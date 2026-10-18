defmodule FraudDetect.Repo.Migrations.CreateTransactions do
  use Ecto.Migration

  def change do
    create table(:transactions) do
      add :transaction_date, :utc_datetime
      add :amount_zar, :decimal
      add :location, :string
      add :account_id, references(:accounts, on_delete: :nothing)
      add :transaction_type_id, references(:transaction_types, on_delete: :nothing)
      add :channel_id, references(:channels, on_delete: :nothing)
      add :status_id, references(:statuses, on_delete: :nothing)
      add :fraud_risk_level_id, references(:fraud_risk_levels, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:transactions, [:account_id])
    create index(:transactions, [:transaction_type_id])
    create index(:transactions, [:channel_id])
    create index(:transactions, [:status_id])
    create index(:transactions, [:fraud_risk_level_id])
  end
end
