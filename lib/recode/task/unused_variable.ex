defmodule Recode.Task.UnusedVariable do
  @moduledoc """
  Prepend unused variables with `_`.
  """

  @shortdoc "Checks if unused variables occur."

  @category :warning

  use Recode.Task, correct: true, check: true

  alias Recode.Issue
  alias Rewrite.Source
  alias Sourceror.Zipper

  @impl Recode.Task
  def run(source, opts) do
    {zipper, issues} =
      source
      |> Source.get(:quoted)
      |> Zipper.zip()
      |> Zipper.traverse([], fn zipper, issues ->
        prepend_unused_variable_with_underscore(zipper, issues)
      end)

    case opts[:autocorrect] do
      true ->
        Source.update(source, __MODULE__, :quoted, Zipper.root(zipper))

      false ->
        Source.add_issues(source, issues)
    end
  end

  defp process_unused({var_name, var_meta, nil} = var, search_zipper, zipper, issues) do
    if unused?(search_zipper, var) do
      zipper = add_underscore(zipper, var)

      issue = Issue.new(__MODULE__, "Unused variable: #{var_name}", var_meta)

      {zipper, [issue | issues]}
    else
      {zipper, issues}
    end
  end

  defp process_unused(_var, _search_zipper, zipper, issues) do
    {zipper, issues}
  end

  defp prepend_unused_variable_with_underscore(
         {{:=, _meta, [var, _other]}, _zipper_meta} = zipper,
         issues
       ) do
    process_unused(var, Zipper.top(zipper), zipper, issues)
  end

  defp prepend_unused_variable_with_underscore(
         {{:def, _meta, [{_fun_name, _fun_meta, nil}, _content]}, _zipper_meta} = zipper,
         issues
       ) do
    {zipper, issues}
  end

  defp prepend_unused_variable_with_underscore(
         {{:def, _meta, [{_fun_name, _fun_meta, params}, _content]}, _zipper_meta} = zipper,
         issues
       ) do
    {fzipper, fissues} =
      Enum.reduce(params, {zipper, issues}, fn var, {z, i} ->
        process_unused(var, zipper, z, i)
      end)

    {fzipper, fissues}
  end

  defp prepend_unused_variable_with_underscore(
         {{:defp, _meta, [{_fun_name, _fun_meta, nil}, _content]}, _zipper_meta} = zipper,
         issues
       ) do
    {zipper, issues}
  end

  defp prepend_unused_variable_with_underscore(
         {{:defp, _meta, [{_fun_name, _fun_meta, params}, _content]}, _zipper_meta} = zipper,
         issues
       ) do
    {fzipper, fissues} =
      Enum.reduce(params, {zipper, issues}, fn var, {z, i} ->
        process_unused(var, zipper, z, i)
      end)

    {fzipper, fissues}
  end

  defp prepend_unused_variable_with_underscore(
         zipper,
         issues
       ) do
    {zipper, issues}
  end

  defp add_underscore(zipper, var) do
    zipper
    |> Zipper.find(fn node -> node == var end)
    |> Zipper.update(fn
      {name, meta, value} ->
        {:"_#{name}", meta, value}

      other ->
        other
    end)
  end

  defp unused?(zipper, {name, metadata, _value}) do
    if String.starts_with?(Atom.to_string(name), "_") do
      false
    else
      {_zipper, references} =
        Zipper.traverse(zipper, [], fn
          {{^name, ref_metadata, _value} = ref, _zipper_meta} = zipper, references
          when metadata != ref_metadata ->
            {zipper, [ref | references]}

          zipper, references ->
            {zipper, references}
        end)

      references == []
    end
  end
end
