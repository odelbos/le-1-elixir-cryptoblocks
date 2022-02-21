# Synopsis

This repository is an Elixir learning exercise.

**Disclaimer : Do not use this code in production.**

## Subject of the exercise

The subject of this exercise is to play with binary and pattern matching.

`CryptoBlocks` is used to split a binary in many encrypted blocks of specific size.

The input binary can be passed in one time to `CryptoBlocks` or in many times with chunks of different size.  
_(ex: receiving a big file from a socket or a stream and reading with a buffer)._

The encryption is made with the `AES 256 GCM` algorithm. Each block is encrypted with his own `key`and `iv`.

As we are working with an accumulator to fit the size of each block to the required size it is necessary to call the `final()` function at the end of the processus.

# Tests

```
mix test
```

# Usage

Create a `CryptoBlocks` structure with initial values :

- **storage** : The absolute path where to write the blocks
- **size** : The size of each block in bytes

### Example : Reading an entire file and split the binary

```elixir
{:ok, data} = File.read filepath

{:ok, blocks} = %CryptoBlocks{storage: "/..path...", size: 256}
  |> CryptoBlocks.write(data)
  |> CryptoBlocks.final()

IO.inspect blocks
```

### Example : Reading many chunks

_(each chunks can be of different size)_

```elixir
s = %CryptoBlocks{storage: "/..path...", size: 256}

# ... read the first chunk (from a socket or a stream)

s1 = CryptoBlocks.write(s, chunk1)

# ... read the second chunk

s2 = CryptoBlocks.write(s1, chunk2)

# ... read the next chunk

s3 = CryptoBlocks.write(s2, chunk3)

# Call the `final()` function and get the blocks description

{:ok, blocks} = CryptoBlocks.final(s3)

IO.inspect blocks
```

or

```elixir
{:ok, blocks} = %CryptoBlocks{storage: "/..path...", size: 256}
  |> CryptoBlocks.write(chunk1)
  |> CryptoBlocks.write(chunk2)
  |> CryptoBlocks.write(chunk3)
  |> CryptoBlocks.final()
```

## The blocks description

After calling the `final()` function you will receive a list containing the description of each block :


```
[
  %{                   # block 1
    id: << ... >>,     # id is used as file name for the block
    key: << ... >>,    # aes key (256 GCM)
    iv: << ... >>,     # aes iv
    tag: << ... >>     # aes tag
  },
  %{                   # block 2
    id: << ... >>,
    key: << ... >>,
    iv: << ... >>,
    tag: << ... >>
  },
  ...
]
```

`id`, `key`, `iv`, `tag` are of type binary.

Usually the last block is the remaining accumulator and it is smaller than the other blocks.  
_(the last block will have the same size than the other blocks only when the input binary size is a multiple of the chosen output block size)._

### Pack and unpack the blocks description

Some helper functions in the `Utils` module are used to pack/unpack the blocks description in a single binary.

Pack in a single binary :

```elixir
bin = CryptoBlocks.Utils.pack blocks
```

Usually, the packed blocks description is encrypted with a master key before being saved to disk.

Unpack the binary :

```elixir
blocks = CryptoBlocks.Utils.unpack bin
```

## Rebuild the original binary

- **blocks** : the blocks description
- **storage** : the absolute path where are stored the blocks
- **dest** : where to write the binary

```Elixir
dest = "/absolute/path/myfile.txt"
CryptoBlocks.rebuild blocks, storage, dest
```

## Delete blocks

```Elixir
CryptoBlocks.delete blocks, storage
```

# Examples

To use the examples you must create the storage folder, there is a mix task to do so.

The task will create the storage folder structure :

```
mix storage --init
```

To clean up the storage folder :

```
mix storage --clean
```

To remove the storage folder :

```
mix storage --remove
```

### Run the examples

```
mix run examples/1_basic.ex
```

```
mix run examples/2_many_chunks.ex
```

```
mix run examples/3_pack_and_encrypt.ex
```

```
mix storage --clean               # Make sure to start with a clean storage
mix run examples/4_delete.ex
```

# Status

- [x] Basic file splitter
- [x] Basic tests
- [x] Add block encryption
- [x] Add usage examples
- [ ] Error handling
- [ ] Add specs
- [ ] Add documentation

# Author

Author : @odelbos
