defmodule FraudDetect.Core.TransactionType do
  use Ecto.Schema
  import Ecto.Changeset

  schema "transaction_types" do
    field :transaction_type_name, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(transaction_type, attrs) do
    transaction_type
    |> cast(attrs, [:transaction_type_name])
    |> validate_required([:transaction_type_name])
  end
end
