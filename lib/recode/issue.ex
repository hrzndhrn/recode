defmodule Recode.Issue do
  @moduledoc """
  An `Issue` struct to track findings by the chechers.
  """

  alias Recode.Issue

  defstruct [:reporter, :message, :line, :column, :meta]

  @type t :: %Issue{
          reporter: module(),
          message: String.t() | nil,
          line: non_neg_integer() | nil,
          column: non_neg_integer() | nil,
          meta: term()
        }

  @doc """
  Creates a new `%Issue{}`

  ## Examples

      iex> Recode.Issue.new(Test, "kaput", line: 1, column: 1)
      %Recode.Issue{reporter: Test, message: "kaput", line: 1, column: 1, meta: nil}

      iex> Recode.Issue.new(Test, foo: "bar")
      %Recode.Issue{reporter: Test, message: nil, line: nil, column: nil, meta: [foo: "bar"]}
  """
  @spec new(module(), String.t() | term() | nil, keyword(), term()) :: Issue.t()
  def new(reporter, message, info \\ [], meta \\ nil)

  def new(reporter, message, info, meta) when is_binary(message) do
    line = Keyword.get(info, :line)
    column = Keyword.get(info, :column)
    struct!(Issue, reporter: reporter, message: message, line: line, column: column, meta: meta)
  end

  def new(reporter, meta, info, nil) do
    line = Keyword.get(info, :line)
    column = Keyword.get(info, :column)
    message = Keyword.get(meta, :message)

    struct!(Issue, reporter: reporter, line: line, column: column, meta: meta, message: message)
  end
end
