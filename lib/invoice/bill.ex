defmodule Invoice.Bill do
  use Ecto.Schema
  use FnExpr
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]
  import ChangesetMerger, only: [derive_if_missing: 4, defaulted: 3]


  alias Invoice.{Bill, Action, Repo}
  alias ChangesetMerger.Token

  @default_precision 2

  @derive {Poison.Encoder, except: [:__meta__]}
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
  def changeset(amount, precision, params) do
    %Bill{}
    |> changeset(Map.merge(amount_to_db(amount, precision), params))
  end

  def create(amount, params), do: create(amount, @default_precision, params)
  def create(amount, precision, params) do
    changeset(amount, precision, params)
    |> Repo.insert!
    |> add_action("bill_created")
  end

  def update(bill, params) do
    bill
    |> changeset(params)
    |> Repo.update!
    |> add_action("bill_updated")
  end
  def update(bill, amount, precision, params) do
    params
    |> Map.merge(amount_to_db(amount, precision))
    |> invoke(update(bill, &1))
  end

  def find_or_create(amount, params), do: find_or_create(amount, @default_precision, params)
  def find_or_create(amount, precision, params) do
    changeset(amount, precision, params)
    |> invoke(&1.changes)
    |> invoke(find(&1[:entity_type], &1[:entity_id], &1[:name]))
    |> invoke(fn (b) -> if is_nil(b), do: create(amount, precision, params), else: b end)
  end

  def upsert(amount, params), do: upsert(amount, @default_precision, params)
  def upsert(amount, precision, params) do
    changeset(amount, precision, params)
    |> invoke(&1.changes)
    |> invoke(find(&1[:entity_type], &1[:entity_id], &1[:name]))
    |> invoke(fn
          nil -> create(amount, precision, params)
          b -> b |> update(amount, precision, params)
       end)
  end

  def find(type, id, name) do
    query = from t in Bill,
      where: t.entity_type == ^type and t.entity_id == ^id and t.name == ^name
    query |> Repo.one
  end
  def find(identifier) do
    query = from t in Bill,
      where: t.identifier == ^identifier
    query |> Repo.one
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
    |> invoke(fn{num, _} -> num end)
    |> amount_to_db(precision)
  end
  def amount_to_db(amount, precision) do
    %{amount: floor(amount * :math.pow(10, precision)), precision: precision}
  end

  @doc"""
  Convert to a simple map where the keys are strings

  ## Examples

      iex> Invoice.Bill.to_map(%Invoice.Bill{amount: 2000, precision: 2, currency: "usd"})
      %{"amount" => 2000, "precision" => 2, "currency" => "usd"}


      iex> Invoice.Bill.to_map(%Invoice.Bill{amount: 2000, precision: 2, currency: "usd"}, %{capture: false})
      %{"amount" => 2000, "precision" => 2, "currency" => "usd", "capture" => false}

  """
  def to_map(bill, additional_fields \\ %{}) do
    bill
    |> Map.drop([:__meta__, :__struct__])
    |> Map.merge(additional_fields)
    |> Enum.filter(fn {_, v} -> v !== nil end)
    |> Enum.map(fn {k, v} -> {"#{k}", v} end)
    |> Enum.into(%{})
  end

  @doc"""
  Prepare an amount for display.

  ## Examples

      iex> Invoice.Bill.amount_to_ui(%{amount: 2000, precision: 2, currency: "usd"})
      "$20.00 USD"

      iex> Invoice.Bill.amount_to_ui(%{amount: 2000, precision: 2, currency: "cad"})
      "$20.00 CAD"

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
  def amount_to_ui(%{amount: amount, precision: precision} = bill) do
    amount * :math.pow(10, -precision)
    |> :erlang.float_to_binary([decimals: precision])
    |> invoke(fn raw ->
                case Map.get(bill, :currency) do
                  nil -> raw
                  curr -> "$#{raw} #{curr |> String.upcase}"
                end
              end)
  end

  defp floor(i) when is_integer(i), do: i
  defp floor(f) when is_float(f), do: Float.floor(f) |> round

  defp add_action(bill, name) do
    Action.add(name, "Bill", bill.identifier)
    bill
  end
end