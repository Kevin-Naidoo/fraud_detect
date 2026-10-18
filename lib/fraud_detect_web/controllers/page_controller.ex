defmodule FraudDetectWeb.PageController do
  use FraudDetectWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
