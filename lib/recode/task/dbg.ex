defmodule Recode.Task.Dbg do
  @shortdoc "There should be no calls to dbg."

  @moduledoc """
  Calls to `dbg/2` should only appear in debug sessions.

  This task rewrites the code when `mix recode` runs with `autocorrect: true`.
  """

  use Recode.Task, corrector: true, category: :warning

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
    |> update(source, opts)
  end

  defp update({zipper, issues}, source, opts) do
    update_source(source, opts, issues: issues, quoted: zipper)
  end

  defp traverse(
         %Zipper{
           node: {:|>, _, [arg, {{:., _, [{:__aliases__, _, [:Kernel]}, :dbg]}, _, _}]}
         } =
           zipper,
         issues,
         true
       ) do
    {Zipper.replace(zipper, arg), issues}
  end

  defp traverse(
         %Zipper{node: {:|>, _, [arg, {:dbg, _, _}]}} = zipper,
         issues,
         true
       ) do
    {Zipper.replace(zipper, arg), issues}
  end

  defp traverse(
         %Zipper{
           node: {{:., _, [{:__aliases__, meta, [:Kernel]}, :dbg]}, _, _}
         } = zipper,
         issues,
         autocorrect
       ) do
    handle(zipper, issues, meta, autocorrect)
  end

  defp traverse(%Zipper{node: {:dbg, meta, args}} = zipper, issues, autocorrect)
       when is_list(args) do
    handle(zipper, issues, meta, autocorrect)
  end

  defp traverse(
         %Zipper{node: {:&, meta, [{:/, _, [{:dbg, _, _}, _]}]}} = zipper,
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
    issue = new_issue(@shortdoc, meta)

    {zipper, [issue | issues]}
  end

  defp handle_up(zipper, issues, meta, true) do
    up = Zipper.up(zipper)
    upup = Zipper.up(up)

    case upup do
      %Zipper{node: {:|>, _, [arg, _]}} -> {Zipper.replace(upup, arg), issues}
      _else -> handle(up, issues, meta, true)
    end
  end

  defp handle_up(zipper, issues, meta, false) do
    handle(zipper, issues, meta, false)
  end
end
