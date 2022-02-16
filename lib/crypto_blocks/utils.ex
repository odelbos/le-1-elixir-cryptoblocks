defmodule CryptoBlocks.Utils do
  @moduledoc """
  Utils functions to pack/unpack the blocks description produced by
  the `CryptoBlocks` module in one single binary.
  """

  def pack(blocks) do
    do_pack blocks, ""
  end

  defp do_pack([], acc), do: acc

  defp do_pack([block | rest], acc) do
    p = block.id <> block.key <> block.iv <> block.tag
    do_pack rest, acc <> p
  end

  # -----

  def unpack(bin), do: Enum.reverse do_unpack(bin, [])

  defp do_unpack(bin, acc) when byte_size(bin) == 0, do: acc

  defp do_unpack(bin, acc) do
    <<id::128, key::256, iv::128, tag::128, rest::binary>> = bin
    block = %{
      id: <<id::128>>,
      key: <<key::256>>,
      iv: <<iv::128>>,
      tag: <<tag::128>>
    }
    do_unpack rest, [block | acc]
  end
end
