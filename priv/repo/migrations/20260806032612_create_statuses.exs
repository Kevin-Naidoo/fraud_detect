defmodule FraudDetect.Repo.Migrations.CreateStatuses do
  use Ecto.Migration

  def change do
    create table(:statuses) do
      add :status_name, :string

      timestamps(type: :utc_datetime)
    end
  end
end
