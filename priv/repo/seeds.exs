NimbleCSV.define(MyParser, separator: ",", escape: "\"")

alias FraudDetect.Repo
alias FraudDetect.Core.Transaction

csv_path = "priv/repo/transactions_1000_simulated.csv"

# Seed basic lookup tables if empty
Repo.query!(
  "INSERT INTO statuses (id, status_name, inserted_at, updated_at) VALUES (1, 'Success', NOW(), NOW()), (2, 'Failed', NOW(), NOW()), (3, 'Pending', NOW(), NOW()) ON CONFLICT (id) DO NOTHING"
)

Repo.query!(
  "INSERT INTO channels (id, channel_name, inserted_at, updated_at) VALUES (1, 'POS Terminal', NOW(), NOW()), (2, 'Mobile App', NOW(), NOW()), (3, 'Web Banking', NOW(), NOW()), (4, 'ATM', NOW(), NOW()) ON CONFLICT (id) DO NOTHING"
)

Repo.query!(
  "INSERT INTO transaction_types (id, transaction_type_name, inserted_at, updated_at) VALUES (1, 'ATM Withdrawal', NOW(), NOW()), (2, 'Online Transfer', NOW(), NOW()), (3, 'POS Payment', NOW(), NOW()) ON CONFLICT (id) DO NOTHING"
)

Repo.query!(
  "INSERT INTO fraud_risk_levels (id, fraud_risk_level_name, inserted_at, updated_at) VALUES (1, 'Low', NOW(), NOW()), (2, 'Medium', NOW(), NOW()), (3, 'High', NOW(), NOW()) ON CONFLICT (id) DO NOTHING"
)

# 1. Helper: Ensures Customer and Account exist in PostgreSQL before Transaction insert
ensure_account_exists = fn acc_num_str ->
  account_id =
    case Integer.parse(acc_num_str) do
      {num, _} -> num
      :error -> 1
    end

  # Check if account exists; if not, create dummy parent customer + account
  case Repo.query("SELECT id FROM accounts WHERE id = $1", [account_id]) do
    {:ok, %{num_rows: 0}} ->
      Repo.query!(
        "INSERT INTO customers (id, customer_name, inserted_at, updated_at) VALUES (1, 'Seed Customer', NOW(), NOW()) ON CONFLICT (id) DO NOTHING"
      )

      Repo.query!(
        "INSERT INTO accounts (id, customer_id, inserted_at, updated_at) VALUES ($1, 1, NOW(), NOW()) ON CONFLICT (id) DO NOTHING",
        [account_id]
      )

      account_id

    {:ok, _} ->
      account_id
  end
end

# 2. DateTime Parser
parse_datetime = fn date_str ->
  [year, month, day] = String.split(date_str, "/") |> Enum.map(&String.to_integer/1)

  NaiveDateTime.new!(year, month, day, 12, 0, 0)
  |> DateTime.from_naive!("Etc/UTC")
end

# 3. Lookup Encoders
get_type_id = fn
  "ATM Withdrawal" -> 1
  "Online Transfer" -> 2
  "POS Payment" -> 3
  _ -> 1
end

get_channel_id = fn
  "POS Terminal" -> 1
  "Mobile App" -> 2
  "Web Banking" -> 3
  "ATM" -> 4
  _ -> 1
end

get_status_id = fn
  "Success" -> 1
  "Failed" -> 2
  "Pending" -> 3
  _ -> 1
end

get_risk_id = fn
  "Low" -> 1
  "Medium" -> 2
  "High" -> 3
  _ -> 1
end

# 4. CSV Import Loop
csv_path
|> File.stream!()
|> MyParser.parse_stream()
|> Stream.drop(1)
|> Enum.each(fn [_tx_id, acc_num, _cust, tx_date, tx_type, amt, channel, loc, status, risk] ->
  valid_account_id = ensure_account_exists.(acc_num)

  Repo.insert!(%Transaction{
    transaction_date: parse_datetime.(tx_date),
    amount_zar: Decimal.new(amt),
    location: loc,
    account_id: valid_account_id,
    transaction_type_id: get_type_id.(tx_type),
    channel_id: get_channel_id.(channel),
    status_id: get_status_id.(status),
    fraud_risk_level_id: get_risk_id.(risk)
  })
end)

IO.puts("Successfully imported all 1,000 seed transactions!")
