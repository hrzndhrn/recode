defmodule Recode.ContextTest do
  use ExUnit.Case

  import ExUnit.CaptureIO

  alias Recode.Context
  alias Sourceror.Zipper

  describe "traverse/3" do
    test "traverses a simple module" do
      src = File.read!("test/fixtures/context/simple.ex")

      {result, acc} =
        src
        |> Sourceror.parse_string!()
        |> Zipper.zip()
        |> Context.traverse([], fn zipper, context, acc ->
          {zipper, context, [context | acc]}
        end)

      assert result |> Zipper.node() |> Sourceror.to_string() == String.trim(src)

      acc = Enum.reverse(acc)

      assert Enum.at(acc, 0) == %Context{
               aliases: [],
               assigns: %{},
               definition: nil,
               imports: [],
               module:
                 {Traverse.Simple,
                  [
                    trailing_comments: [],
                    leading_comments: [],
                    do: [line: 1, column: 27],
                    end: [line: 7, column: 1],
                    line: 1,
                    column: 1
                  ]},
               requirements: [],
               usages: []
             }

      assert %{
               definition:
                 {{:def, :foo, 1},
                  [
                    trailing_comments: [],
                    leading_comments: [],
                    end_of_expression: [newlines: 2, line: 4, column: 6],
                    do: [line: 2, column: 14],
                    end: [line: 4, column: 3],
                    line: 2,
                    column: 3
                  ]}
             } = Enum.at(acc, 18)

      assert %{
               definition:
                 {{:def, :baz, 0},
                  [
                    trailing_comments: [],
                    leading_comments: [],
                    line: 6,
                    column: 3
                  ]}
             } = Enum.at(acc, 25)
    end

    test "collects use, import, etc..." do
      src = File.read!("test/fixtures/context/use_import_etc.ex")

      {_result, acc} =
        src
        |> Sourceror.parse_string!()
        |> Zipper.zip()
        |> Context.traverse([], fn zipper, context, acc ->
          {zipper, context, [context | acc]}
        end)

      assert hd(acc) == %Context{
               aliases: [
                 {Traverse.Nested.Simple,
                  [
                    trailing_comments: [],
                    leading_comments: [],
                    end_of_expression: [newlines: 1, line: 4, column: 31],
                    line: 4,
                    column: 3
                  ], nil},
                 {Donald.Duck,
                  [
                    trailing_comments: [],
                    leading_comments: [],
                    end_of_expression: [newlines: 1, line: 5, column: 31],
                    line: 5,
                    column: 3
                  ], [as: Goofy]},
                 {Foo.Bar,
                  [
                    trailing_comments: [],
                    leading_comments: [],
                    end_of_expression: [newlines: 2, line: 6, column: 23],
                    line: 6,
                    column: 3
                  ], nil},
                 {Foo.Baz,
                  [
                    trailing_comments: [],
                    leading_comments: [],
                    end_of_expression: [newlines: 2, line: 6, column: 23],
                    line: 6,
                    column: 3
                  ], nil}
               ],
               assigns: %{},
               definition:
                 {{:def, :foo, 0},
                  [trailing_comments: [], leading_comments: [], line: 13, column: 3]},
               imports: [
                 {Traverse.Pluto,
                  [
                    trailing_comments: [],
                    leading_comments: [],
                    end_of_expression: [newlines: 1, line: 8, column: 24],
                    line: 8,
                    column: 3
                  ], nil},
                 {Traverse.Mouse,
                  [
                    trailing_comments: [],
                    leading_comments: [],
                    end_of_expression: [newlines: 2, line: 9, column: 42],
                    line: 9,
                    column: 3
                  ], [only: [micky: 1]]}
               ],
               module:
                 {Traverse.Foo,
                  [
                    trailing_comments: [],
                    leading_comments: [],
                    do: [line: 1, column: 24],
                    end: [line: 14, column: 1],
                    line: 1,
                    column: 1
                  ]},
               requirements: [
                 {Logger,
                  [
                    trailing_comments: [],
                    leading_comments: [],
                    end_of_expression: [newlines: 2, line: 11, column: 17],
                    line: 11,
                    column: 3
                  ], nil}
               ],
               usages: [
                 {Traverse.Obelix,
                  [
                    trailing_comments: [],
                    leading_comments: [],
                    end_of_expression: [newlines: 2, line: 2, column: 37],
                    line: 2,
                    column: 3
                  ], [app: Traverse]}
               ]
             }
    end

    test "collects definitions with when" do
      src = File.read!("test/fixtures/context/when.ex")

      {result, acc} =
        src
        |> Sourceror.parse_string!()
        |> Zipper.zip()
        |> Context.traverse([], fn zipper, context, acc ->
          {zipper, context, [context | acc]}
        end)

      assert result |> Zipper.node() |> Sourceror.to_string() == String.trim(src)

      acc = Enum.reverse(acc)

      assert acc |> Enum.at(9) |> Map.get(:definition) ==
               {{:def, :foo, 1},
                [
                  trailing_comments: [],
                  leading_comments: [],
                  end_of_expression: [newlines: 2, line: 4, column: 6],
                  do: [line: 2, column: 26],
                  end: [line: 4, column: 3],
                  line: 2,
                  column: 3
                ]}

      assert acc |> Enum.at(37) |> Map.get(:definition) ==
               {{:def, :baz, 1},
                [
                  trailing_comments: [],
                  leading_comments: [],
                  line: 6,
                  column: 3
                ]}
    end
  end

  describe "traverse/2" do
    test "traverses a simple module" do
      src = File.read!("test/fixtures/context/simple.ex")

      {result, output} =
        assert with_io(:stdio, fn ->
                 src
                 |> Sourceror.parse_string!()
                 |> Zipper.zip()
                 |> Context.traverse(fn zipper, context ->
                   context =
                     context
                     |> inc()
                     |> write()

                   {zipper, context}
                 end)
               end)

      assert result |> Zipper.node() |> Sourceror.to_string() == String.trim(src)

      assert output =~ ~r/^1:.module:.{Traverse.Simple,.*line:.1,/m
      assert output =~ ~r/^9:.definition:.nil/m
      assert output =~ ~r/^10:.definition:.{{:def,.:foo,.1},.*line:.2/m
      assert output =~ ~r/^21:.definition:.{{:def,.:baz,.0},.*line:.6/m
    end

    test "traverse a nested module" do
      src = File.read!("test/fixtures/context/nested.ex")

      {result, output} =
        assert with_io(fn ->
                 src
                 |> Sourceror.parse_string!()
                 |> Zipper.zip()
                 |> Context.traverse(fn zipper, context ->
                   context =
                     context
                     |> inc()
                     |> write()

                   {zipper, context}
                 end)
               end)

      assert result |> Zipper.node() |> Sourceror.to_string() == String.trim(src)

      assert output =~ ~r/^1: module: nil/m
      assert output =~ ~r/^16: module:.{Traverse.SomeModule/m
      assert output =~ ~r/^66: module:.{Traverse.Simple/m
      assert output =~ ~r/^67: module:.{Traverse.Simple.Nested/m
      assert output =~ ~r/^85: module:.{Traverse.Simple/m
    end

    test "collect use, import, etc..." do
      src = File.read!("test/fixtures/context/use_import_etc.ex")

      {result, output} =
        assert with_io(fn ->
                 src
                 |> Sourceror.parse_string!()
                 |> Zipper.zip()
                 |> Context.traverse(fn zipper, context ->
                   context =
                     context
                     |> inc()
                     |> write()

                   {zipper, context}
                 end)
               end)

      assert result |> Zipper.node() |> Sourceror.to_string() == String.trim(src)

      assert output =~ ~r/^77: aliases:.*Donald.Duck/m
      assert output =~ ~r/^77: requirements:.*Logger/m
      assert output =~ ~r/^77: usages:.*Traverse.Obelix/m
      assert output =~ ~r/^77: imports:.*Traverse.Pluto/m
    end
  end

  defp inc(%Context{assigns: %{count: count}} = context) do
    Context.assign(context, :count, count + 1)
  end

  defp inc(%Context{} = context) do
    Context.assign(context, :count, 1)
  end

  defp write(context) do
    %{count: count} = context.assigns
    IO.write("#{count}: module: #{inspect(context.module)}" <> "\n")
    IO.write("#{count}: definition: #{inspect(context.definition)}" <> "\n")
    IO.write("#{count}: usages: #{inspect(context.usages)}" <> "\n")
    IO.write("#{count}: aliases: #{inspect(context.aliases)}" <> "\n")
    IO.write("#{count}: requirements: #{inspect(context.requirements)}" <> "\n")
    IO.write("#{count}: imports: #{inspect(context.imports)}" <> "\n")
    context
  end
end
