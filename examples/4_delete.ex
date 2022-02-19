# -----------------------------------------------------------
# Delete blocks example
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

{output, _status} = System.cmd "tree", ["storage"]
IO.puts output

# -----

# Deelte all blocks
CryptoBlocks.delete blocks, storage_path

# -----

{output, _status} = System.cmd "tree", ["storage"]
IO.puts output
