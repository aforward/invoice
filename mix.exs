defmodule Invoice.Mixfile do
  use Mix.Project

  @name    :invoice
  @version "0.1.0"

  @deps [
    {:mix_test_watch, github: "aforward/mix-test.watch", only: :dev, runtime: false},
    {:postgrex, "~> 0.13.2"},
    {:ecto, "~> 2.2.4"},
    {:poison, "~> 3.1.0"},
    {:fn_expr, "~> 0.2"},
    {:ex_doc, ">= 0.0.0", only: :dev},
    {:deferred_config, "~> 0.1"},
    {:changeset_merger, "~> 0.3.9"}
  ]

  @aliases [
    "ecto.reset": ["ecto.drop --quiet", "ecto.create --quiet", "ecto.migrate"],
    "test.once": ["ecto.reset", "test"],
  ]

  # ------------------------------------------------------------

  def project do
    in_production = Mix.env == :prod
    [
      app:     @name,
      version: @version,
      elixir:  "~> 1.4",
      deps:    @deps,
      aliases: @aliases,
      build_embedded:  in_production,
    ]
  end

  def application do
    [
      mod: { Invoice.Application, [] },
      extra_applications: [
        :logger
      ],
    ]
  end

end
