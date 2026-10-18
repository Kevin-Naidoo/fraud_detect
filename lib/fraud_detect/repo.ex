defmodule FraudDetect.Repo do
  use Ecto.Repo,
    otp_app: :fraud_detect,
    adapter: Ecto.Adapters.Postgres
end
