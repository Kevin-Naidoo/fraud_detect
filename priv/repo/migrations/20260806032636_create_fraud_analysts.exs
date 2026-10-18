defmodule FraudDetect.Repo.Migrations.CreateFraudAnalysts do
  use Ecto.Migration

  def change do
    create table(:fraud_analysts) do
      add :analyst_name, :string

      timestamps(type: :utc_datetime)
    end
  end
end
