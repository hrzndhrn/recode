defmodule Recode.StopWatch do
  @moduledoc false

  @name :__stop_watch__

  defmacro __using__(_opts) do
    quote do
      require Recode.StopWatch
      alias Recode.StopWatch
    end
  end

  def init(opts \\ []) do
    name = Keyword.get(opts, :name, @name)
    ets = :ets.new(Keyword.get(opts, :name, @name), [:set, :public, :named_table])

    if Keyword.has_key?(opts, :start) do
      _put(name, opts[:start], :start, System.monotonic_time())
    end

    ets
  rescue
    ArgumentError ->
      reraise ArgumentError, [message: "StopWatch already exisits."], __STACKTRACE__
  end

  def _put(name, key, op, timestamp) do
    with false <- :ets.insert_new(name, {{key, op}, timestamp}) do
      raise ArgumentError,
            "StopWatch has already received the #{inspect(op)} operation for #{inspect(key)}."
    end
  end

  def _time(name \\ @name, key, timestamp) do
    case :ets.match(name, {{key, :_}, :"$1"}) do
      [[timestamp1], [timestamp2]] -> abs(timestamp1 - timestamp2) |> convert()
      [[timestamp1]] -> convert(timestamp - timestamp1)
    end
  end

  defp convert(time), do: System.convert_time_unit(time, :native, :microsecond)

  defmacro start(name \\ @name, key) do
    quote bind_quoted: [name: name, key: key] do
      Recode.StopWatch._put(name, key, :start, System.monotonic_time())
    end
  end

  defmacro stop(name \\ @name, key) do
    quote bind_quoted: [name: name, key: key] do
      Recode.StopWatch._put(name, key, :stop, System.monotonic_time())
    end
  end

  defmacro time(name \\ @name, key) do
    quote bind_quoted: [name: name, key: key] do
      Recode.StopWatch._time(name, key, System.monotonic_time())
    end
  end
end
