defmodule FraudDetect.Repo.Migrations.CreateFraudReviews do
  use Ecto.Migration

  def change do
    create table(:fraud_reviews) do
      add :review_outcome, :string
      add :review_date, :utc_datetime
      add :alert_id, references(:fraud_alerts, on_delete: :nothing)
      add :analyst_id, references(:fraud_analysts, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:fraud_reviews, [:alert_id])
    create index(:fraud_reviews, [:analyst_id])
  end
end
