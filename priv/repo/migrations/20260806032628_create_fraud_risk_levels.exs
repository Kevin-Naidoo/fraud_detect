defmodule FraudDetect.Repo.Migrations.CreateFraudRiskLevels do
  use Ecto.Migration

  def change do
    create table(:fraud_risk_levels) do
      add :fraud_risk_level_name, :string

      timestamps(type: :utc_datetime)
    end
  end
end
