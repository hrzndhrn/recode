defmodule Recode.Task.Specs do
  @moduledoc """
  Function and macros should have specs.

  ## Options

    * `:only` - `:public`, `:visible`
  """

  use Recode.Task, check: true

  alias Recode.Context
  alias Recode.Issue
  alias Recode.Source
  alias Recode.Task.Specs

  def run(source, opts) do
    include = Keyword.get(opts, :only, :all)
    issues = check_specs(source, include)

    Source.add_issues(source, issues)
  end

  defp check_specs(source, include) do
    source
    |> Source.zipper!()
    |> Context.traverse({[], nil}, fn zipper, context, acc ->
      check_specs(zipper, context, acc, include)
    end)
    |> result()
  end

  defp check_specs(zipper, context, {issues, last_def}, include) do
    case context.definition != last_def do
      true ->
        issues = check_spec(include, context, issues)
        {zipper, context, {issues, context.definition}}

      false ->
        {zipper, context, {issues, last_def}}
    end
  end

  defp check_spec(_only, %Context{definition: nil}, issues), do: issues

  defp check_spec(:all, context, issues) do
    case Context.spec?(context) do
      true -> issues
      false -> [issue(context) | issues]
    end
  end

  defp check_spec(only, context, issues) do
    case Context.definition?(context, only) and not Context.spec?(context) do
      true -> [issue(context) | issues]
      false -> issues
    end
  end

  defp issue(%Context{definition: {_definition, meta}}) do
    message = "Functions should have a @spec type specification."
    Issue.new(Specs, message, meta)
  end

  defp result({_zipper, {issues, _seen}}), do: issues
end
