defmodule CryptoBlocks.MixProject do
  use Mix.Project

  def project do
    [
      app: :crypto_blocks,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "Crypto Blocks",
      decription: "Split binary in many blocks of specific size."
    ]
  end

  def application do
    [
      extra_applications: [:logger, :crypto]
    ]
  end

  defp deps do
    []
  end
end
