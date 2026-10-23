defmodule FraudDetect.FraudEngineTest do
  use FraudDetect.DataCase

  alias FraudDetect.Repo
  import Ecto.Query

  describe "Fraud Alerts Database Operations" do
    test "successfully inserts and updates a fraud alert status" do
      # 0. Seed lookup tables to satisfy foreign key constraints
      Repo.insert_all(
        "transaction_types",
        [
          [
            id: 1,
            transaction_type_name: "Purchase",
            inserted_at: NaiveDateTime.utc_now(),
            updated_at: NaiveDateTime.utc_now()
          ]
        ], on_conflict: :nothing)

      Repo.insert_all(
        "channels",
        [
          [
            id: 1,
            channel_name: "Online",
            inserted_at: NaiveDateTime.utc_now(),
            updated_at: NaiveDateTime.utc_now()
          ]
        ], on_conflict: :nothing)

      Repo.insert_all(
        "statuses",
        [
          [
            id: 1,
            status_name: "Completed",
            inserted_at: NaiveDateTime.utc_now(),
            updated_at: NaiveDateTime.utc_now()
          ]
        ], on_conflict: :nothing)

      Repo.insert_all(
        "fraud_risk_levels",
        [
          [
            id: 1,
            fraud_risk_level_name: "Low",
            inserted_at: NaiveDateTime.utc_now(),
            updated_at: NaiveDateTime.utc_now()
          ]
        ], on_conflict: :nothing)

      # 1. Insert a dummy customer to satisfy foreign keys
      {1, [%{id: customer_id}]} =
        Repo.insert_all(
          "customers",
          [
            [
              customer_name: "Test Customer",
              inserted_at: NaiveDateTime.utc_now(),
              updated_at: NaiveDateTime.utc_now()
            ]
          ],
          returning: [:id]
        )

      # 2. Insert a dummy account linked to the customer
      {1, [%{id: account_id}]} =
        Repo.insert_all(
          "accounts",
          [
            [
              customer_id: customer_id,
              inserted_at: NaiveDateTime.utc_now(),
              updated_at: NaiveDateTime.utc_now()
            ]
          ],
          returning: [:id]
        )

      # 3. Insert the transaction linked to the account
      {1, [%{id: tx_id}]} =
        Repo.insert_all(
          "transactions",
          [
            [
              amount_zar: Decimal.new("1500.00"),
              location: "Johannesburg",
              account_id: account_id,
              transaction_type_id: 1,
              channel_id: 1,
              status_id: 1,
              fraud_risk_level_id: 1,
              transaction_date: NaiveDateTime.utc_now(),
              inserted_at: NaiveDateTime.utc_now(),
              updated_at: NaiveDateTime.utc_now()
            ]
          ],
          returning: [:id]
        )

      # 4. Insert fraud alert with risk score
      {1, [%{id: alert_id}]} =
        Repo.insert_all(
          "fraud_alerts",
          [
            [
              transaction_id: tx_id,
              risk_score: Decimal.new("67.87"),
              alert_status: "Pending Review",
              alert_date: NaiveDateTime.utc_now(),
              inserted_at: NaiveDateTime.utc_now(),
              updated_at: NaiveDateTime.utc_now()
            ]
          ],
          returning: [:id]
        )

# Verify it exists as 'Pending Review'
      alert = Repo.one(from a in "fraud_alerts", where: a.id == ^alert_id, select: %{id: a.id, alert_status: a.alert_status})
      assert alert.alert_status == "Pending Review"

      # Simulate Dashboard 'Approve' Action
      Repo.update_all(
        from(a in "fraud_alerts", where: a.id == ^alert_id),
        set: [alert_status: "Approved", updated_at: NaiveDateTime.utc_now()]
      )

      updated_alert = Repo.one(from a in "fraud_alerts", where: a.id == ^alert_id, select: %{id: a.id, alert_status: a.alert_status})
      assert updated_alert.alert_status == "Approved"
    end
  end
end
