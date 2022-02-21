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
    # %File.Error{reason: reason} -> IO.inspect reason
    e -> case e do
           %File.Error{reason: reason} ->
             {:error, reason, "File system error", struct}
           %ErlangError{original: {reason, _, info}} ->
             IO.inspect __STACKTRACE__
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
    s = struct.size * 8
    <<chunk::size(s), rest::binary>> = bin
    make_blocks struct, <<chunk::size(s)>>, rest
  end

  def make_blocks(%CryptoBlocks{} = struct, data, bin) do
    make_blocks write_block(struct, data), bin
  end

  # -----

  def write_block(%CryptoBlocks{} = struct, data) do
    {key, iv, tag, encrypted} = Crypto.encrypt data         # TODO : error handling
    id = generate_id struct.storage
    dest = Path.join [struct.storage, id_to_name(id)]
    File.write! dest, encrypted, [:binary, :raw]            # TODO : error handling
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
           {:error, reason} ->
             {:error, reason,"File system error 1"}
           %File.Error{reason: reason} ->
             {:error, reason, "File system error 2"}
           %ErlangError{original: {reason, _, _}} ->
             {:error, reason, "Cannot decrypt a block"}
           _ ->
             IO.inspect e
             {:error, :unknow, "Unknow error"}
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

  def delete([], _storage) do
    :ok
  end

  def delete([block | tail], storage) do
    filepath = Path.join [storage, id_to_name(block.id)]
    if File.exists?(filepath), do: File.rm filepath             # TODO : error handling
    delete tail, storage
  end
end
