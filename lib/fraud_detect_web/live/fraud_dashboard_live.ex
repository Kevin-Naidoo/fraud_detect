defmodule FraudDetectWeb.FraudDashboardLive do
  use FraudDetectWeb, :live_view

  alias FraudDetect.Repo
  import Ecto.Query

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(FraudDetect.PubSub, "fraud_alerts")
    end

    socket =
      socket
      |> assign(:page_title, "Real-Time Fraud Monitoring Engine")
      |> load_dashboard_data()

    {:ok, socket}
  end

  @impl true
  def handle_info({:new_alert, _alert}, socket) do
    {:noreply, load_dashboard_data(socket)}
  end

  @impl true
  def handle_info({:alert_updated, _id}, socket) do
    {:noreply, load_dashboard_data(socket)}
  end

  @impl true
  def handle_event("update_status", %{"id" => id, "status" => new_status}, socket) do
    alert_id = String.to_integer(id)

    # Update the alert status in PostgreSQL
    Repo.update_all(
      from(a in "fraud_alerts", where: a.id == ^alert_id),
      set: [alert_status: new_status, updated_at: NaiveDateTime.utc_now()]
    )

    # Broadcast update across PubSub so all connected dashboards sync up
    Phoenix.PubSub.broadcast(FraudDetect.PubSub, "fraud_alerts", {:alert_updated, alert_id})

    {:noreply, load_dashboard_data(socket)}
  end

  defp load_dashboard_data(socket) do
    total_alerts = Repo.aggregate("fraud_alerts", :count, :id)
    pending_alerts = Repo.one(from a in "fraud_alerts", where: a.alert_status == "Pending Review", select: count(a.id))

    raw_avg_risk = Repo.one(from a in "fraud_alerts", select: avg(a.risk_score))
    avg_risk =
      cond do
        is_nil(raw_avg_risk) -> 0.0
        match?(%Decimal{}, raw_avg_risk) -> Decimal.to_float(raw_avg_risk)
        is_float(raw_avg_risk) -> raw_avg_risk
        is_integer(raw_avg_risk) -> raw_avg_risk * 1.0
        true -> 0.0
      end

    alerts_query =
      from a in "fraud_alerts",
        join: t in "transactions",
        on: a.transaction_id == t.id,
        order_by: [desc: a.id],
        limit: 10,
        select: %{
          id: a.id,
          transaction_id: t.id,
          amount_zar: t.amount_zar,
          risk_score: a.risk_score,
          alert_status: a.alert_status,
          alert_date: a.alert_date
        }

    recent_alerts = Repo.all(alerts_query)

    assign(socket,
      total_alerts: total_alerts,
      pending_alerts: pending_alerts,
      avg_risk: Float.round(avg_risk, 2),
      recent_alerts: recent_alerts
    )
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-slate-900 text-slate-100 p-8">
      <!-- Header -->
      <div class="flex justify-between items-center mb-8 border-b border-slate-800 pb-5">
        <div>
          <h1 class="text-3xl font-bold tracking-tight text-white">Fraud Risk Operations Center</h1>
          <p class="text-slate-400 text-sm mt-1">Real-time inference streaming via Scholar & Nx ML Engine</p>
        </div>
        <div class="flex items-center space-x-2">
          <span class="relative flex h-3 w-3">
            <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
            <span class="relative inline-flex rounded-full h-3 w-3 bg-emerald-500"></span>
          </span>
          <span class="text-emerald-400 font-mono text-sm">Engine Active</span>
        </div>
      </div>

      <!-- Key Metrics Row -->
      <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        <div class="bg-slate-800/60 border border-slate-700/50 rounded-xl p-6 backdrop-blur">
          <p class="text-slate-400 text-sm font-medium uppercase tracking-wider">Total Alerts Logged</p>
          <p class="text-4xl font-extrabold text-white mt-2 font-mono"><%= @total_alerts %></p>
        </div>
        <div class="bg-slate-800/60 border border-slate-700/50 rounded-xl p-6 backdrop-blur">
          <p class="text-slate-400 text-sm font-medium uppercase tracking-wider">Pending Human Review</p>
          <p class="text-4xl font-extrabold text-amber-400 mt-2 font-mono"><%= @pending_alerts %></p>
        </div>
        <div class="bg-slate-800/60 border border-slate-700/50 rounded-xl p-6 backdrop-blur">
          <p class="text-slate-400 text-sm font-medium uppercase tracking-wider">Avg High-Risk Score</p>
          <p class="text-4xl font-extrabold text-rose-500 mt-2 font-mono"><%= @avg_risk %>%</p>
        </div>
      </div>

      <!-- Real-Time Alerts Stream Table -->
      <div class="bg-slate-800/40 border border-slate-700/60 rounded-xl overflow-hidden shadow-2xl">
        <div class="px-6 py-4 border-b border-slate-700/60 bg-slate-800/80">
          <h2 class="text-lg font-semibold text-white">Streaming Flagged Transactions</h2>
        </div>
        <div class="overflow-x-auto">
          <table class="w-full text-left border-collapse">
            <thead>
              <tr class="bg-slate-900/50 text-slate-400 uppercase text-xs tracking-wider border-b border-slate-700/60">
                <th class="py-4 px-6">Alert ID</th>
                <th class="py-4 px-6">Tx ID</th>
                <th class="py-4 px-6">Amount (ZAR)</th>
                <th class="py-4 px-6">ML Risk Score</th>
                <th class="py-4 px-6">Status</th>
                <th class="py-4 px-6">Timestamp</th>
                <th class="py-4 px-6 text-right">Actions</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-slate-700/40 font-mono text-sm">
              <%= for alert <- @recent_alerts do %>
                <tr class="hover:bg-slate-700/30 transition-colors">
                  <td class="py-4 px-6 font-medium text-slate-300">#<%= alert.id %></td>
                  <td class="py-4 px-6 text-indigo-400">#<%= alert.transaction_id %></td>
                  <td class="py-4 px-6 text-emerald-400">R <%= alert.amount_zar %></td>
                  <td class="py-4 px-6">
                    <span class="px-2.5 py-1 rounded-full text-xs font-semibold bg-rose-500/20 text-rose-400 border border-rose-500/30">
                      <%= alert.risk_score %>% Risk
                    </span>
                  </td>
                  <td class="py-4 px-6">
                    <span class={"px-2.5 py-1 rounded-md text-xs font-medium #{cond do alert.alert_status == "Approved" -> "bg-emerald-500/20 text-emerald-400 border border-emerald-500/30"; alert.alert_status == "Rejected" -> "bg-rose-500/20 text-rose-400 border border-rose-500/30"; true -> "bg-slate-700 text-slate-200" end}"}>
                      <%= alert.alert_status %>
                    </span>
                  </td>
                  <td class="py-4 px-6 text-slate-400 text-xs"><%= alert.alert_date %></td>
                  <td class="py-4 px-6 text-right space-x-2">
                    <button
                      phx-click="update_status"
                      phx-value-id={alert.id}
                      phx-value-status="Approved"
                      class="px-3 py-1 bg-emerald-600/20 hover:bg-emerald-600/40 text-emerald-400 border border-emerald-500/30 rounded text-xs font-semibold transition-colors">
                      Approve
                    </button>
                    <button
                      phx-click="update_status"
                      phx-value-id={alert.id}
                      phx-value-status="Rejected"
                      class="px-3 py-1 bg-rose-600/20 hover:bg-rose-600/40 text-rose-400 border border-rose-500/30 rounded text-xs font-semibold transition-colors">
                      Reject
                    </button>
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
end
