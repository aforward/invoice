use Mix.Config

config :invoice, ecto_repos: [Invoice.Repo]

if Mix.env == :dev do
  config :mix_test_watch,
    setup_tasks: ["ecto.reset"],
    ansi_enabled: :ignore,
    clear: true
end

import_config "#{Mix.env}.exs"