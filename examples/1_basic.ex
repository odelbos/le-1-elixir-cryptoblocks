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

result = %CryptoBlocks{storage: storage_path, size: size}
  |> CryptoBlocks.write(data)
  |> CryptoBlocks.final()

case result do
  {:error, reason, msg, blocks} ->
    IO.puts "We receive an error: #{msg}, #{reason}"
    IO.inspect blocks
    System.halt 0
  _ -> result
end

{:ok, blocks} = result

IO.inspect blocks

# -----

# Rebuild the file
dest = Path.join [current_path, "storage", "rebuild_lorem.txt"]

case CryptoBlocks.rebuild blocks, storage_path, dest do
  :ok ->
    IO.puts "-- File rebuilded --"
  {:error, reason, msg} ->
    IO.puts "Error : #{reason}, #{msg}"
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
