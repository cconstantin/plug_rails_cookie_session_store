defmodule PlugRailsCookieSessionStoreTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias PlugRailsCookieSessionStore, as: CookieStore

  @default_opts [
    store: CookieStore,
    key: "foobar",
    encryption_salt: "encrypted cookie salt",
    signing_salt: "signing salt"
  ]

  @secret String.duplicate("abcdef0123456789", 8)
  @signing_opts Plug.Session.init(Keyword.put(@default_opts, :encrypt, false))
  @signing_without_salt_opts Plug.Session.init(
                               Keyword.put(@default_opts, :signing_with_salt, false)
                             )
  @encrypted_opts Plug.Session.init(@default_opts)

  @authenticated_encrypted_opts Plug.Session.init(@default_opts
                                                  |> Keyword.put(:use_authenticated_encryption, true)
                                                  |> Keyword.put(:authenticated_encryption_salt, "authenticated encrypted cookie"))

  defmodule CustomSerializer do
    def encode(%{"foo" => "bar"}), do: {:ok, "encoded session"}
    def encode(%{foo: :bar}), do: {:ok, "another encoded session"}
    def encode(%{}), do: {:ok, ""}
    def encode(_), do: :error

    def decode("encoded session"), do: {:ok, %{"foo" => "bar"}}
    def decode("another encoded session"), do: {:ok, %{foo: :bar}}
    def decode(nil), do: {:ok, nil}
    def decode(_), do: :error
  end

  @custom_serializer_opts Plug.Session.init(
                            Keyword.put(@default_opts, :serializer, CustomSerializer)
                          )

  defp sign_conn(conn, secret \\ @secret) do
    put_in(conn.secret_key_base, secret)
    |> Plug.Session.call(@signing_opts)
    |> fetch_session
  end

  defp encrypt_conn(conn) do
    put_in(conn.secret_key_base, @secret)
    |> Plug.Session.call(@encrypted_opts)
    |> fetch_session
  end

  defp authenticated_encrypt_conn(conn) do
    put_in(conn.secret_key_base, "edffda9d151781024e5a40d0d68d44f6")
    |> Plug.Session.call(@authenticated_encrypted_opts)
    |> fetch_session
  end

  defp custom_serialize_conn(conn) do
    put_in(conn.secret_key_base, @secret)
    |> Plug.Session.call(@custom_serializer_opts)
    |> fetch_session
  end

  test "requires signing_salt option to be defined" do
    assert_raise ArgumentError, ~r/expects :signing_salt as option/, fn ->
      Plug.Session.init(Keyword.delete(@default_opts, :signing_salt))
    end
  end

  test "requires encrypted_salt option to be defined" do
    assert_raise ArgumentError, ~r/expects :encryption_salt as option/, fn ->
      Plug.Session.init(Keyword.delete(@default_opts, :encryption_salt))
    end
  end

  test "requires the secret to be at least 32 bytes" do
    assert_raise ArgumentError, ~r/to be at least 32 bytes/, fn ->
      conn(:get, "/")
      |> sign_conn("abcdef")
      |> put_session(:foo, "bar")
      |> send_resp(200, "OK")
    end
  end

  test "defaults key generator opts" do
    key_generator_opts = CookieStore.init(@default_opts).key_opts
    assert key_generator_opts[:iterations] == 1000
    assert key_generator_opts[:length] == 32
    assert key_generator_opts[:digest] == :sha256
  end

  test "uses specified key generator opts" do
    opts =
      @default_opts
      |> Keyword.put(:key_iterations, 2000)
      |> Keyword.put(:key_length, 64)
      |> Keyword.put(:key_digest, :sha)

    key_generator_opts = CookieStore.init(opts).key_opts
    assert key_generator_opts[:iterations] == 2000
    assert key_generator_opts[:length] == 64
    assert key_generator_opts[:digest] == :sha
  end

  test "requires serializer option to be an atom" do
    assert_raise ArgumentError, ~r/expects :serializer option to be a module/, fn ->
      Plug.Session.init(Keyword.put(@default_opts, :serializer, "CustomSerializer"))
    end
  end

  test "uses :external_term_format cookie serializer by default" do
    assert Plug.Session.init(@default_opts).store_config.serializer == :external_term_format
  end

  test "uses custom cookie serializer" do
    assert @custom_serializer_opts.store_config.serializer == CustomSerializer
  end

  ## Signed

  test "session cookies are signed" do
    conn = %{secret_key_base: @secret}
    cookie = CookieStore.put(conn, nil, %{foo: :bar}, @signing_opts.store_config)
    assert is_binary(cookie)
    assert CookieStore.get(conn, cookie, @signing_opts.store_config) == {nil, %{foo: :bar}}
  end

  test "session cookies are signed without salt" do
    conn = %{secret_key_base: @secret}
    cookie = CookieStore.put(conn, nil, %{foo: :bar}, @signing_without_salt_opts.store_config)
    assert is_binary(cookie)

    assert CookieStore.get(conn, cookie, @signing_without_salt_opts.store_config) ==
             {nil, %{foo: :bar}}
  end

  test "gets and sets signed session cookie" do
    conn =
      conn(:get, "/")
      |> sign_conn()
      |> put_session(:foo, "bar")
      |> send_resp(200, "")

    assert conn(:get, "/")
           |> recycle_cookies(conn)
           |> sign_conn()
           |> get_session(:foo) == "bar"
  end

  test "deletes signed session cookie" do
    conn =
      conn(:get, "/")
      |> sign_conn()
      |> put_session(:foo, :bar)
      |> configure_session(drop: true)
      |> send_resp(200, "")

    assert conn(:get, "/")
           |> recycle_cookies(conn)
           |> sign_conn()
           |> get_session(:foo) == nil
  end

  ## Encrypted

  test "session cookies are encrypted" do
    conn = %{secret_key_base: @secret}
    cookie = CookieStore.put(conn, nil, %{foo: :bar}, @encrypted_opts.store_config)
    assert is_binary(cookie)
    assert CookieStore.get(conn, cookie, @encrypted_opts.store_config) == {nil, %{foo: :bar}}
  end

  test "gets and sets encrypted session cookie" do
    conn =
      conn(:get, "/")
      |> encrypt_conn()
      |> put_session(:foo, "bar")
      |> send_resp(200, "")

    assert conn(:get, "/")
           |> recycle_cookies(conn)
           |> encrypt_conn()
           |> get_session(:foo) == "bar"
  end

  test "deletes encrypted session cookie" do
    conn =
      conn(:get, "/")
      |> encrypt_conn()
      |> put_session(:foo, :bar)
      |> configure_session(drop: true)
      |> send_resp(200, "")

    assert conn(:get, "/")
           |> recycle_cookies(conn)
           |> encrypt_conn()
           |> get_session(:foo) == nil
  end

  ## Custom Serializer

  test "session cookies are serialized by the custom serializer" do
    conn = %{secret_key_base: @secret}
    cookie = CookieStore.put(conn, nil, %{foo: :bar}, @custom_serializer_opts.store_config)
    assert is_binary(cookie)

    assert CookieStore.get(conn, cookie, @custom_serializer_opts.store_config) ==
             {nil, %{foo: :bar}}
  end

  test "gets and sets custom serialized session cookie" do
    conn =
      conn(:get, "/")
      |> custom_serialize_conn()
      |> put_session(:foo, "bar")
      |> send_resp(200, "")

    res =
      conn(:get, "/")
      |> recycle_cookies(conn)
      |> custom_serialize_conn()
      |> get_session(:foo)

    assert res == "bar"
  end

  test "deletes custom serialized session cookie" do
    conn =
      conn(:get, "/")
      |> custom_serialize_conn()
      |> put_session(:foo, :bar)
      |> configure_session(drop: true)
      |> send_resp(200, "")

    assert conn(:get, "/")
           |> recycle_cookies(conn)
           |> custom_serialize_conn()
           |> get_session(:foo) == nil
  end

  @tag :wip
  test "deserializes Rails >5.2 session cookie" do
    assert conn(:get, "/")
           |> put_req_cookie("foobar", "XMxMwUhyiqs5gHWnmFQaWqRGg0vdvy4KHcKbhTUuGl2%2FAuFgLckh0grWkOh7s0zAd0bPeRlXSxZkGv0%3D--djXWCUYYPM5HFzUu--gYdZB9mHt5C0fkTjvnAZpg%3D%3D")
           |> authenticated_encrypt_conn()
           |> get_session(:foo) == 123

  end
end
