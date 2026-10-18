defmodule FraudDetect.Core.Notification do
  use Ecto.Schema
  import Ecto.Changeset

  schema "notifications" do
    field :notification_date, :utc_datetime
    field :notification_type, :string
    field :transaction_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(notification, attrs) do
    notification
    |> cast(attrs, [:notification_date, :notification_type])
    |> validate_required([:notification_date, :notification_type])
  end
end
