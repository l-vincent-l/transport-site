defmodule DB.Application do
  @moduledoc false

  use Application
  alias DB.Repo

  def start(_type, _args) do
    children = [
      Repo
    ]

    opts = [strategy: :one_for_one, name: DB.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
