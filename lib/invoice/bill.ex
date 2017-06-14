defmodule Invoice.Bill do
  use Ecto.Schema
  import Ecto.Changeset
  import ChangesetMerger, only: [derive_if_missing: 4, defaulted: 3]

  alias Invoice.{Bill, Action, Repo}
  alias ChangesetMerger.Token

  @default_precision 2

  schema "bills" do
    field :identifier, :string
    field :name, :string
    field :description, :string
    field :entity_type, :string
    field :entity_id, :string
    field :amount, :integer
    field :precision, :integer
    field :currency, :string
    field :payment_status, :string
    field :data, :map

    timestamps()
  end

  def changeset(record, params) do
    record
    |> cast(params, [:identifier, :name, :description, :entity_type, :entity_id, :amount, :precision, :currency, :payment_status, :data])
    |> Token.defaulted(:identifier, 20)
    |> derive_if_missing(:description, :name, &(&1))
    |> defaulted(:currency, "CAD")
    |> defaulted(:payment_status, "created")
    |> validate_required([:description])
  end

  def create(amount, params), do: create(amount, @default_precision, params)
  def create(amount, precision, params) do
    %Bill{}
    |> changeset(Map.merge(amount_to_db(amount, precision), params))
    |> Repo.insert!
    |> add_action("bill_created")
  end

  def update(bill, params) do
    bill
    |> changeset(params)
    |> Repo.update!
    |> add_action("bill_updated")
  end

  @doc"""
  Prepare an amount for the database.  If it's an integer, nothing
  to do.  If it's a float, then noramlize it based on the precision.

  ## Examples

      iex> Invoice.Bill.amount_to_db(20, 2)
      %{amount: 2000, precision: 2}

      iex> Invoice.Bill.amount_to_db("20", 2)
      %{amount: 2000, precision: 2}

      iex> Invoice.Bill.amount_to_db(20.0, 2)
      %{amount: 2000, precision: 2}

      iex> Invoice.Bill.amount_to_db(20.0, 0)
      %{amount: 20, precision: 0}

      iex> Invoice.Bill.amount_to_db(20.0, 2)
      %{amount: 2000, precision: 2}

      iex> Invoice.Bill.amount_to_db(20.50, 2)
      %{amount: 2050, precision: 2}

      iex> Invoice.Bill.amount_to_db(12.3456, 3)
      %{amount: 12345, precision: 3}

      iex> Invoice.Bill.amount_to_db(12.3459, 4)
      %{amount: 123459, precision: 4}

  """
  def amount_to_db(nil, _precision), do: 0
  def amount_to_db(amount, precision) when is_binary(amount) do
    amount
    |> Float.parse
    |> (fn{num, _} -> num end).()
    |> amount_to_db(precision)
  end
  def amount_to_db(amount, precision) do
    %{amount: floor(amount * :math.pow(10, precision)), precision: precision}
  end

  @doc"""
  Prepare an amount for display.

  ## Examples

      iex> Invoice.Bill.amount_to_ui(%{amount: 2000, precision: 2})
      "20.00"

      iex> Invoice.Bill.amount_to_ui(%{amount: 20, precision: 0})
      "20"

      iex> Invoice.Bill.amount_to_ui(%{amount: 2050, precision: 2})
      "20.50"

      iex> Invoice.Bill.amount_to_ui(%{amount: 12345, precision: 3})
      "12.345"

      iex> Invoice.Bill.amount_to_ui(%{amount: 123459, precision: 4})
      "12.3459"

  """
  def amount_to_ui(%{amount: amount, precision: precision}) do
    amount * :math.pow(10, -precision)
    |> :erlang.float_to_binary([decimals: precision])
  end

  defp floor(i) when is_integer(i), do: i
  defp floor(f) when is_float(f), do: Float.floor(f) |> round

  defp add_action(bill, name) do
    Action.add(name, "Bill", bill.identifier)
    bill
  end
end