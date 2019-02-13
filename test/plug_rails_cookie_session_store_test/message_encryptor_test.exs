defmodule PlugRailsCookieSessionStore.MessageEncryptorTest do
  use ExUnit.Case, async: true

  alias PlugRailsCookieSessionStore.MessageEncryptor, as: ME

  @right String.duplicate("abcdefgh", 4)
  @wrong String.duplicate("12345678", 4)
  @large String.duplicate(@right, 2)

  test "it encrypts/decrypts a message" do
    data = <<0, "hełłoworld", 0>>
    encrypted = ME.encrypt_and_sign(<<0, "hełłoworld", 0>>, @right, @right)

    decrypted = ME.verify_and_decrypt(encrypted, @right, @wrong)
    assert decrypted == :error

    decrypted = ME.verify_and_decrypt(encrypted, @wrong, @right)
    assert decrypted == :error

    decrypted = ME.verify_and_decrypt(encrypted, @right, @right)
    assert decrypted == {:ok, data}
  end

  test "it uses only the first 32 bytes to encrypt/decrypt" do
    data = <<0, "helloworld", 0>>
    encrypted = ME.encrypt_and_sign(<<0, "helloworld", 0>>, @large, @large)

    decrypted = ME.verify_and_decrypt(encrypted, @large, @large)
    assert decrypted == {:ok, data}

    decrypted = ME.verify_and_decrypt(encrypted, @right, @large)
    assert decrypted == {:ok, data}

    decrypted = ME.verify_and_decrypt(encrypted, @large, @right)
    assert decrypted == :error

    decrypted = ME.verify_and_decrypt(encrypted, @right, @right)
    assert decrypted == :error

    encrypted = ME.encrypt_and_sign(<<0, "helloworld", 0>>, @right, @large)

    decrypted = ME.verify_and_decrypt(encrypted, @large, @large)
    assert decrypted == {:ok, data}

    decrypted = ME.verify_and_decrypt(encrypted, @right, @large)
    assert decrypted == {:ok, data}

    decrypted = ME.verify_and_decrypt(encrypted, @large, @right)
    assert decrypted == :error

    decrypted = ME.verify_and_decrypt(encrypted, @right, @right)
    assert decrypted == :error
  end

  test "it authenticates and encrypts/decrypts a message" do
    #decrypted = ME.verify_and_decrypt("gfYQ/Lf3k3g2UbqVYUGkJZ2VVW5Elnw+Q6hYM/vA09MOvs4bswNiJ/SGRiyamaQJ5u8p0hPKkgMPZ3o=--M6q9L9Aj90r1oDdL--HJ0Ce+OpOsCU/Q7Mb/k2jA==", "authenticated encrypted cookie", "", :aes_gcm)
    #assert decrypted == :error

    data = <<0, "hełłoworld", 0>>
    encrypted = ME.encrypt_and_authenticate(<<0, "hełłoworld", 0>>, @right)

    decrypted = ME.authenticate_and_decrypt(encrypted, @wrong)
    assert decrypted == :error

    decrypted = ME.authenticate_and_decrypt(encrypted, @right)
    assert decrypted == {:ok, data}
  end

  test "it uses only the first 32 bytes to authenticate and encrypt/decrypt" do
    data = <<0, "helloworld", 0>>
    encrypted = ME.encrypt_and_authenticate(<<0, "helloworld", 0>>, @large)

    decrypted = ME.authenticate_and_decrypt(encrypted, @large)
    assert decrypted == {:ok, data}

    decrypted = ME.authenticate_and_decrypt(encrypted, @right)
    assert decrypted == {:ok, data}

    decrypted = ME.verify_and_decrypt(encrypted, @right, @right)
    assert decrypted == :error

    encrypted = ME.encrypt_and_authenticate(<<0, "helloworld", 0>>, @right)

    decrypted = ME.authenticate_and_decrypt(encrypted, @large)
    assert decrypted == {:ok, data}

    decrypted = ME.authenticate_and_decrypt(encrypted, @right)
    assert decrypted == {:ok, data}
  end
end
