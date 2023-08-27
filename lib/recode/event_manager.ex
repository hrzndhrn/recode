defmodule Recode.EventManager do
  @moduledoc false

  def start_link do
    DynamicSupervisor.start_link(strategy: :one_for_one)
  end

  def stop(event_manager) do
    for {_, pid, _, _} <- DynamicSupervisor.which_children(event_manager) do
      GenServer.stop(pid, :normal, :infinity)
    end

    DynamicSupervisor.stop(event_manager)
  end

  def add_handler(event_manager, handler, opts) do
    DynamicSupervisor.start_child(event_manager, %{
      id: GenServer,
      start: {GenServer, :start_link, [handler, opts]},
      restart: :temporary
    })
  end

  def notify(event_manager, message) do
    for {_, pid, _, _} <- Supervisor.which_children(event_manager) do
      GenServer.cast(pid, message)
    end

    :ok
  end
end
