defmodule Recode.Traverse do
  @moduledoc """
  TODO: add moduledoc
  """

  alias Recode.AST
  alias Sourceror.Zipper

  @doc ~S'''
  TODO: add doc

  ## Examples

      iex> alias Recode.Traverse
      iex> alias Sourceror.Zipper
      iex> zipper = """
      ...> defmodule Foo do
      ...>   @moduledoc "The Foo"
      ...>
      ...>   def foo do
      ...>     :foo
      ...>   end
      ...> end
      ...> """
      ...> |> Sourceror.parse_string!()
      ...> |> Zipper.zip()
      iex> {:ok, def} = Traverse.to(zipper, :def)
      iex> {name, _meta, _args} = Zipper.node(def)
      iex> name
      :def
      iex> {:ok, attr} = Traverse.to(zipper, {:@, :moduledoc})
      iex> {_name, _meta, args} = Zipper.node(attr)
      iex> args
      [
        {:moduledoc, [trailing_comments: [], leading_comments: [], line: 2, column: 4],
         [
           {:__block__,
            [trailing_comments: [], leading_comments: [], delimiter: "\"", line: 2, column: 14],
            ["The Foo"]}
         ]}
      ]
  '''

  @spec to(Zipper.zipper(), atom() | [atom()]) :: {:ok, Zipper.zipper()} | :error
  def to(zipper, item) when not is_list(item), do: to(zipper, [item])

  def to(zipper, atoms) when is_list(atoms) do
    {_zipper, result} =
      Zipper.traverse_while(zipper, nil, fn
        {{:@, _meta, _args} = ast, _zipper_meta} = zipper, _acc ->
          name = AST.module_attribute_name(ast)

          case {:@, name} in atoms do
            true -> {:halt, zipper, zipper}
            false -> {:cont, zipper, nil}
          end

        {{name, _meta, _args}, _zipper_meta} = zipper, _acc ->
          case name in atoms do
            true -> {:halt, zipper, zipper}
            false -> {:cont, zipper, nil}
          end

        zipper, _acc ->
          {:cont, zipper, nil}
      end)

    case result do
      nil -> :error
      result -> {:ok, result}
    end
  end

  @doc ~s'''
  TODO: add doc

  ## Examples

      iex> alias Recode.Traverse
      iex> alias Sourceror.Zipper
      iex> zipper = """
      ...> defmodule Foo do
      ...>   def foo do
      ...>     :foo
      ...>   end
      ...> end
      ...> """
      ...> |> Sourceror.parse_string!()
      ...> |> Zipper.zip()
      iex> {:ok, zipper} = Traverse.to_defmodule(zipper, Foo)
      iex> {name, _meta, _args} = Zipper.node(zipper)
      iex> name
      :defmodule
  '''
  def to_defmodule(zipper, module) do
    {_zipper, result} =
      Zipper.traverse_while(zipper, nil, fn
        {{:defmodule, _meta, [aliases | _args]}, _zipper_meta} = zipper, _acc ->
          case AST.aliases_concat(aliases) == module do
            true -> {:halt, zipper, zipper}
            false -> {:cont, zipper, nil}
          end

        zipper, _acc ->
          {:cont, zipper, nil}
      end)

    case Zipper.end?(result) do
      true -> :error
      false -> {:ok, result}
    end
  end

  def to_defmodule!(zipper, module) do
    case to_defmodule(zipper, module) do
      {:ok, zipper} -> zipper
      :error -> raise "TODO: raise an usefull error"
    end
  end

  def collect(zipper, name) do
    zipper
    |> Zipper.traverse([], fn
      {{^name, _meta, _args}, _zipper_meta} = zipper, acc -> {zipper, [zipper | acc]}
      zipper, acc -> {zipper, acc}
    end)
    |> elem(1)
  end
end
