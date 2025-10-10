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
  Creates a new `%Issue{}`.

  ## Parameters
    * `reporter` - atom(), the module reporting the issue
    * `message` - String.t(), the issue description
    * `info` - Keyword.t(), optional parameters including:
      * `:line` - non_neg_integer(), the line number
      * `:column` - non_neg_integer(), the column number
      * `:meta` - term(), additional metadata

  ## Examples

      iex> Recode.Issue.new(Test, "kaput", line: 1, column: 1)
      %Recode.Issue{reporter: Test, message: "kaput", line: 1, column: 1, meta: nil}

      iex> Recode.Issue.new(Test, meta: [foo: "bar"])
      %Recode.Issue{reporter: Test, message: nil, line: nil, column: nil, meta: [foo: "bar"]}

      iex> Recode.Issue.new(Test, "kaput")
      %Recode.Issue{reporter: Test, message: "kaput", line: nil, column: nil, meta: nil}

      iex> Recode.Issue.new(message: "kaput")
      %Recode.Issue{reporter: Recode, message: "kaput", line: nil, column: nil, meta: nil}
  """
  @spec new(atom(), String.t(), Keyword.t()) :: t()
  def new(reporter, message, info)
      when is_atom(reporter) and is_binary(message) and is_list(info) do
    info
    |> Keyword.merge(reporter: reporter, message: message)
    |> new()
  end

  @doc """
  Creates a new `%Issue{}`. See `new/3` for examples.
  """
  @spec new(atom(), String.t() | Keyword.t()) :: t()
  def new(reporter, info) when is_atom(reporter) and is_binary(info) do
    new(reporter: reporter, message: info)
  end

  def new(reporter, info) when is_atom(reporter) and is_list(info) do
    info
    |> Keyword.put(:reporter, reporter)
    |> new()
  end

  @doc """
  Creates a new `%Issue{}`. See `new/3` for examples.
  """
  @spec new(Keyword.t()) :: t()
  def new(info) when is_list(info) do
    struct(Issue, Keyword.put_new(info, :reporter, Recode))
  end
end
