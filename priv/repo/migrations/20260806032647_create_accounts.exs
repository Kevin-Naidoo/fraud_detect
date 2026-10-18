defmodule FraudDetect.Repo.Migrations.CreateAccounts do
  use Ecto.Migration

  def change do
    create table(:accounts) do
      add :customer_id, references(:customers, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:accounts, [:customer_id])
  end
end
