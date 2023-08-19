defmodule Recode.Task.Dbg do
  @shortdoc "There should be no calls to dbg."

  @moduledoc """
  Calls to `dbg/2` should only appear in debug sessions.

  This task rewrites the code when `mix recode` runs with `autocorrect: true`.
  """

  use Recode.Task, corrector: true, category: :warning

  alias Recode.Issue
  alias Recode.Task.Dbg
  alias Rewrite.Source
  alias Sourceror.Zipper

  @impl Recode.Task
  def run(source, opts) do
    source
    |> Source.get(:quoted)
    |> Zipper.zip()
    |> Zipper.traverse([], fn zipper, issues ->
      traverse(zipper, issues, opts[:autocorrect])
    end)
    |> update(source, opts[:autocorrect])
  end

  defp update({zipper, _issues}, source, true) do
    Source.update(source, Dbg, :quoted, Zipper.root(zipper))
  end

  defp update({_zipper, []}, source, false), do: source

  defp update({_zipper, issues}, source, false) do
    Source.add_issues(source, issues)
  end

  defp traverse(
         {
           {:|>, _, [arg, {{:., _, [{:__aliases__, _, [:Kernel]}, :dbg]}, _, _}]},
           _zipper_meat
         } =
           zipper,
         issues,
         true
       ) do
    {Zipper.replace(zipper, arg), issues}
  end

  defp traverse(
         {{:|>, _, [arg, {:dbg, _, _}]}, _zipper_meat} = zipper,
         issues,
         true
       ) do
    {Zipper.replace(zipper, arg), issues}
  end

  # {{:., [], [{:__aliases__, [alias: false], [:Kernel]}, :dbg]}, [], [{:x, [], Elixir}]}

  defp traverse(
         {
           {{:., _, [{:__aliases__, _, [:Kernel]}, :dbg]}, meta, _},
           _zipper_meat
         } = zipper,
         issues,
         autocorrect
       ) do
    handle(zipper, issues, meta, autocorrect)
  end

  defp traverse({{:dbg, meta, args}, _zipper_meat} = zipper, issues, autocorrect)
       when is_list(args) do
    handle(zipper, issues, meta, autocorrect)
  end

  defp traverse(
         {{:&, _, [{:/, meta, [{:dbg, _, _}, _]}]}, _zipper_meat} = zipper,
         issues,
         autocorrect
       ) do
    handle_up(zipper, issues, meta, autocorrect)
  end

  defp traverse(zipper, issues, _autocorrect) do
    {zipper, issues}
  end

  defp handle(zipper, issues, _meta, true) do
    {Zipper.remove(zipper), issues}
  end

  defp handle(zipper, issues, meta, false) do
    issue = Issue.new(Dbg, @shortdoc, meta)
    {zipper, [issue | issues]}
  end

  defp handle_up(zipper, issues, meta, true) do
    up = Zipper.up(zipper)
    upup = Zipper.up(up)

    case upup do
      {{:|>, _, [arg, _]}, _meta} -> {Zipper.replace(upup, arg), issues}
      _else -> handle(up, issues, meta, true)
    end
  end

  defp handle_up(zipper, issues, meta, false) do
    handle(zipper, issues, meta, false)
  end
end
