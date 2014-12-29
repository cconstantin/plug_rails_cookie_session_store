defmodule PlugRailsCookieSessionStore.Mixfile do
  use Mix.Project

  def project do
    [app: :plug_rails_cookie_session_store,
     version: "0.1.0",
     elixir: "~> 1.0",
     description: description,
     package: package,
     deps: deps]
  end

  def application do
    [applications: [:crypto, :logger]]
  end

  defp description do
    "Rails compatible Plug session store"
  end

  defp package do
    [contributors: ["Chris Constantin"],
     licenses: ["MIT"],
     links: %{"Github" => "https://github.com/cconstantin/plug_rails_cookie_session_store"}]
  end

  defp deps do
    [{:cowboy,  "~> 1.0", optional: true},
     {:plug,    ">= 0.9.0"},
     {:ex_doc,  github: "elixir-lang/ex_doc"}]
  end
end
