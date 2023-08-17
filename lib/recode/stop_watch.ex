defmodule Recode.StopWatch do
  @moduledoc """
  A stopwatch to measure times in milliseconds.

  ## Examples

      iex> alias Recode.StopWatch
      iex> StopWatch.init!(:test)
      iex> StopWatch.start!(:test, :foo)
      iex> t1 = StopWatch.time!(:test, :foo)
      iex> Process.sleep(1)
      iex> t2 = StopWatch.time!(:test, :foo)
      iex> Process.sleep(1)
      iex> StopWatch.stop!(:test, :foo)
      iex> t3 = StopWatch.time!(:test, :foo)
      iex> t1 < t2 and t2 < t3
      true
      iex> t3 == StopWatch.time!(:test, :foo)
      true
  """
  @name :stop_watch

  defmacro __using__(_opts) do
    quote do
      require Recode.StopWatch
      alias Recode.StopWatch
    end
  end

  def init!(name \\ @name) do
    :ets.new(name, [:set, :public, :named_table])
  rescue
    ArgumentError ->
      reraise ArgumentError, [message: "StopWatch #{inspect(name)} already exisits."], __STACKTRACE__
  end

  @doc false
  def _put!(name, key, op, timestamp) do
    with false <- :ets.insert_new(name, {{key, op}, timestamp}) do
      raise ArgumentError,
            "StopWatch has already received the #{inspect(op)} operation for #{inspect(key)}."
    end
  end

  @doc false
  def _time!(name \\ @name, key, timestamp) do
    case :ets.match(name, {{key, :_}, :"$1"}) do
      [[timestamp1], [timestamp2]] -> abs(timestamp1 - timestamp2)
      [[timestamp1]] -> abs(timestamp - timestamp1)
    end
  end

  defmacro start!(name \\ @name, key) do
    quote bind_quoted: [name: name, key: key] do
      Recode.StopWatch._put!(name, key, :start, System.monotonic_time(:millisecond))
    end
  end

  defmacro stop!(name \\ @name, key) do
    quote bind_quoted: [name: name, key: key] do
      Recode.StopWatch._put!(name, key, :stop, System.monotonic_time(:millisecond))
    end
  end

  defmacro time!(name \\ @name, key) do
    quote bind_quoted: [name: name, key: key] do
      Recode.StopWatch._time!(name, key, System.monotonic_time(:millisecond))
    end
  end
end
