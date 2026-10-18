defmodule FraudDetect.Core.Channel do
  use Ecto.Schema
  import Ecto.Changeset

  schema "channels" do
    field :channel_name, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(channel, attrs) do
    channel
    |> cast(attrs, [:channel_name])
    |> validate_required([:channel_name])
  end
end
