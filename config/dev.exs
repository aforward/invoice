use Mix.Config

config :invoice, Invoice.Repo, [
  adapter: Ecto.Adapters.Postgres,
  database: "invoice_#{Mix.env}",
  username: "postgres",
  password: "",
  hostname: "localhost",
]