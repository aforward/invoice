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

  test "find_or_create" do
    original_bill = Bill.find_or_create(1, %{name: "10 bunnies", description: "x", entity_type: "A", entity_id: "123"})
    assert 100 == original_bill.amount
    assert "x" == original_bill.description

    same_bill = Bill.find_or_create(2, %{name: "10 bunnies", description: "y", entity_type: "A", entity_id: "123"})
    assert original_bill.identifier == same_bill.identifier
    assert 100 == same_bill.amount
    assert "x" == same_bill.description
  end

  test "upsert" do
    original_bill = Bill.upsert(1, %{name: "Bunny Purchase", description: "8 bunnies", entity_type: "A", entity_id: "123"})
    assert 100 == original_bill.amount
    assert "8 bunnies" == original_bill.description

    same_bill = Bill.upsert(2, %{name: "Bunny Purchase", description: "9 bunnies", entity_type: "A", entity_id: "123"})
    assert original_bill.identifier == same_bill.identifier
    assert 200 == same_bill.amount
    assert "9 bunnies" == same_bill.description
  end

  test "update" do
    bill = Bill.create(12.50, 3, %{description: "10 bunnies"})

    new_bill = Bill.update(bill, %{payment_status: "paid"})
    assert bill.identifier == new_bill.identifier
    assert "paid" == new_bill.payment_status

    assert ["bill_created", "bill_updated"] == Action.summary("Bill", bill.identifier)
  end

  test "find (entity)" do
    bill = Bill.find("A", "123", "10 bunnies")
    assert bill == nil

    original_bill = Bill.create(1, %{description: "10 bunnies", entity_type: "A", entity_id: "123"})
    bill = Bill.find("A", "123", "10 bunnies")

    assert original_bill.identifier == bill.identifier
  end

  test "find (identifier)" do
    bill = Bill.find("abc123")
    assert bill == nil

    original_bill = Bill.create(1, %{description: "10 bunnies", entity_type: "A", entity_id: "123"})
    bill = Bill.find(original_bill.identifier)

    assert original_bill.identifier == bill.identifier
    assert original_bill.description == bill.description
  end

  test "to_stripe_invoice (no additional args)" do
    assert Bill.to_map(%Invoice.Bill{amount: 10}) ==   %{"amount" => 10}
  end

  test "to_stripe_invoice (additional args" do
    assert Bill.to_map(%Invoice.Bill{amount: 10}, %{capture: false}) == %{"amount" => 10, "capture" => false}
  end

end
