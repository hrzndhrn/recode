defmodule Recode.Task.EnforceLineLength do
  @moduledoc """
  The `EnforceLineLength` task writes multiline expressions into one line if
  they do not exceed the maximum line length.

  ## Options

    * `:skip` - specifies expressions to skip.
    * `:ignore` - specifies expressions to ignore.

  ## Examples

  The following code is not changed by the Elixir Formatter.
  ```Elixir
  fn
    x ->
      {
        :ok,
        x
      }
  end
  ```
  The `EnforceLineLength` task rewrite this to
  ```Elixir
  fn x -> {:ok, x} end
  ```
  and with the option `[ignore: :fn]` to
  ```Elixir
  fn
    x -> {:ok, x}
  end
  ```
  and with the option `skip: :fn` the code keeps unchanged.
  """

  use Recode.Task, correct: true, check: false

  alias Recode.AST
  alias Recode.Task.EnforceLineLength
  alias Rewrite.Source
  alias Sourceror.Zipper

  @impl Recode.Task
  def run(source, opts) do
    opts = validate(opts)

    zipper =
      source
      |> Source.get(:quoted)
      |> Zipper.zip()
      |> Zipper.traverse_while(fn zipper -> same_line(zipper, opts) end)

    Source.update(source, EnforceLineLength, :quoted, Zipper.root(zipper))
  end

  defp same_line({{:with, _meta, _args}, _zipper_meta} = zipper, _opts) do
    {:cont, zipper}
  end

  defp same_line({{name, _meta, args}, _zipper_meta} = zipper, opts) when is_list(args) do
    cond do
      name in opts[:skip] -> {:skip, zipper}
      name in opts[:ignore] -> {:cont, zipper}
      true -> do_same_line(zipper)
    end
  end

  defp same_line(zipper, _opts), do: {:cont, zipper}

  defp do_same_line(zipper) do
    case zipper |> Zipper.node() |> AST.multiline?() do
      true -> {:cont, Zipper.update(zipper, &AST.to_same_line/1)}
      false -> {:cont, zipper}
    end
  end

  defp validate(opts) do
    opts
    |> Keyword.update(:skip, [], fn skip -> List.wrap(skip) end)
    |> Keyword.update(:ignore, [], fn ignore -> List.wrap(ignore) end)
    |> Keyword.validate!([:skip, :ignore, :autocorrect])
  end
end
