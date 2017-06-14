defmodule Invoice.BillTest do
  use ExUnit.Case, async: true

  alias Invoice.{Bill, Action, Repo}
  doctest Invoice.Bill

  setup do
    # Explicitly get a connection before each test
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  end

  test "create - default values" do
    bill = Bill.create(10.99, %{description: "10 bunnies"})

    assert "10 bunnies" == bill.name
    assert "10 bunnies" == bill.description
    assert nil == bill.entity_type
    assert nil == bill.entity_id
    assert 1099 == bill.amount
    assert 2 == bill.precision
    assert "CAD" == bill.currency # yes, canadian :-p
    assert "created" == bill.payment_status
    assert nil == bill.data
  end

  test "create - custom precision" do
    bill = Bill.create(12.50, 3, %{description: "10 bunnies"})

    assert 12500 == bill.amount
    assert 3 == bill.precision

    assert ["bill_created"] == Action.summary("Bill", bill.identifier)
  end

  test "create - entity" do
    bill = Bill.create(1, %{description: "10 bunnies", entity_type: "A", entity_id: "123"})

    assert "A" == bill.entity_type
    assert "123" == bill.entity_id
  end

  test "create - data" do
    bill = Bill.create(1, %{description: "10 bunnies",data: %{"tax" => 0.15}})
    assert %{"tax" => 0.15} == bill.data
  end

  test "update" do
    bill = Bill.create(12.50, 3, %{description: "10 bunnies"})

    new_bill = Bill.update(bill, %{payment_status: "paid"})
    assert bill.identifier == new_bill.identifier
    assert "paid" == new_bill.payment_status

    assert ["bill_created", "bill_updated"] == Action.summary("Bill", bill.identifier)
  end
end
