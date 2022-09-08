defmodule Recode.Task.UnusedVariable do
  @moduledoc """
  Prepend unused variables with `_`
  """

  use Recode.Task, correct: true, check: true

  alias Recode.Issue
  alias Rewrite.Source
  alias Sourceror.Zipper

  @impl Recode.Task
  def run(source, opts) do
    {zipper, issues} =
      source
      |> Source.ast()
      |> Zipper.zip()
      |> Zipper.traverse([], fn zipper, issues ->
        prepend_unused_variable_with_underscore(zipper, issues)
      end)

    case opts[:autocorrect] do
      true ->
        Source.update(source, __MODULE__, ast: Zipper.root(zipper))

      false ->
        Source.add_issues(source, issues)
    end
  end

  defp prepend_unused_variable_with_underscore(
         {{:=, _meta, [{var_name, var_meta, _var_value} = var, _other]}, _zipper_meta} = zipper,
         issues
       ) do
    if unused?(zipper, var) do
      zipper = add_underscore(zipper, var)

      issue = Issue.new(__MODULE__, "Unused variable: #{var_name}", var_meta)

      {zipper, [issue | issues]}
    else
      {zipper, issues}
    end
  end

  defp prepend_unused_variable_with_underscore(
         {_ast, _zipper_meta} = zipper,
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
