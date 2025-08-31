defmodule AshCloak.MixProject do
  use Mix.Project

  @description """
  An Ash extension to seamlessly encrypt and decrypt resource attributes.
  """

  @version "0.1.7"

  def project do
    [
      app: :ash_cloak,
      version: @version,
      package: package(),
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      docs: &docs/0,
      dialyzer: [plt_add_apps: [:mix]],
      aliases: aliases(),
      description: @description,
      source_url: "https://github.com/ash-project/ash_cloak",
      homepage_url: "https://github.com/ash-project/ash_cloak"
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      extra_section: "GUIDES",
      extras: [
        {"README.md", title: "Home"},
        "documentation/tutorials/getting-started-with-ash-cloak.md",
        "documentation/topics/how-does-ash-cloak-work.md",
        {"documentation/dsls/DSL-AshCloak.md", search_data: Spark.Docs.search_data_for(AshCloak)},
        "CHANGELOG.md"
      ],
      groups_for_extras: [
        Tutorials: ~r"documentation/tutorials",
        Topics: ~r"documentation/topics",
        Reference: ~r"documentation/dsls",
        "About AshCloak": [
          "CHANGELOG.md"
        ]
      ],
      before_closing_head_tag: fn type ->
        if type == :html do
          """
          <script>
            if (location.hostname === "hexdocs.pm") {
              var script = document.createElement("script");
              script.src = "https://plausible.io/js/script.js";
              script.setAttribute("defer", "defer")
              script.setAttribute("data-domain", "ashhexdocs")
              document.head.appendChild(script);
            }
          </script>
          """
        end
      end
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp package do
    [
      name: :ash_cloak,
      licenses: ["MIT"],
      files: ~w(lib .formatter.exs mix.exs README* LICENSE*
      CHANGELOG* documentation),
      links: %{
        GitHub: "https://github.com/ash-project/ash_cloak"
      }
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ash, ash_version("~> 3.0")},
      {:igniter, "~> 0.5", only: [:dev, :test]},
      {:ex_doc, "~> 0.37-rc", only: [:dev, :test], runtime: false},
      {:ex_check, "~> 0.12", only: [:dev, :test]},
      {:credo, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:dialyxir, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:sobelow, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:git_ops, "~> 2.5", only: [:dev, :test]},
      {:mix_test_watch, "~> 1.0", only: :dev, runtime: false},
      {:simple_sat, ">= 0.0.0", only: :test},
      {:mix_audit, ">= 0.0.0", only: [:dev, :test], runtime: false}
    ]
  end

  defp ash_version(default_version) do
    case System.get_env("ASH_VERSION") do
      nil -> default_version
      "local" -> [path: "../ash"]
      "main" -> [git: "https://github.com/ash-project/ash.git"]
      version -> "~> #{version}"
    end
  end

  defp aliases do
    [
      sobelow: "sobelow --skip",
      credo: "credo --strict",
      docs: [
        "spark.cheat_sheets",
        "docs",
        "spark.replace_doc_links"
      ],
      "spark.formatter": "spark.formatter --extensions AshCloak",
      "spark.cheat_sheets_in_search": "spark.cheat_sheets_in_search --extensions AshCloak",
      "spark.cheat_sheets": "spark.cheat_sheets --extensions AshCloak"
    ]
  end
end
