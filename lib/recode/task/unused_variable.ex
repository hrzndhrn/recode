defmodule Recode.Task.UnusedVariable do
  @shortdoc "Checks if unused variables occur."

  @moduledoc """
  Prepend unused variables with `_`.
  """

  use Recode.Task, corrector: true, category: :warning

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

    update_source(source, opts, quoted: zipper, issues: issues)
  end

  defp process_unused({var_name, var_meta, nil} = var, search_zipper, zipper, issues) do
    if unused?(search_zipper, var) do
      zipper = add_underscore(zipper, var)

      issue = new_issue("Unused variable: #{var_name}", var_meta)

      {zipper, [issue | issues]}
    else
      {zipper, issues}
    end
  end

  defp process_unused(_var, _search_zipper, zipper, issues) do
    {zipper, issues}
  end

  defp prepend_unused_variable_with_underscore(
         %Zipper{node: {:=, _meta, [var, _other]}} = zipper,
         issues
       ) do
    process_unused(var, Zipper.top(zipper), zipper, issues)
  end

  defp prepend_unused_variable_with_underscore(
         %Zipper{node: {:def, _meta, [{_fun_name, _fun_meta, nil}, _content]}} = zipper,
         issues
       ) do
    {zipper, issues}
  end

  defp prepend_unused_variable_with_underscore(
         %Zipper{node: {:def, _meta, [{_fun_name, _fun_meta, params}, _content]}} = zipper,
         issues
       ) do
    {fzipper, fissues} =
      Enum.reduce(params, {zipper, issues}, fn var, {z, i} ->
        process_unused(var, zipper, z, i)
      end)

    {fzipper, fissues}
  end

  defp prepend_unused_variable_with_underscore(
         %Zipper{node: {:defp, _meta, [{_fun_name, _fun_meta, nil}, _content]}} = zipper,
         issues
       ) do
    {zipper, issues}
  end

  defp prepend_unused_variable_with_underscore(
         %Zipper{node: {:defp, _meta, [{_fun_name, _fun_meta, params}, _content]}} = zipper,
         issues
       ) do
    {fzipper, fissues} =
      Enum.reduce(params, {zipper, issues}, fn var, {z, i} ->
        process_unused(var, zipper, z, i)
      end)

    {fzipper, fissues}
  end

  defp prepend_unused_variable_with_underscore(zipper, issues), do: {zipper, issues}

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
          %Zipper{node: {^name, ref_metadata, _value} = ref} = zipper, references
          when metadata != ref_metadata ->
            {zipper, [ref | references]}

          zipper, references ->
            {zipper, references}
        end)

      references == []
    end
  end
end
