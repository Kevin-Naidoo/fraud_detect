defmodule FraudDetect.Core.Account do
  use Ecto.Schema
  import Ecto.Changeset

  schema "accounts" do

    field :customer_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(account, attrs) do
    account
    |> cast(attrs, [])
    |> validate_required([])
  end
end
