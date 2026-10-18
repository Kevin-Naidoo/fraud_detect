defmodule FraudDetect.Repo.Migrations.CreateNotifications do
  use Ecto.Migration

  def change do
    create table(:notifications) do
      add :notification_date, :utc_datetime
      add :notification_type, :string
      add :transaction_id, references(:transactions, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:notifications, [:transaction_id])
  end
end
