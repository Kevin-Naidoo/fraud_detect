defmodule FraudDetect.Core.Status do
  use Ecto.Schema
  import Ecto.Changeset

  schema "statuses" do
    field :status_name, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(status, attrs) do
    status
    |> cast(attrs, [:status_name])
    |> validate_required([:status_name])
  end
end
