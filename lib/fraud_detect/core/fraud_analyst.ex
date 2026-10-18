defmodule FraudDetect.Core.FraudAnalyst do
  use Ecto.Schema
  import Ecto.Changeset

  schema "fraud_analysts" do
    field :analyst_name, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(fraud_analyst, attrs) do
    fraud_analyst
    |> cast(attrs, [:analyst_name])
    |> validate_required([:analyst_name])
  end
end
