defmodule FraudDetect.Core.Customer do
  use Ecto.Schema
  import Ecto.Changeset

  schema "customers" do
    field :customer_name, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(customer, attrs) do
    customer
    |> cast(attrs, [:customer_name])
    |> validate_required([:customer_name])
  end
end
