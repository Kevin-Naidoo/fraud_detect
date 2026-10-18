defmodule FraudDetect.Core.Transaction do
  use Ecto.Schema
  import Ecto.Changeset

  schema "transactions" do
    field :transaction_date, :utc_datetime
    field :amount_zar, :decimal
    field :location, :string
    field :account_id, :id
    field :transaction_type_id, :id
    field :channel_id, :id
    field :status_id, :id
    field :fraud_risk_level_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [:transaction_date, :amount_zar, :location])
    |> validate_required([:transaction_date, :amount_zar, :location])
  end
end
