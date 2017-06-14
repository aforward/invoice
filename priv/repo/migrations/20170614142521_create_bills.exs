defmodule Invoice.Repo.Migrations.CreateInvoices do
  use Ecto.Migration

  def change do
    create table(:bills) do
      add :identifier, :string
      add :name, :string            # Short name (more generic, e.g. Shoes)
      add :description, :string     # Longer description (more unqiue Size 10 Trainers)
      add :entity_type, :string     # an invoice for whom / what?
      add :entity_id, :string       # that whom/what's unique identifier
      add :amount, :integer         # absolute number
      add :precision, :integer      # number of decimal places
      add :currency, :string        # what currency, CAD, USD, etc
      add :payment_status, :string  # created, paid, cancelled

      add :data, :jsonb           # Additional data about the invoice

      timestamps()
    end
  end
end
