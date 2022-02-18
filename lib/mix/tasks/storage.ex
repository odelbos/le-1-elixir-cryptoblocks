defmodule Mix.Tasks.Storage do
  @moduledoc """
  Usage :

  mix storage --init       # Create the storage folder structure

  mix storage --clean      # Delete all stored files

  mix storage --remove     # Remove the storage folder
  """
  use Mix.Task

  @path File.cwd!
  @storage_path Path.join [@path, "storage"]
  @blocks_path Path.join [@storage_path, "blocks"]
  @files_path Path.join [@storage_path, "files"]

  @shortdoc "Manage the storage folder."
  def run(args) do
    case args do
      ["--init"] -> init()
      ["--clean"] -> clean()
      ["--remove"] -> remove()
      _ -> IO.puts "You must provide --init, --clean or --remove flag"
    end
  end

  defp init() do
    unless File.exists?(@storage_path), do: File.mkdir @storage_path
    unless File.exists?(@blocks_path), do: File.mkdir @blocks_path
    unless File.exists?(@files_path), do: File.mkdir @files_path
    IO.puts "Storage folder structure created."
  end

  defp clean() do
    remove()
    init()
  end

  defp remove() do
    if File.exists?(@storage_path), do: File.rm_rf @storage_path
    IO.puts "Storage folder deleted."
  end
end
