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
  rescue
    e ->
      reraise e, filter_stacktrace(__STACKTRACE__)
  end

  def encrypt(data) do
    key = :crypto.strong_rand_bytes 32
    {iv, tag, encrypted} = encrypt data, key
    {key, iv, tag, encrypted}
  end

  def decrypt(data, key, iv, tag) do
    aad = "A256GCM"
    :crypto.crypto_one_time_aead :aes_256_gcm, key, iv, data, aad, tag, false
  rescue
    e ->
      reraise e, filter_stacktrace(__STACKTRACE__)
  end

  # -----

  defp filter_stacktrace(stacktrace) do
    Enum.reverse do_filter_stacktrace(stacktrace, [])
  end

  defp do_filter_stacktrace([], acc), do: acc

  defp do_filter_stacktrace([item | rest], acc) do
    new_item = case item do
                 {mod, fun, _, info} -> {mod, fun, "(filtered args)", info}
                 _ -> item
               end
    do_filter_stacktrace rest, [new_item | acc]
  end
end

#
# ---------------------------------------------------------------------------
# Dev note
# ---------------------------------------------------------------------------
#
# We need to rescue and reraise the excpetion with a filtered stacktrace
# because the default exception raised by crypto_one_time_aead() function is
# leaking the secret key.
#
# The default Erlang exception stacktrace looks like :
#
# ** (ErlangError) Erlang error: {:badarg, {'aead.c', 69}, 'non-binary AAD'}
#     (crypto 5.0.5) crypto.erl:945: :crypto.crypto_one_time_aead(:aes_256_gcm, <<49, ..secret-key... >>, <<203, ... >>, "...msg...", nil, 16, true)
#     (crypto_blocks 0.1.0) lib/crypto_blocks/crypto.ex:11: CryptoBlocks.Crypto.encrypt/2
#     ....
#     ....
#
# This mean that if we use a specific exception logging system or external
# service to log and monitor your application errors, the secret key used
# to encrypt/decrypt is leaked.
#
