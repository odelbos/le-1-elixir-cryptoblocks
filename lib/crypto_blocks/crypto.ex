defmodule CryptoBlocks.Crypto do
  @moduledoc """
  AES 256 GCM ecnrypt and decrypt functions.
  """

  def encrypt(data, key) do
    iv = :crypto.strong_rand_bytes 16
    aad = "A256GCM"
    {encrypted, tag} =
      :crypto.crypto_one_time_aead :aes_256_gcm, key, iv, data, aad, true
    {iv, tag, encrypted}
  end

  def encrypt(data) do
    key = :crypto.strong_rand_bytes 32
    {iv, tag, encrypted} = encrypt data, key
    {key, iv, tag, encrypted}
  end

  def decrypt(data, key, iv, tag) do
    aad = "A256GCM"
    :crypto.crypto_one_time_aead :aes_256_gcm, key, iv, data, aad, tag, false
  end
end
