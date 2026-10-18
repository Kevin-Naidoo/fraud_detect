defmodule FraudDetect.Core do
  import Ecto.Query, warn: false
  alias FraudDetect.Repo
  alias FraudDetect.Core.Customer

  def list_customers do
    Repo.all(Customer)
  end

  def change_customer(%Customer{} = customer, attrs \\ %{}) do
    Customer.changeset(customer, attrs)
  end

  def create_customer(attrs \\ %{}) do
    %Customer{}
    |> Customer.changeset(attrs)
    |> Repo.insert()
  end
end
