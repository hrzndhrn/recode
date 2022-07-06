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

  @spec new(module(), String.t() | nil, keyword(), term()) :: Issue.t()
  def new(reporter, message, info \\ [], meta \\ nil) do
    line = Keyword.get(info, :line)
    column = Keyword.get(info, :column)
    struct!(Issue, reporter: reporter, message: message, line: line, column: column, meta: meta)
  end
end
