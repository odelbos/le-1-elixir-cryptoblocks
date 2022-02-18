# -------------------------------------------------------
# Generate the blocks and save the blocks description
# -------------------------------------------------------
# ---1---
# Load the binary file to split in blocks
current_path = File.cwd!
lorem_filepath = Path.join [current_path, "test", "data", "lorem.txt"]
{:ok, data} = File.read lorem_filepath

# ---2---
# Split the binary file in blocks of 256 bytes
size = 256
storage_path = Path.join [current_path, "storage", "blocks"]

{:ok, blocks} = %CryptoBlocks{storage: storage_path, size: size}
  |> CryptoBlocks.write(data)
  |> CryptoBlocks.final()

IO.inspect blocks

# ---3---
# Pack the blocks description.
packed_blocks = CryptoBlocks.Utils.pack blocks

IO.inspect packed_blocks

# Usually we would like to encrypt the packed blocks with a master key
# before to save it to disk.
master_key = :crypto.strong_rand_bytes 32
{iv, tag, encrypted_blocks} =
  CryptoBlocks.Crypto.encrypt packed_blocks, master_key

# ---4---
# Save the encrypted blocks description to disk
filename = :crypto.strong_rand_bytes(100)
  |> :erlang.md5
  |> Base.encode16(case: :lower)
filepath = Path.join [current_path, "storage", "files", filename]
File.write filepath, iv <> tag <> encrypted_blocks, [:binary, :raw]


# -------------------------------------------------------
# And Later
# -------------------------------------------------------
# ---1---
# Read the encrypted blocks description from disk
{:ok, bin} = File.read filepath
<<iv::128, tag::128, e_blocks::binary>> = bin
c_iv = <<iv::128>>
c_tag = <<tag::128>>

# ---2---
# Decrypt and unpack
clear_blocks = e_blocks
  |> CryptoBlocks.Crypto.decrypt(master_key, c_iv, c_tag)
  |> CryptoBlocks.Utils.unpack()

# ---3---
# Rebuild the file
dest = Path.join [current_path, "storage", "rebuild_lorem.txt"]
CryptoBlocks.rebuild clear_blocks, storage_path, dest

# -----

# Output md5 of original and rebuild file
{:ok, rebuild_data} = File.read dest
IO.puts "Original lorem.txt : #{:erlang.md5(data) |> Base.encode16(case: :lower)}"
IO.puts "Rebuild lorem.txt  : #{:erlang.md5(rebuild_data) |> Base.encode16(case: :lower)}"
