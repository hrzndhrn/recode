defmodule Recode.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [{Task.Supervisor, name: Recode.TaskSupervisor, max_restarts: 10}]

    opts = [strategy: :one_for_one, name: Recode.Supervisor]

    Supervisor.start_link(children, opts)
  end
end
