defmodule FraudDetect.Repo.Migrations.CreateAuditLogs do
  use Ecto.Migration

  def change do
    create table(:audit_logs) do
      add :event_description, :string
      add :event_date, :utc_datetime
      add :transaction_id, references(:transactions, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:audit_logs, [:transaction_id])
  end
end
