defmodule Recode.Application do
  @moduledoc false

  # TODO: needed?

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: MyApp.Worker.start_link(arg)
      # {MyApp.Worker, arg}
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
