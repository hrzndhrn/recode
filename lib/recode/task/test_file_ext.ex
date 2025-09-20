defmodule Recode.Task.TestFileExt do
  @shortdoc "Checks the file extension of test files."

  @moduledoc """
  Tests must be in a file with the extension `*_test.exs`.

  This module searches for `*_test.ex` to rename the file and/or report an
  issue.
  """

  use Recode.Task, corrector: true, category: :warning

  alias Recode.Issue
  alias Rewrite.Source

  @impl Recode.Task
  def run(source, opts) do
    test_file_ext(source, opts[:autocorrect])
  end

  defp test_file_ext(%Source{path: path} = source, autocrecct) do
    case update_path(path) do
      ^path -> source
      updated_path -> update_source(source, updated_path, autocrecct)
    end
  end

  defp update_path(path) when is_binary(path) do
    String.replace(path, ~r/_test\.ex$/, "_test.exs")
  end

  defp update_source(source, path, true) do
    Source.update(source, :path, path, by: __MODULE__)
  end

  defp update_source(source, path, false) do
    message = "The file must be renamed to #{path} so that ExUnit can find it."
    Source.add_issue(source, Issue.new(__MODULE__, message))
  end
end
