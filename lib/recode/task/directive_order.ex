defmodule Recode.Task.DirectiveOrder do
  @shortdoc "Checks if directives (use/import/alias/require) are sorted ."

  @moduledoc """
  Alphabetically sorted lists are easier to read.

      # preferred

      alias Alpha
      alias Bravo
      alias Delta.{Echo, Foxtrot}

      # not preferred

      alias Delta.{Foxtrot, Echo}
      alias Alpha
      alias Bravo
  """

  use Recode.Task, corrector: true, category: :readability

  alias Recode.AST
  alias Recode.Task.AliasOrder
  alias Rewrite.Source
  alias Sourceror.Zipper

  @nodes [:use, :import, :alias, :require]

  @impl Recode.Task
  def run(source, opts) do
    source
    |> Source.get(:quoted)
    |> Zipper.zip()
    |> do_run(source, opts[:autocorrect])
  end

  defp do_run(_zipper, _source, false) do
    throw("Not implemented yet")
  end

  defp do_run(zipper, source, true) do
    new_zipper =
      zipper
      |> Zipper.traverse_while([[]], &alias_order/2)
      |> update()

    Source.update(source, AliasOrder, :quoted, Zipper.root(new_zipper))
  end

  defp alias_order(%Zipper{node: {node, _meta, _args} = ast} = zipper, [group | groups])
       when node in @nodes do
    last_node = if group == [], do: node, else: elem(hd(group), 0)

    if last_node == node do
      {:skip, zipper, [[ast | group] | groups]}
    else
      {:skip, zipper, [[ast], group | groups]}
    end
  end

  defp alias_order(zipper, acc) do
    {:cont, zipper, acc}
  end

  defp update({zipper, []}), do: zipper

  defp update({zipper, acc}) do
    groups = Enum.map(acc, &Enum.reverse/1) |> Enum.reverse()

    [[first | _] | _] = groups
    sorted = sorted(groups)

    rewound = Zipper.find(zipper, :next, fn item -> item == first end)

    Enum.reduce(sorted, rewound, fn group, zipper ->
      group
      |> Enum.reduce(zipper, fn ast, z ->
        Zipper.update(z, fn _ast -> AST.put_newlines(ast, 1) end) |> skip()
      end)
      |> prev()
      |> Zipper.update(fn ast -> AST.put_newlines(ast, 2) end)
      |> skip()
    end)
  end

  defp sorted(groups) do
    Enum.sort(groups, fn
      [ast1 | _], [ast2 | _] ->
        Enum.find_index(@nodes, fn node -> node == elem(ast1, 0) end) <=
          Enum.find_index(@nodes, fn node -> node == elem(ast2, 0) end)
    end)
  end

  defp skip(zipper), do: Zipper.right(zipper) || Zipper.next(zipper)
  defp prev(zipper), do: Zipper.left(zipper) || Zipper.prev(zipper)
end
