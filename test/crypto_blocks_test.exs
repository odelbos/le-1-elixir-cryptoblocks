defmodule CryptoBlocksTest do
  use ExUnit.Case
  doctest CryptoBlocks

  @path __DIR__
  @storage_path Path.join [@path, "storage"]
  @blocks_path Path.join [@storage_path, "blocks"]

  setup do
    # Create temporary storage
    unless File.exists?(@storage_path), do: File.mkdir @storage_path
    unless File.exists?(@blocks_path), do: File.mkdir @blocks_path

    on_exit(fn ->
      # Clean up the storage folder
      if File.exists?(@storage_path), do: File.rm_rf @storage_path
    end)
  end

  # -----

  test "binary must be splitted in many blocks" do
    # Load the input binary file
    lorem_filepath = Path.join [@path, "data", "lorem.txt"]
    {:ok, data} = File.read lorem_filepath

    # Split the input binary in blocks of 256 bytes
    size = 256
    {:ok, blocks} = %CryptoBlocks{storage: @blocks_path, size: size}
      |> CryptoBlocks.write(data)
      |> CryptoBlocks.final()

    # Must end up with 13 blocks (12 * 256 + 121)
    # (data binary is 3193 bytes)
    assert length(blocks) == 13

    # Test the last block (it must be 121 bytes size)
    last_block = List.last blocks
    test_block_existence_and_block_size last_block, 121

    # Remove the last block and test all remaining blocks
    new_blocks = Enum.drop blocks, -1
    for block <- new_blocks do
      test_block_existence_and_block_size block, size
    end

    # Rebuild the binary from blocks and assert it's the same as the original binary
    dest = Path.join [@storage_path, "rebuild_lorem.txt"]
    CryptoBlocks.rebuild blocks, @blocks_path, dest
    {:ok, rebuild_data} = File.read dest
    assert :erlang.md5(data) == :erlang.md5(rebuild_data)
  end

  test "many input binary must be splitted in many blocks" do
    # Load the input binary file in many chunks of different size
    # (ex: simulating a file received from a socket or stream in many
    # different chunks size)
    lorem_filepath = Path.join [@path, "data", "lorem.txt"]
    {:ok, file} = File.open lorem_filepath, [:read, :binary]
    part1 = IO.binread file, 480
    part2 = IO.binread file, 1200
    part3 = IO.binread file, 864
    part4 = IO.binread file, 649
    File.close file

    # Split the input binary in blocks of 512 bytes
    size = 512
    {:ok, blocks} = %CryptoBlocks{storage: @blocks_path, size: size}
      |> CryptoBlocks.write(part1)
      |> CryptoBlocks.write(part2)
      |> CryptoBlocks.write(part3)
      |> CryptoBlocks.write(part4)
      |> CryptoBlocks.final()

    # Must end up with 7 blocks (6 * 512 + 121)
    # (input binary file is 3193 bytes)
    assert length(blocks) == 7

    # Test the last block (it must be 121 bytes size)
    last_block = List.last blocks
    test_block_existence_and_block_size last_block, 121

    # Remove the last block and test all remaining blocks
    new_blocks = Enum.drop blocks, -1
    for block <- new_blocks do
      test_block_existence_and_block_size block, size
    end

    # Rebuild the binary from blocks and assert it's the same as the original binary
    dest = Path.join [@storage_path, "rebuild_lorem.txt"]
    CryptoBlocks.rebuild blocks, @blocks_path, dest
    {:ok, rebuild_data} = File.read dest
    {:ok, lorem_data} = File.read lorem_filepath
    assert :erlang.md5(lorem_data) == :erlang.md5(rebuild_data)
  end

  test "when input binary size is a multiple of the block size" do
    # Load the input binary file
    lorem_512_filepath = Path.join [@path, "data", "lorem_512.txt"]
    {:ok, data} = File.read lorem_512_filepath

    # Split the input binary in blocks of 128 bytes
    size = 128
    {:ok, blocks} = %CryptoBlocks{storage: @blocks_path, size: size}
      |> CryptoBlocks.write(data)
      |> CryptoBlocks.final()

    # Must end up with 4 blocks (4 * 128)
    # (data binary is 512 bytes)
    assert length(blocks) == 4

    # Test blocks
    for block <- blocks do
      test_block_existence_and_block_size block, size
    end

    # Rebuild the binary from blocks and assert it's the same as the original binary
    dest = Path.join [@storage_path, "rebuild_lorem.txt"]
    CryptoBlocks.rebuild blocks, @blocks_path, dest
    {:ok, rebuild_data} = File.read dest
    assert :erlang.md5(data) == :erlang.md5(rebuild_data)
  end

  test "when input binary size is smaller than the block size" do
    # Load the input binary file
    lorem_512_filepath = Path.join [@path, "data", "lorem_512.txt"]
    {:ok, data} = File.read lorem_512_filepath

    # Split the input binary in blocks of 1024 bytes
    size = 1024
    {:ok, blocks} = %CryptoBlocks{storage: @blocks_path, size: size}
    |> CryptoBlocks.write(data)
    |> CryptoBlocks.final()

    # Must end up with 1 blocks of 512 bytes
    assert length(blocks) == 1

    # Test the block
    [block | _r] = blocks
    test_block_existence_and_block_size block, 512

    # Rebuild the binary from blocks and assert it's the same as the original binary
    dest = Path.join [@storage_path, "rebuild_lorem.txt"]
    CryptoBlocks.rebuild blocks, @blocks_path, dest
    {:ok, rebuild_data} = File.read dest
    assert :erlang.md5(data) == :erlang.md5(rebuild_data)
  end

  test "blocks must be encrypted" do
    # Load the input binary file
    lorem_512_filepath = Path.join [@path, "data", "lorem_512.txt"]
    {:ok, data} = File.read lorem_512_filepath

    # Split the input binary in blocks of 128 bytes
    size = 128
    {:ok, blocks} = %CryptoBlocks{storage: @blocks_path, size: size}
    |> CryptoBlocks.write(data)
    |> CryptoBlocks.final()

    # Compare each block data with the corresponding source data
    lorem_filepath = Path.join [@path, "data", "lorem.txt"]
    {:ok, file} = File.open lorem_filepath, [:read, :binary]
    for block <- blocks do
      test_encrypted block, file, 128
    end
    File.close file
  end

  # -----------------------------------------------------
  # Helper functions
  # -----------------------------------------------------
  defp test_encrypted(block, file, bytes) do
    # Read the input binary chunk
    src_data = IO.binread file, bytes
    # Read the corresponding encrypted block
    block_filepath = Path.join [@blocks_path, CryptoBlocks.id_to_name(block.id)]
    {:ok, file} = File.open block_filepath, [:read, :binary]
    block_data = IO.binread file, :all
    File.close file
    assert :erlang.md5(src_data) != :erlang.md5(block_data)
  end

  defp test_block_existence_and_block_size(block, size) do
    filepath = Path.join [@blocks_path, CryptoBlocks.id_to_name(block.id)]
    assert File.exists?(filepath)
    assert size == with {:ok, %File.Stat{size: bs}} <- File.stat(filepath), do: bs
  end
end
