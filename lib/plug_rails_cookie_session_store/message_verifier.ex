defmodule PlugRailsCookieSessionStore.MessageVerifier do
  @moduledoc """
  `MessageVerifier` makes it easy to generate and verify messages
  which are signed to prevent tampering.

  For example, the cookie store uses this verifier to send data
  to the client. Although the data can be read by the client, he
  cannot tamper it.
  """

  @doc """
  Decodes and verifies the encoded binary was not tampered with.
  """
  def verify(binary, secret) when is_binary(binary) and is_binary(secret) do
    case String.split(binary, "--") do
      [content, digest] when content != "" and digest != "" ->
        if Plug.Crypto.secure_compare(digest(secret, content), digest) do
          {:ok, Base.decode64!(content)}
        else
          :error
        end
      _ ->
        :error
    end
  end

  @doc """
  Signs a binary according to the given secret.
  """
  def sign(binary, secret) when is_binary(binary) and is_binary(secret) do
    encoded = Base.encode64(binary)
    encoded <> "--" <> digest(secret, encoded)
  end

  defp digest(secret, data) do
    :crypto.mac(:hmac, :sha, secret, data) |> Base.encode16(case: :lower)
  end
end
