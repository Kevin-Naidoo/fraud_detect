defmodule FraudDetect.Repo.Migrations.CreateFraudAlerts do
  use Ecto.Migration

  def change do
    create table(:fraud_alerts) do
      add :alert_date, :utc_datetime
      add :alert_status, :string
      add :transaction_id, references(:transactions, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:fraud_alerts, [:transaction_id])
  end
end
