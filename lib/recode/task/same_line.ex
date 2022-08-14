defmodule Recode.Task.SameLine do
  @moduledoc """
  TODO: Add doc
  """

  use Recode.Task, correct: true, check: false

  alias Recode.AST
  alias Recode.Source
  alias Sourceror.Zipper

  @impl Recode.Task
  def run(source, opts) do
    opts = validate(opts)

    zipper =
      source
      |> Source.zipper()
      |> Zipper.traverse(fn zipper -> same_line(zipper, opts) end)

    Source.update(source, SameLine, code: zipper)
  end

  defp same_line({{:with, _meta, _args}, _zipper_meta} = zipper, _opts) do
    zipper
  end

  defp same_line({{name, _meta, args}, _zipper_meta} = zipper, opts) when is_list(args) do
    cond do
      name in opts[:skip] -> Zipper.skip(zipper)
      name in opts[:ignore] -> zipper
      true -> do_same_line(zipper)
    end
  end

  defp same_line(zipper, _opts), do: zipper

  defp do_same_line(zipper) do
    case zipper |> Zipper.node() |> AST.multiline?() do
      true -> Zipper.update(zipper, &AST.to_same_line/1)
      false -> zipper
    end
  end

  defp validate(opts) do
    opts
    |> Keyword.update(:skip, [], fn skip -> List.wrap(skip) end)
    |> Keyword.update(:ignore, [], fn ignore -> List.wrap(ignore) end)
    |> Keyword.validate!([:skip, :ignore, :autocorrect])
  end
end
