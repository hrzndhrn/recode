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

      iex> Recode.Issue.new(Test, meta: [foo: "bar"])
      %Recode.Issue{reporter: Test, message: nil, line: nil, column: nil, meta: [foo: "bar"]}
  """
  def new(reporter, message, info) do
    info
    |> Keyword.merge(reporter: reporter, message: message)
    |> new()
  end

  def new(reporter, info) do
    info
    |> Keyword.put(:reporter, reporter)
    |> new()
  end

  def new(info) do
    struct(Issue, Keyword.put_new(info, :reporter, Recode))
  end
end
