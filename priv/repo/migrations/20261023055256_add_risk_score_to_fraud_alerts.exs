defmodule FraudDetect.Repo.Migrations.AddRiskScoreToFraud_alerts do
  use Ecto.Migration

  def change do
    alter table(:fraud_alerts) do
      add :risk_score, :decimal, precision: 5, scale: 2
    end
  end
end
