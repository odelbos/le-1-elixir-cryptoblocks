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

{:ok, blocks} = %CryptoBlocks{storage: storage_path, size: size}
  |> CryptoBlocks.write(data)
  |> CryptoBlocks.final()

IO.inspect blocks

# -----

# Rebuild the file
dest = Path.join [current_path, "storage", "rebuild_lorem.txt"]
CryptoBlocks.rebuild blocks, storage_path, dest

# -----

# Compare md5 of original file and rebuild file
{:ok, rebuild_data} = File.read lorem_filepath
IO.puts "Original lorem.txt : #{:erlang.md5(data) |> Base.encode16(case: :lower)}"
IO.puts "Rebuild lorem.txt  : #{:erlang.md5(rebuild_data) |> Base.encode16(case: :lower)}"
