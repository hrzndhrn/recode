defmodule Recode.Task.TestFile do
  @shortdoc "Checks test files for correct name and extension."

  @moduledoc """
  Tests must be in a file with the extension `*_test.exs`.

  This task checks and/or corrects two things:

    * files ending with `*_test.ex`.

    * filtes in `test` folders, missing `*_test.exs` and containing a module 
      `*Test`.

  """

  use Recode.Task, corrector: true, category: :warning

  alias Rewrite.Source

  @impl Recode.Task
  def run(source, opts) do
    source
    |> test_file_ext(opts)
    |> test_file_name(opts)
  end

  defp test_file_ext(%Source{path: path} = source, opts) do
    case String.replace(path, ~r/_test\.ex$/, "_test.exs") do
      ^path -> source
      updated_path -> update(source, updated_path, opts)
    end
  end

  defp test_file_name(%Source{path: path} = source, opts) do
    in_test = path |> Path.split() |> Enum.member?("test")
    correct_file_name = Regex.match?(~r/_test.exs$/, path)

    if in_test and not correct_file_name do
      case test_module_filenames(source) do
        [] ->
          source

        [name] ->
          path = path |> Path.dirname() |> Path.join(name)
          update(source, path, opts)

        filenames ->
          issue =
            new_issue("""
            The file does not end with _test.exs and can not be found by ExUnit.\
              Maybe one of the following filenames can be used:\
              #{inspect(filenames)}
            """)

          Source.add_issue(source, issue)
      end
    else
      source
    end
  end

  defp test_module_filenames(source) do
    source
    |> Source.Ex.modules()
    |> Enum.reduce([], fn module, acc ->
      basename = module |> Macro.underscore() |> Path.basename()

      if String.ends_with?(basename, "_test") do
        [basename <> ".exs" | acc]
      else
        acc
      end
    end)
  end

  defp update(source, path, opts) do
    issue = new_issue("The file must be renamed to #{path} so that ExUnit can find it.")
    update_source(source, opts, path: path, issue: issue)
  end
end
