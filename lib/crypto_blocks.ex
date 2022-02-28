defmodule CryptoBlocks do
  @moduledoc """
  Documentation for `CryptoBlocks`.
  """

  alias CryptoBlocks.Crypto

  @enforce_keys [:storage]

  defstruct storage: nil,    # Where to store blocks (absolute path)
            size: 262144,    # Block size in bytes. (256KB -> 1024*256 = 262144)
            blocks: [],      # Where the result will be stored
            acc: nil         # Internal accumulator

  def write(%CryptoBlocks{} = struct, data) when byte_size(data) == 0 do
    {:ok, Enum.reverse struct.blocks}
  end

  def write(%CryptoBlocks{} = struct, data) when struct.acc != nil do
    write %{struct | acc: nil}, struct.acc <> data
  end

  def write(%CryptoBlocks{} = struct, data) when struct.acc == nil do
    make_blocks struct, data
  rescue
    e -> case e do
           %File.Error{reason: reason} ->
             {:error, reason, "File system error", struct}
           %ErlangError{original: {reason, _, info}} ->
             {:error, reason, "Encryption error: #{info}", struct}
           _ ->
             {:error, :unknown, "Unknown error", struct}
         end
  end

  # -----

  def final({:error, reason, msg, struct}) when struct.acc == nil do
    {:error, reason, msg, Enum.reverse struct.blocks}
  end

  def final(%CryptoBlocks{} = struct) when struct.acc == nil do
    {:ok, Enum.reverse struct.blocks}
  end

  def final(%CryptoBlocks{} = struct) when byte_size(struct.acc) > struct.size do
    new_struct = make_blocks %{struct | acc: nil}, struct.acc
    final new_struct
  end

  def final(%CryptoBlocks{} = struct) do
    {:ok, Enum.reverse %{write_block(struct, struct.acc) | acc: nil}.blocks}
  end

  # -----

  def make_blocks(%CryptoBlocks{} = struct, bin) when byte_size(bin) == 0 do
    struct
  end

  def make_blocks(%CryptoBlocks{} = struct, bin) when byte_size(bin) < struct.size do
    %{struct | acc: bin}
  end

  def make_blocks(%CryptoBlocks{} = struct, bin) do
    s = struct.size
    <<chunk::binary-size(s), rest::binary>> = bin
    make_blocks struct, <<chunk::binary-size(s)>>, rest
  end

  def make_blocks(%CryptoBlocks{} = struct, data, bin) do
    make_blocks write_block(struct, data), bin
  end

  # -----

  def write_block(%CryptoBlocks{} = struct, data) do
    {key, iv, tag, encrypted} = Crypto.encrypt data
    id = generate_id struct.storage
    dest = Path.join [struct.storage, id_to_name(id)]
    File.write! dest, encrypted, [:binary, :raw]
    %{struct | blocks: [%{id: id, key: key, iv: iv, tag: tag} | struct.blocks]}
  end

  # -----

  def id_to_name(id), do: Base.encode16 id, case: :lower

  defp generate_id(path) do
    id = :crypto.strong_rand_bytes(100) |> :erlang.md5
    filepath = Path.join [path, id_to_name(id)]
    if File.exists? filepath do
      generate_id path
    else
      id
    end
  end

  # -----

  def rebuild(blocks, storage, filepath) do
    file = File.open! filepath, [:write, :binary, :raw]
    do_rebuild blocks, storage, file
  rescue
    e -> case e do
           {:error, reason, msg} -> {:error, reason, msg}
           %File.Error{reason: reason} ->
             {:error, reason, "File system error"}
           %ErlangError{original: {reason, _, _}} ->
             {:error, reason, "Cannot decrypt a block"}
           _ ->
             {:error, :unknown, "Unknown error"}
         end
  end

  defp do_rebuild([], _storage, file) do
    File.close file
    :ok
  end

  defp do_rebuild([block | tail], storage, file) do
    case read_block block, storage do
      :error ->
        {:error, :decrypt, "Block corrupted"}
      data ->
        IO.binwrite file, data
        do_rebuild tail, storage, file
    end
  end

  # -----

  def read_block(block, storage) do
    filename = id_to_name block.id
    filepath = Path.join [storage, filename]
    encrypted = File.read! filepath
    Crypto.decrypt encrypted, block.key, block.iv, block.tag
  end

  # -----

  def delete([], _storage), do: :ok

  def delete([block | tail], storage) do
    filepath = Path.join [storage, id_to_name(block.id)]
    if File.exists?(filepath), do: File.rm filepath
    delete tail, storage
  end

  # -----

  def bytes(blocks, storage) do
    Enum.reduce(blocks, 0, fn block, acc ->
      case File.stat(Path.join [storage, id_to_name(block.id)]) do
        {:ok, %File.Stat{size: bs}} -> acc + bs
        _ -> acc
      end
    end)
  end

  # -----

  def hash(blocks, storage, algo \\ :sha256)
            when algo in [:sha256, :sha512, :blake2b, :blake2s] do
    state = :crypto.hash_init algo
    blocks
      |> Enum.reduce(state, &:crypto.hash_update(&2, read_block(&1, storage)))
      |> :crypto.hash_final()
      |> Base.encode16(case: :lower)
  end
end
