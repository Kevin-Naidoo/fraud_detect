NimbleCSV.define(MyParser, separator: ",", escape: "\"")

alias FraudDetect.Repo
alias FraudDetect.Core.Transaction
alias FraudDetect.Core.Customer

csv_path = "priv/repo/transactions_1000_simulated.csv"

# Seed basic lookup tables if empty
Repo.query!(
  "INSERT INTO statuses (id, status_name, inserted_at, updated_at) VALUES (1, 'Success', NOW(), NOW()), (2, 'Failed', NOW(), NOW()), (3, 'Pending', NOW(), NOW()), (4, 'Flagged', NOW(), NOW()) ON CONFLICT (id) DO NOTHING"
)

Repo.query!(
  "INSERT INTO channels (id, channel_name, inserted_at, updated_at) VALUES (1, 'POS Terminal', NOW(), NOW()), (2, 'Mobile App', NOW(), NOW()), (3, 'Online Banking', NOW(), NOW()), (4, 'ATM', NOW(), NOW()), (5, 'Branch', NOW(), NOW()) ON CONFLICT (id) DO NOTHING"
)

Repo.query!(
  "INSERT INTO transaction_types (id, transaction_type_name, inserted_at, updated_at) VALUES (1, 'ATM Withdrawal', NOW(), NOW()), (2, 'Cash Deposit', NOW(), NOW()), (3, 'Salary Deposit', NOW(), NOW()), (4, 'EFT Payment', NOW(), NOW()), (5, 'Online Transfer', NOW(), NOW()), (6, 'International Payment', NOW(), NOW()), (7, 'POS Payment', NOW(), NOW()) ON CONFLICT (id) DO NOTHING"
)

Repo.query!(
  "INSERT INTO fraud_risk_levels (id, fraud_risk_level_name, inserted_at, updated_at) VALUES (1, 'Low', NOW(), NOW()), (2, 'Medium', NOW(), NOW()), (3, 'High', NOW(), NOW()) ON CONFLICT (id) DO NOTHING"
)

# 1. DateTime Parser
parse_datetime = fn date_str ->
  [year, month, day] = String.split(date_str, "/") |> Enum.map(&String.to_integer/1)

  NaiveDateTime.new!(year, month, day, 12, 0, 0)
  |> DateTime.from_naive!("Etc/UTC")
end

# 2. Lookup Encoders
get_type_id = fn
  "ATM Withdrawal" -> 1
  "Cash Deposit" -> 2
  "Salary Deposit" -> 3
  "EFT Payment" -> 4
  "Online Transfer" -> 5
  "International Payment" -> 6
  "POS Payment" -> 7
  _ -> 1
end

get_channel_id = fn
  "POS Terminal" -> 1
  "Mobile App" -> 2
  "Online Banking" -> 3
  "ATM" -> 4
  "Branch" -> 5
  _ -> 1
end

get_status_id = fn
  "Success" -> 1
  "Failed" -> 2
  "Pending" -> 3
  "Flagged" -> 4
  _ -> 1
end

get_risk_id = fn
  "Low" -> 1
  "Medium" -> 2
  "High" -> 3
  _ -> 1
end

# 3. Helper: Ensures unique Customer and Account exist before Transaction insert
ensure_customer_and_account = fn acc_num_str, customer_name ->
  account_id =
    case Integer.parse(acc_num_str) do
      {num, _} -> num
      :error -> 1
    end

  # Check or insert Customer uniquely by name
  customer_query =
    Repo.query!("SELECT id FROM customers WHERE customer_name = $1", [customer_name])

  customer_id =
    case customer_query.rows do
      [[existing_id]] ->
        existing_id

      [] ->
        res =
          Repo.query!(
            "INSERT INTO customers (customer_name, inserted_at, updated_at) VALUES ($1, NOW(), NOW()) RETURNING id",
            [customer_name]
          )

        [[new_id]] = res.rows
        new_id
    end

  # Check or insert Account linked to this unique customer
  account_query = Repo.query!("SELECT id FROM accounts WHERE id = $1", [account_id])

  case account_query.num_rows do
    0 ->
      Repo.query!(
        "INSERT INTO accounts (id, customer_id, inserted_at, updated_at) VALUES ($1, $2, NOW(), NOW()) ON CONFLICT (id) DO NOTHING",
        [account_id, customer_id]
      )

    _ ->
      :ok
  end

  account_id
end

# 4. CSV Import Loop (Single Pass)
csv_path
|> File.stream!()
|> MyParser.parse_stream()
|> Stream.drop(1)
|> Enum.each(fn [_tx_id, acc_num, cust, tx_date, tx_type, amt, channel, loc, status, risk] ->
  valid_account_id = ensure_customer_and_account.(acc_num, cust)

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

IO.puts("Successfully imported all 1,000 seed transactions with unique customers and accounts!")
