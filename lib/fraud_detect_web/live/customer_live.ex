defmodule FraudDetectWeb.CustomerLive do
  use FraudDetectWeb, :live_view
  alias FraudDetect.Core
  alias FraudDetect.Core.Customer

  @impl true
  def mount(_params, _session, socket) do
    changeset = Core.change_customer(%Customer{})
    customers = Core.list_customers()

    {:ok, assign(socket, customers: customers, form: to_form(changeset))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <h1>Customer Management</h1>

    <section>
      <h2>Add New Customer</h2>
      <.form for={@form} phx-submit="save">
        <label for="customer_name">Customer Name:</label>
        <.input field={@form[:customer_name]} type="text" />
        <button type="submit">Save Customer</button>
      </.form>
    </section>

    <hr />

    <section>
      <h2>Customer List</h2>
      <table>
        <thead>
          <tr>
            <th>ID</th>
            <th>Name</th>
            <th>Created At</th>
          </tr>
        </thead>
        <tbody>
          <%= for customer <- @customers do %>
            <tr>
              <td>{customer.id}</td>
              <td>{customer.customer_name}</td>
              <td>{customer.inserted_at}</td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </section>
    """
  end

  @impl true
  def handle_event("save", %{"customer" => customer_params}, socket) do
    case Core.create_customer(customer_params) do
      {:ok, _customer} ->
        updated_customers = Core.list_customers()
        new_changeset = Core.change_customer(%Customer{})

        {:noreply,
         socket
         |> put_flash(:info, "Customer created successfully")
         |> assign(customers: updated_customers, form: to_form(new_changeset))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
