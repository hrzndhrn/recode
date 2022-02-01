defmodule Recode.CredoPlugin do
  import Credo.Plugin

  def init(exec) do
    prepend_task(
      exec,
      Credo.CLI.Command.Suggest.SuggestCommand,
      :filter_issues,
      Recode.CredoPlugin.Execution
    )
  end
end

defmodule Recode.CredoPlugin.Execution do
  use Credo.Execution.Task

  alias Credo.Execution

  def call(exec, _opts) do
    fix_by = Execution.get_plugin_param(exec, Recode.CredoPlugin, :fix_by)

    issues =
      exec
      |> Execution.get_issues()
      |> Enum.reject(fn issue -> fix(issue, fix_by) end)

    Execution.put_issues(exec, issues)
  end

  defp fix(issue, by) do
    case Keyword.fetch(by, issue.check) do
      :error ->
        false

      {:ok, task} ->
        source =
          issue.filename
          |> File.read!()
          |> Sourceror.parse_string!()
          |> task.run()
          |> Sourceror.to_string()
          |> newline()

        File.write!(issue.filename, source)

        true
    end
  end

  defp newline(string), do: string <> "\n"
end
