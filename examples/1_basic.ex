# -----------------------------------------------------------
# Basic example on how to use CryptoBlocks
# -----------------------------------------------------------

# Load the binary file to split in blocks
current_path = File.cwd!
lorem_filepath = Path.join [current_path, "test", "data", "lorem.txt"]
{:ok, data} = File.read lorem_filepath

# -----

# Split in blocks of 512 bytes
size = 512
storage_path = Path.join [current_path, "storage", "blocks"]
# storage_path = Path.join [current_path, "storage", "not-exists"]

# {:ok, blocks} = %CryptoBlocks{storage: storage_path, size: size}
#   |> CryptoBlocks.write(data)
#   |> CryptoBlocks.final()

result = %CryptoBlocks{storage: storage_path, size: size}
  |> CryptoBlocks.write(data)
  |> CryptoBlocks.final()

case result do
  {:error, reason, blocks} ->
    IO.puts "We receive an error : #{IO.inspect reason}"
    IO.puts "blocks:"
    IO.inspect blocks
    System.halt 0
  _ -> result
end

{:ok, blocks} = result

# IO.inspect blocks

# -----

# Generate an error by corrupting a block
# c_block = Enum.at blocks, 3
# IO.inspect c_block
# corrupt_filepath = Path.join [storage_path, CryptoBlocks.id_to_name(c_block.id)]
# File.write corrupt_filepath, :crypto.strong_rand_bytes(512)
# File.close corrupt_filepath

# -----

# error_path = Path.join [current_path, "storage", "not-exists"]

# Rebuild the file
dest = Path.join [current_path, "storage", "rebuild_lorem.txt"]
# dest = Path.join [current_path, "error", "rebuild_lorem.txt"]

case CryptoBlocks.rebuild blocks, storage_path, dest do
  :ok ->
    IO.puts "File rebuilded"
  {:error, reason, msg} ->
    IO.puts "===> We got an error : #{IO.inspect reason}"
    IO.puts "===> Message         : #{IO.inspect msg}"
    System.halt 0
  e ->
    IO.inspect e
    IO.puts "===> We got an unknow error"
    System.halt 0
end

# -----

# Compare md5 of original file and rebuild file
{:ok, rebuild_data} = File.read lorem_filepath
IO.puts "Original lorem.txt : #{:erlang.md5(data) |> Base.encode16(case: :lower)}"
IO.puts "Rebuild lorem.txt  : #{:erlang.md5(rebuild_data) |> Base.encode16(case: :lower)}"
