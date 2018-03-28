defmodule Exred.Node.GPIOIn.Mixfile do
  use Mix.Project

  def project do
    [
      app: :exred_node_gpio_in,
      version: "0.1.1",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:exred_library, git: "git@bitbucket.org:zsolt001/exred_library.git"},
      {:elixir_ale, "~> 1.0"}
    ]
  end
end