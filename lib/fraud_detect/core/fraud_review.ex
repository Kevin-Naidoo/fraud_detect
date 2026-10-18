defmodule FraudDetect.Core.FraudReview do
  use Ecto.Schema
  import Ecto.Changeset

  schema "fraud_reviews" do
    field :review_outcome, :string
    field :review_date, :utc_datetime
    field :alert_id, :id
    field :analyst_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(fraud_review, attrs) do
    fraud_review
    |> cast(attrs, [:review_outcome, :review_date])
    |> validate_required([:review_outcome, :review_date])
  end
end
