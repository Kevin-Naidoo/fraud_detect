alias FraudDetect.Repo
alias FraudDetect.Core.Transaction
import Ecto.Query

IO.puts("🚀 Starting Native Elixir ML Training & Inference Engine (Scholar)...")

# 1. Configure Nx to use EXLA backend
Nx.global_default_backend(EXLA.Backend)

# 2. Fetch all transactions ordered by ID
transactions = Repo.all(from t in Transaction, order_by: [asc: t.id])

if length(transactions) == 0 do
  IO.puts("❌ No transactions found in the database. Run your seeds script first!")
  System.halt(0)
end

IO.puts("📊 Total transactions loaded from DB: #{length(transactions)}")

# 3. Split Data: First 400 for Training, Rest for Real-Time Inference
{train_txs, test_txs} = Enum.split(transactions, 400)

IO.puts("🛠️ Training model on #{length(train_txs)} transactions...")

# 4. Feature Extraction & Normalization (Prevents model saturation)
extract_features = fn tx ->
  # Normalize amount between 0.0 and 1.0 (assuming R50,000 is a high baseline max)
  amount_float = Decimal.to_float(tx.amount_zar)
  normalized_amount = min(amount_float / 50000.0, 1.0)

  # Normalize categorical IDs by dividing by a safe max scalar (e.g., 10.0)
  [
    normalized_amount,
    tx.channel_id / 10.0,
    tx.transaction_type_id / 10.0,
    tx.status_id / 10.0
  ]
end

extract_target = fn tx ->
  if tx.fraud_risk_level_id == 3, do: 1, else: 0
end

x_train_list = Enum.map(train_txs, extract_features)
y_train_list = Enum.map(train_txs, extract_target)

x_train = Nx.tensor(x_train_list)
y_train = Nx.tensor(y_train_list, type: {:s, 64})

# 5. Train using Scholar's Logistic Regression Classifier (Native Elixir)
model = Scholar.Linear.LogisticRegression.fit(x_train, y_train, num_classes: 2)
IO.puts("✅ Model training completed successfully!")

# 6. Real-Time Inference Simulation on Test Set (Remaining transactions)
IO.puts("⚡ Running real-time inference on #{length(test_txs)} streaming transactions...")

{fraud_detected_count, _} = Enum.reduce(test_txs, {0, 0}, fn tx, {acc, index} ->
  x_sample = Nx.tensor([extract_features.(tx)])

  probabilities = Scholar.Linear.LogisticRegression.predict_probability(model, x_sample)

  risk_score =
    case Nx.to_flat_list(probabilities) do
      [_p0, p1] -> p1
      [p0] -> p0
      _ -> 0.0
    end

  # Print the first 10 raw scores to see what the model is outputting
  if index < 10 do
    IO.puts("🔍 Tx ID #{tx.id} | Amount: #{tx.amount_zar} | Risk Score: #{Float.round(risk_score * 100, 2)}%")
  end

  # Let's lower the threshold temporarily to 0.15 (15%) to see if anything gets caught
 if risk_score > 0.35 do
    Repo.query!(
      "INSERT INTO fraud_alerts (transaction_id, risk_score, alert_status, alert_date, inserted_at, updated_at) VALUES ($1, $2, 'Pending Review', NOW(), NOW(), NOW()) ON CONFLICT DO NOTHING",
      [tx.id, Float.round(risk_score * 100, 2)]
    )

    # Broadcast event to LiveView subscribers
    Phoenix.PubSub.broadcast(FraudDetect.PubSub, "fraud_alerts", {:new_alert, tx.id})

    {acc + 1, index + 1}
  else
    {acc, index + 1}
  end
end)

IO.puts("🎯 Inference complete! Flagged #{fraud_detected_count} high-risk transactions.")
