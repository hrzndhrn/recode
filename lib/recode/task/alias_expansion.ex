defmodule Recode.Task.AliasExpansion do
  @moduledoc """
  TODO: moduledoc
  """

  use Recode.Task, correct: true

  alias Recode.Project
  alias Recode.Source
  alias Recode.Task.AliasExpansion
  alias Sourceror.Zipper

  def run(project, _opts) do
    Project.map(project, fn source ->
      zipper =
        source
        |> Source.zipper!()
        |> Zipper.traverse(&expand_alias/1)

      source = Source.update(source, AliasExpansion, code: zipper)

      {:ok, source}
    end)
  end

  defp expand_alias({{:alias, _meta, _args}, _zipper_meta} = zipper) do
    with {base, segments, alias_meta, call_meta} <- extract(zipper) do
      segments
      |> segments_to_alias(base)
      |> put_leading_comments(alias_meta)
      |> put_trailing_comments(call_meta)
      |> insert(zipper)
    end
  end

  defp expand_alias(zipper), do: zipper

  defp extract({tree, _meta} = zipper) do
    case tree do
      {:alias, alias_meta, [{{:., _meta, [base, :{}]}, call_meta, segments}]} ->
        {base, segments, alias_meta, call_meta}

      _tree ->
        zipper
    end
  end

  defp insert(aliases, zipper) do
    aliases
    |> Enum.reduce(zipper, fn alias, zip -> Zipper.insert_left(zip, alias) end)
    |> Zipper.remove()
  end

  defp segments_to_alias(segments, {_name, _meta, base_segments}) when is_list(segments) do
    Enum.map(segments, fn {_name, meta, segments} ->
      {:alias, meta, [{:__aliases__, [], base_segments ++ segments}]}
    end)
  end

  defp put_leading_comments([first | rest], meta) do
    comments = meta[:leading_comments] || []
    [Sourceror.prepend_comments(first, comments) | rest]
  end

  defp put_trailing_comments(list, meta) do
    comments = meta[:trailing_comments] || []

    case List.pop_at(list, -1) do
      {nil, list} ->
        list

      {last, list} ->
        last =
          {:__block__,
           [
             trailing_comments: comments,
             end_of_expression: [newlines: 2]
           ], [last]}

        list ++ [last]
    end
  end
end
