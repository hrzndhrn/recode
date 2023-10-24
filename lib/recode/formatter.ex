defmodule Recode.Formatter do
  @moduledoc """
  Helper functions for formatting and the formatting protocols.

  Formatters are `GenServer`s specified during `Recode` configuration that
  receive a series of events as casts.

  The following events are possible:

  * `{:prepared, %Rewrite{} = project, time}` -
    all files have been read.

  * `{:task_started, %Rewrite.Source{} = source, task}` -
    a task has started.

  * `{:task_finished, %Rewrite.Source{} = source, task, time}` .
    a task has finished.

  * `{:tasks_finished, %Rewrite{} = project, time}` -
    all tasks are finished.

  * `{:finished, %Rewrite{} = project, time}` -
    the Recode run has finished.

  The full Recode configuration is passed as the argument to GenServer.init/1
  callback when the formatters are started.

  All `time` variables are integers and representing microseconds.
  """

  @doc """
  Formats the given `microseconds` to a string representing the time in seconds.

  ## Examples

      iex> Recode.Formatter.format_time(1234)
      "0.00"
      iex> Recode.Formatter.format_time(12345)
      "0.01"
      iex> Recode.Formatter.format_time(123456)
      "0.1"
      iex> Recode.Formatter.format_time(1234567)
      "1.2"
      iex> Recode.Formatter.format_time(12345678)
      "12.3"
  """
  @spec format_time(integer) :: String.t()
  def format_time(microseconds), do: format_time(microseconds, :second)

  @doc """
  Formats the given `microseconds` to a string representing the time in the
  given `time_unit`.

  ## Examples

      iex> Recode.Formatter.format_time(1234, :second)
      "0.00"
      iex> Recode.Formatter.format_time(12345, :second)
      "0.01"
      iex> Recode.Formatter.format_time(123456, :second)
      "0.1"
      iex> Recode.Formatter.format_time(1234567, :second)
      "1.2"
      iex> Recode.Formatter.format_time(12345678, :second)
      "12.3"

      iex> Recode.Formatter.format_time(1234, :millisecond)
      "1.234"
      iex> Recode.Formatter.format_time(12345, :millisecond)
      "12.345"
  """
  @spec format_time(integer, time_unit :: :second | :millisecond) :: String.t()
  def format_time(microseconds, :second) do
    time = div(microseconds, 10_000)

    if time < 10 do
      "0.0#{time}"
    else
      time = div(time, 10)
      "#{div(time, 10)}.#{rem(time, 10)}"
    end
  end

  def format_time(microseconds, :millisecond) do
    "#{div(microseconds, 1_000)}.#{rem(microseconds, 1_000)}"
  end
end
