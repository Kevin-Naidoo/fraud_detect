defmodule FraudDetect.Core.AuditLog do
  use Ecto.Schema
  import Ecto.Changeset

  schema "audit_logs" do
    field :event_description, :string
    field :event_date, :utc_datetime
    field :transaction_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(audit_log, attrs) do
    audit_log
    |> cast(attrs, [:event_description, :event_date])
    |> validate_required([:event_description, :event_date])
  end
end
