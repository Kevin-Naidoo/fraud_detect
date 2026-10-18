defmodule FraudDetect.Core.FraudRiskLevel do
  use Ecto.Schema
  import Ecto.Changeset

  schema "fraud_risk_levels" do
    field :fraud_risk_level_name, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(fraud_risk_level, attrs) do
    fraud_risk_level
    |> cast(attrs, [:fraud_risk_level_name])
    |> validate_required([:fraud_risk_level_name])
  end
end
