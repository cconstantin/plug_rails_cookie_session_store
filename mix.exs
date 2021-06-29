defmodule PlugRailsCookieSessionStore.Mixfile do
  use Mix.Project

  @source_url "https://github.com/cconstantin/plug_rails_cookie_session_store"
  @version "2.0.0"

  def project do
    [
      app: :plug_rails_cookie_session_store,
      version: @version,
      elixir: "~> 1.0",
      package: package(),
      deps: deps(),
      docs: docs()
    ]
  end

  def application do
    [
      applications: [:crypto, :logger, :plug_crypto]
    ]
  end

  defp package do
    [
      name: :plug_rails_cookie_session_store,
      description: "Rails compatible Plug session store",
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Chris Constantin"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url
      }
    ]
  end

  defp deps do
    [
      {:plug, ">= 1.11.0"},
      {:plug_crypto, ">= 1.2.0"},
      {:ex_doc, ">= 0.24.2", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      extras: [
        "LICENSE.md": [title: "License"],
        "README.md": [title: "Overview"]
      ],
      main: "readme",
      source_url: @source_url,
      formatters: ["html"]
    ]
  end
end
