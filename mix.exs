defmodule PlugRailsCookieSessionStore.Mixfile do
  use Mix.Project

  def project do
    [
      app: :plug_rails_cookie_session_store,
      version: "0.3.0",
      elixir: "~> 1.0",
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  def application do
    [applications: [:crypto, :logger]]
  end

  defp description do
    "Rails compatible Plug session store"
  end

  defp package do
    [
      name: :plug_rails_cookie_session_store,
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Chris Constantin"],
      licenses: ["MIT"],
      links: %{"Github" => "https://github.com/cconstantin/plug_rails_cookie_session_store"}
    ]
  end

  defp deps do
    [
      {:plug, ">= 1.7.0"},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end
end
