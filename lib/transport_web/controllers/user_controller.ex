defmodule TransportWeb.UserController do
  use TransportWeb, :controller
  alias Transport.{Worker, Datagouvfr.Client}
  alias TransportWeb.ErrorView
  plug :authentication_required

  def organizations(%Plug.Conn{} = conn, _) do
    conn
    |> Client.me
    |> case do
     {:ok, response} ->
       conn
       |> assign(:organizations, response["organizations"])
       |> render("organizations.html")
     {:error, _} ->
       conn
       |> put_status(:internal_server_error)
       |> render(ErrorView, "500.html")
    end
  end

  def organization_datasets(conn, %{"slug" => slug}) do
    slug
    |> Client.organizations(:with_datasets)
    |> case do
      {:ok, response} ->
        conn
        |> assign(:has_datasets, Enum.empty?(response["datasets"]) == false)
        |> assign(:datasets, response["datasets"])
        |> assign(:organization, response)
        |> render("organization_datasets.html")
     {:error, _} ->
       conn
       |> put_status(:internal_server_error)
       |> render(ErrorView, "500.html")
     end
  end

  def add_badge_dataset(conn, %{"slug" => slug}) do
    slug
    |> Client.put_datasets({:add_tag, "GTFS"}, conn)
    |> case do
      {:ok, dataset} ->
        Worker.validate_data(dataset["uri"])
        conn
        |> render("add_badge_dataset.html")
      {:error, _} ->
        conn
        |> put_status(:internal_server_error)
        |> render(ErrorView, "500.html")
     end
  end

  defp authentication_required(conn, _) do
    case conn.assigns[:current_user]  do
      nil ->
        conn
        |> put_flash(:info, dgettext("alert", "You need to be connected before doing this."))
        |> redirect(to: page_path(conn, :login))
        |> halt()
      _ ->
        conn
    end
  end
end
