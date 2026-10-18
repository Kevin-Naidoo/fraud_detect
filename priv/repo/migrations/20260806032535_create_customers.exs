defmodule FraudDetect.Repo.Migrations.CreateCustomers do
  use Ecto.Migration

  def change do
    create table(:customers) do
      add :customer_name, :string

      timestamps(type: :utc_datetime)
    end
  end
end
