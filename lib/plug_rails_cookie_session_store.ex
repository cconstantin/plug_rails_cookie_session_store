defmodule PlugRailsCookieSessionStore do
  @moduledoc """
  Stores the session in a cookie.

  This cookie store is based on `Plug.Crypto.MessageVerifier`
  and `Plug.Crypto.Message.Encryptor` which encrypts and signs
  each cookie to ensure they can't be read nor tampered with.

  Since this store uses crypto features, it requires you to
  set the `:secret_key_base` field in your connection. This
  can be easily achieved with a plug:

      plug :put_secret_key_base

      def put_secret_key_base(conn, _) do
        put_in conn.secret_key_base, "-- LONG STRING WITH AT LEAST 64 BYTES --"
      end

  ## Options

  * `:encrypt` - specify whether to encrypt cookies, defaults to true.
    When this option is false, the cookie is still signed, meaning it
    can't be tempered with but its contents can be read;

  * `:encryption_salt` - a salt used with `conn.secret_key_base` to generate
    a key for encrypting/decrypting a cookie;

  * `:signing_salt` - a salt used with `conn.secret_key_base` to generate a
    key for signing/verifying a cookie;

  * `:key_iterations` - option passed to `Plug.Crypto.KeyGenerator`
    when generating the encryption and signing keys. Defaults to 1000;

  * `:key_length` - option passed to `Plug.Crypto.KeyGenerator`
    when generating the encryption and signing keys. Defaults to 32;

  * `:key_digest` - option passed to `Plug.Crypto.KeyGenerator`
    when generating the encryption and signing keys. Defaults to `:sha256`;

  * `:serializer` - cookie serializer module that defines `encode/1` and
    `decode/1` returning an `{:ok, value}` tuple. Defaults to
    `:external_term_format`.

  ## Examples

      # Use the session plug with the table name
      plug Plug.Session, store: PlugRailsCookieSessionStore,
                         key: "_my_app_session",
                         encryption_salt: "cookie store encryption salt",
                         signing_salt: "cookie store signing salt",
                         key_length: 64,
                         serializer: Poison

  """

  @behaviour Plug.Session.Store

  alias Plug.Crypto.KeyGenerator
  alias PlugRailsCookieSessionStore.MessageVerifier
  alias PlugRailsCookieSessionStore.MessageEncryptor

  def init(opts) do
    encryption_salt = check_encryption_salt(opts)
    signing_salt = check_signing_salt(opts)

    iterations = Keyword.get(opts, :key_iterations, 1000)
    length = Keyword.get(opts, :key_length, 32)
    digest = Keyword.get(opts, :key_digest, :sha256)
    key_opts = [iterations: iterations, length: length, digest: digest, cache: Plug.Keys]

    serializer = check_serializer(opts[:serializer] || :external_term_format)

    %{
      encryption_salt: encryption_salt,
      signing_salt: signing_salt,
      key_opts: key_opts,
      serializer: serializer
    }
  end

  def get(conn, cookie, opts) do
    key_opts = opts.key_opts
    cookie = cookie |> URI.decode_www_form()

    if key = opts.encryption_salt do
      MessageEncryptor.verify_and_decrypt(
        cookie,
        derive(conn, key, key_opts),
        derive(conn, opts.signing_salt, key_opts)
      )
    else
      MessageVerifier.verify(cookie, derive(conn, opts.signing_salt, key_opts))
    end
    |> decode(opts.serializer)
  end

  def put(conn, _sid, term, opts) do
    binary = encode(term, opts.serializer)
    key_opts = opts.key_opts

    if key = opts.encryption_salt do
      MessageEncryptor.encrypt_and_sign(
        binary,
        derive(conn, key, key_opts),
        derive(conn, opts.signing_salt, key_opts)
      )
    else
      MessageVerifier.sign(binary, derive(conn, opts.signing_salt, key_opts))
    end
    |> URI.encode_www_form()
  end

  def delete(_conn, _sid, _opts) do
    :ok
  end

  defp encode(term, :external_term_format), do: :erlang.term_to_binary(term)

  defp encode(term, serializer) do
    case serializer.encode(term) do
      {:ok, binary} -> binary
      _ -> nil
    end
  end

  defp decode({:ok, binary}, :external_term_format), do: {nil, :erlang.binary_to_term(binary)}

  defp decode({:ok, binary}, serializer) do
    case serializer.decode(binary) do
      {:ok, term} -> {nil, term}
      _ -> {nil, %{}}
    end
  end

  defp decode(:error, _serializer), do: {nil, %{}}

  defp derive(conn, key, key_opts) do
    conn.secret_key_base
    |> validate_secret_key_base()
    |> generate_key(key, key_opts)
  end

  defp generate_key(secret, nil, _), do: secret
  defp generate_key(secret, key, key_opts), do: KeyGenerator.generate(secret, key, key_opts)

  defp validate_secret_key_base(nil),
    do: raise(ArgumentError, "cookie store expects conn.secret_key_base to be set")

  defp validate_secret_key_base(secret_key_base) when byte_size(secret_key_base) < 32,
    do: raise(ArgumentError, "cookie store expects conn.secret_key_base to be at least 32 bytes")

  defp validate_secret_key_base(secret_key_base), do: secret_key_base

  defp check_signing_salt(opts) do
    if Keyword.get(opts, :signing_with_salt, true) do
      case opts[:signing_salt] do
        nil -> raise ArgumentError, "cookie store expects :signing_salt as option"
        salt -> salt
      end
    end
  end

  defp check_encryption_salt(opts) do
    if Keyword.get(opts, :encrypt, true) do
      case opts[:encryption_salt] do
        nil -> raise ArgumentError, "encrypted cookie store expects :encryption_salt as option"
        salt -> salt
      end
    end
  end

  defp check_serializer(serializer) when is_atom(serializer), do: serializer

  defp check_serializer(_),
    do: raise(ArgumentError, "cookie store expects :serializer option to be a module")
end
