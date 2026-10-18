defmodule FraudDetect.Core.FraudAlert do
  use Ecto.Schema
  import Ecto.Changeset

  schema "fraud_alerts" do
    field :alert_date, :utc_datetime
    field :alert_status, :string
    field :transaction_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(fraud_alert, attrs) do
    fraud_alert
    |> cast(attrs, [:alert_date, :alert_status])
    |> validate_required([:alert_date, :alert_status])
  end
end
