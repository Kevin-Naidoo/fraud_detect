defmodule FraudDetectWeb.FraudLive do
  use FraudDetectWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       # Form state
       account_id: "",
       amount_zar: "",
       location: "Johannesburg",

       # Real-Time Monitoring Dashboard metrics (US6)
       total_transactions: 0,
       completed_count: 0,
       blocked_count: 0,
       pending_review_count: 0,

       # In-memory datasets (US1, US3, US5)
       transactions: [],
       pending_reviews: [],
       audit_logs: []
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto p-6 space-y-8 font-sans">
      <h1 class="text-3xl font-bold text-gray-900 border-b pb-4">
        Real-Time Fraud Detection & Case Management
      </h1>
      
    <!-- US6: Real-Time Monitoring Dashboard Metrics -->
      <div class="grid grid-cols-4 gap-4">
        <div class="p-4 bg-blue-50 border border-blue-200 rounded-lg text-center">
          <p class="text-xs uppercase font-semibold text-blue-600">Total Processed</p>
          <p class="text-2xl font-bold text-blue-900">{@total_transactions}</p>
        </div>
        <div class="p-4 bg-green-50 border border-green-200 rounded-lg text-center">
          <p class="text-xs uppercase font-semibold text-green-600">Completed (No Risk)</p>
          <p class="text-2xl font-bold text-green-900">{@completed_count}</p>
        </div>
        <div class="p-4 bg-yellow-50 border border-yellow-200 rounded-lg text-center">
          <p class="text-xs uppercase font-semibold text-yellow-600">Under Review</p>
          <p class="text-2xl font-bold text-yellow-900">{@pending_review_count}</p>
        </div>
        <div class="p-4 bg-red-50 border border-red-200 rounded-lg text-center">
          <p class="text-xs uppercase font-semibold text-red-600">Blocked (Fraud)</p>
          <p class="text-2xl font-bold text-red-900">{@blocked_count}</p>
        </div>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
        
    <!-- US1: Customer Initiate Transaction Form -->
        <div class="bg-white p-6 border rounded-lg shadow-sm space-y-4">
          <h2 class="text-lg font-bold text-gray-800">1. Initiate Customer Transaction</h2>
          <form phx-submit="process_transaction" class="space-y-4">
            <div>
              <label class="block text-sm font-medium text-gray-700">Account ID</label>
              <input
                type="number"
                name="account_id"
                value={@account_id}
                required
                class="mt-1 w-full border rounded p-2 text-sm"
                placeholder="e.g. 101"
              />
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700">Amount (ZAR)</label>
              <input
                type="number"
                step="0.01"
                name="amount_zar"
                value={@amount_zar}
                required
                class="mt-1 w-full border rounded p-2 text-sm"
                placeholder="e.g. 12500.00"
              />
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700">Location</label>
              <select name="location" class="mt-1 w-full border rounded p-2 text-sm">
                <option value="Johannesburg">Johannesburg</option>
                <option value="Cape Town">Cape Town</option>
                <option value="International/Unusual">International/Unusual</option>
              </select>
            </div>

            <button
              type="submit"
              class="w-full bg-blue-600 text-white font-medium py-2 rounded hover:bg-blue-700"
            >
              Submit Transaction
            </button>
          </form>
        </div>
        
    <!-- US3 & US4: Manual Review Queue for Analysts -->
        <div class="lg:col-span-2 bg-white p-6 border rounded-lg shadow-sm space-y-4">
          <h2 class="text-lg font-bold text-gray-800">2. Analyst Review Queue (High Risk Alerts)</h2>
          <%= if Enum.empty?(@pending_reviews) do %>
            <p class="text-sm text-gray-500 italic py-4">
              No suspicious transactions currently pending review.
            </p>
          <% else %>
            <div class="overflow-x-auto">
              <table class="w-full text-left text-sm border-collapse">
                <thead>
                  <tr class="border-b bg-gray-50">
                    <th class="p-2">Tx ID</th>
                    <th class="p-2">Account</th>
                    <th class="p-2">Amount</th>
                    <th class="p-2">Reason</th>
                    <th class="p-2 text-right">Action</th>
                  </tr>
                </thead>
                <tbody>
                  <%= for review <- @pending_reviews do %>
                    <tr class="border-b">
                      <td class="p-2 font-mono">{review.id}</td>
                      <td class="p-2">{review.account_id}</td>
                      <td class="p-2 font-semibold">R {review.amount_zar}</td>
                      <td class="p-2 text-xs text-red-600 font-medium">{review.reason}</td>
                      <td class="p-2 text-right space-x-2">
                        <button
                          phx-click="resolve_review"
                          phx-value-id={review.id}
                          phx-value-decision="legitimate"
                          class="px-2 py-1 bg-green-600 text-white rounded text-xs"
                        >
                          Approve
                        </button>
                        <button
                          phx-click="resolve_review"
                          phx-value-id={review.id}
                          phx-value-decision="fraud"
                          class="px-2 py-1 bg-red-600 text-white rounded text-xs"
                        >
                          Block
                        </button>
                      </td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
          <% end %>
        </div>
      </div>
      
    <!-- Live Transaction Log -->
      <div class="bg-white p-6 border rounded-lg shadow-sm space-y-4">
        <h2 class="text-lg font-bold text-gray-800">3. Real-Time Transaction Log</h2>
        <div class="overflow-x-auto">
          <table class="w-full text-left text-sm border-collapse">
            <thead>
              <tr class="border-b bg-gray-50 text-gray-600">
                <th class="p-2">Tx ID</th>
                <th class="p-2">Account</th>
                <th class="p-2">Amount</th>
                <th class="p-2">Location</th>
                <th class="p-2">Status</th>
              </tr>
            </thead>
            <tbody>
              <%= for tx <- @transactions do %>
                <tr class="border-b">
                  <td class="p-2 font-mono">{tx.id}</td>
                  <td class="p-2">{tx.account_id}</td>
                  <td class="p-2">R {tx.amount_zar}</td>
                  <td class="p-2">{tx.location}</td>
                  <td class="p-2">
                    <span class={
                      case tx.status do
                        "Completed" ->
                          "px-2 py-1 bg-green-100 text-green-800 text-xs rounded-full"

                        "Pending Review" ->
                          "px-2 py-1 bg-yellow-100 text-yellow-800 text-xs rounded-full"

                        "Blocked" ->
                          "px-2 py-1 bg-red-100 text-red-800 text-xs rounded-full"
                      end
                    }>
                      {tx.status}
                    </span>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      </div>
    </div>
    """
  end

  # --- HANDLERS ---

  # Process Incoming Transaction (US1, US8, US3)
  @impl true
  def handle_event(
        "process_transaction",
        %{"account_id" => acc_id, "amount_zar" => amt_str, "location" => loc},
        socket
      ) do
    amount = String.to_float(amt_str)
    tx_id = "TX-"

    # Rule-based Engine (US8): High amount or unusual location flags as Suspicious
    suspicious? = amount >= 10000.00 or loc == "International/Unusual"

    {status, new_pending, new_completed, new_review_count} =
      if suspicious? do
        review_item = %{
          id: tx_id,
          account_id: acc_id,
          amount_zar: amount,
          reason: if(amount >= 10000.0, do: "High Volume (>= R10,000)", else: "Location Anomaly")
        }

        {"Pending Review", [review_item | socket.assigns.pending_reviews],
         socket.assigns.completed_count, socket.assigns.pending_review_count + 1}
      else
        {"Completed", socket.assigns.pending_reviews, socket.assigns.completed_count + 1,
         socket.assigns.pending_review_count}
      end

    new_tx = %{
      id: tx_id,
      account_id: acc_id,
      amount_zar: amount,
      location: loc,
      status: status
    }

    {:noreply,
     assign(socket,
       total_transactions: socket.assigns.total_transactions + 1,
       completed_count: new_completed,
       pending_review_count: new_review_count,
       pending_reviews: new_pending,
       transactions: [new_tx | socket.assigns.transactions]
     )}
  end

  # Handle Manual Analyst Decision (US4, US5, US2)
  @impl true
  def handle_event("resolve_review", %{"id" => tx_id, "decision" => decision}, socket) do
    # Remove from review queue
    remaining_reviews = Enum.reject(socket.assigns.pending_reviews, fn r -> r.id == tx_id end)

    {final_status, blocked_inc, completed_inc} =
      if decision == "fraud" do
        {"Blocked", 1, 0}
      else
        {"Completed", 0, 1}
      end

    # Update state in transaction list (US5)
    updated_transactions =
      Enum.map(socket.assigns.transactions, fn tx ->
        if tx.id == tx_id, do: %{tx | status: final_status}, else: tx
      end)

    {:noreply,
     assign(socket,
       pending_reviews: remaining_reviews,
       pending_review_count: socket.assigns.pending_review_count - 1,
       blocked_count: socket.assigns.blocked_count + blocked_inc,
       completed_count: socket.assigns.completed_count + completed_inc,
       transactions: updated_transactions
     )}
  end

  defp script_rand, do: :rand.uniform(8999) + 1000
end
