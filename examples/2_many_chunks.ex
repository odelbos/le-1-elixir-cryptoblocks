# -----------------------------------------------------------
# Example with many chunks
# -----------------------------------------------------------

# Path to the file
current_path = File.cwd!
lorem_filepath = Path.join [current_path, "test", "data", "lorem.txt"]
{ :ok, file } = File.open lorem_filepath, [:read, :binary]

# -----

size = 256       # Output blocks of 256 bytes
storage_path = Path.join [current_path, "storage", "blocks"]
s = %CryptoBlocks{storage: storage_path, size: size}

# We will read the file in many different chunks
# to simulate many reading with a buffer from a socket or a stream.

part1 = IO.binread file, 480             # Read the first chunk
s1 = CryptoBlocks.write s, part1

part2 = IO.binread file, 1200            # Read the next chunk
s2 = CryptoBlocks.write s1, part2

part3 = IO.binread file, 864             # Next chunk
s3 = CryptoBlocks.write s2, part3

part4 = IO.binread file, 649             # Next chunk
s4 = CryptoBlocks.write s3, part4

{:ok, blocks} = CryptoBlocks.final s4    # Final

# {:ok, blocks} = %CryptoBlocks{storage: storage_path, size: size}
# |> CryptoBlocks.write(part1)
# |> CryptoBlocks.write(part2)
# |> CryptoBlocks.write(part3)
# |> CryptoBlocks.write(part4)
# |> CryptoBlocks.final()

File.close file

IO.inspect blocks

# -----

# Rebuild the file
dest = Path.join [current_path, "storage", "rebuild_lorem.txt"]
CryptoBlocks.rebuild blocks, storage_path, dest

# -----

# Compare md5 of original file and rebuild file
{:ok, lorem_data} = File.read lorem_filepath
{:ok, rebuild_data} = File.read lorem_filepath
IO.puts "Original lorem.txt : #{:erlang.md5(lorem_data) |> Base.encode16(case: :lower)}"
IO.puts "Rebuild lorem.txt  : #{:erlang.md5(rebuild_data) |> Base.encode16(case: :lower)}"
