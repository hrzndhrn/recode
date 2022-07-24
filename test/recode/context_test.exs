defmodule Recode.ContextTest do
  use ExUnit.Case

  import ExUnit.CaptureIO

  alias Recode.Context
  alias Sourceror.Zipper

  doctest Recode.Context

  describe "traverse/2" do
    test "traverses a simple module" do
      src = File.read!("test/fixtures/context/simple.ex")

      output =
        capture_io(fn ->
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

      assert output =~ ~r/^1:.module:.{Traverse.Simple,.*line:.1,/m
      assert output =~ ~r/^9:.definition:.nil/m
      assert output =~ ~r/^10:.definition:.{{:def,.:foo,.1},.*line:.2/m
      assert output =~ ~r/^21:.definition:.{{:def,.:baz,.0},.*line:.6/m
    end

    test "traverses modules and collects @moduledoc, @doc and @spec" do
      src = File.read!("test/fixtures/context/doc_and_spec.ex")

      output =
        capture_io(fn ->
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

      assert output =~ ~r/^1:.moduledoc:.nil/m
      assert output =~ ~r/^1:.doc:.nil/m
      assert output =~ ~r/^1:.spec:.nil/m

      assert output =~ ~r/^10:.moduledoc:.*Doc.for.module.simple/m

      assert output =~ ~r/^40:.moduledoc:.nil/m
      refute output =~ ~r/^40:.doc:.nil/m
      refute output =~ ~r/^40:.spec:.nil/m

      refute output =~ ~r/^51:.doc:.nil/m
      refute output =~ ~r/^51:.spec:.nil/m

      refute output =~ ~r/^63:.doc:.nil/m
      refute output =~ ~r/^63:.spec:.nil/m

      assert output =~ ~r/^64:.doc:.nil/m
      assert output =~ ~r/^64:.spec:.nil/m
    end

    test "traverses modules and collects @impl" do
      src = File.read!("test/fixtures/context/impl.ex")

      output =
        capture_io(fn ->
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

      assert output =~ """
             27: impl: {{:def, :foo, 1}, \
             {:@, [trailing_comments: [], leading_comments: [], \
             end_of_expression: [newlines: 1, line: 4, column: 13], line: 4, column: 3], \
             [{:impl, [trailing_comments: [], leading_comments: [], line: 4, column: 4], \
             [{:__block__, [trailing_comments: [], leading_comments: [], line: 4, column: 9], \
             [true]}]}]}}\
             """

      assert output =~ """
             42: impl: {{:def, :baz, 0}, \
             {:@, [trailing_comments: [], leading_comments: [], \
             end_of_expression: [newlines: 1, line: 7, column: 27], line: 7, column: 3], \
             [{:impl, [trailing_comments: [], leading_comments: [], line: 7, column: 4], \
             [{:__aliases__, [trailing_comments: [], leading_comments: [], \
             last: [line: 7, column: 18], line: 7, column: 9], \
             [:Traverse, :Something]}]}]}}\
             """
    end

    test "traverse a nested module" do
      src = File.read!("test/fixtures/context/nested.ex")

      output =
        capture_io(fn ->
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

      assert output =~ ~r/^1: module: nil/m
      assert output =~ ~r/^16: module:.{Traverse.SomeModule,/m
      assert output =~ ~r/^76: module:.{Traverse.Simple,/m
      assert output =~ ~r/^113: module:.{Traverse.Simple.Nested,/m
      assert output =~ ~r/^134: module:.{Traverse.Simple,/m
    end

    test "collect use, import, etc..." do
      src = File.read!("test/fixtures/context/use_import_etc.ex")

      output =
        capture_io(fn ->
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

      assert output =~ ~r/^158: aliases:.*Donald.Duck/m
      assert output =~ ~r/^158: aliases:.*Foo.Bar/m
      assert output =~ ~r/^158: aliases:.*Foo.Baz/m
      assert output =~ ~r/^158: requirements:.*Logger/m
      assert output =~ ~r/^158: usages:.*Traverse.Obelix/m

      assert output =~ """
             158: imports: [\
             {Traverse.Pluto, [trailing_comments: [], leading_comments: [], \
             end_of_expression: [newlines: 1, line: 22, column: 24], line: 22, column: 3], nil}, \
             {Traverse.Mouse, [trailing_comments: [], leading_comments: [], \
             end_of_expression: [newlines: 1, line: 23, column: 42], line: 23, column: 3], \
             [{{:__block__, [trailing_comments: [], leading_comments: [], \
             format: :keyword, line: 23, column: 26], [:only]}, \
             {:__block__, [trailing_comments: [], leading_comments: [], \
             closing: [line: 23, column: 41], line: 23, column: 32], \
             [[{{:__block__, [trailing_comments: [], leading_comments: [], \
             format: :keyword, line: 23, column: 33], [:micky]}, \
             {:__block__, [trailing_comments: [], leading_comments: [], \
             token: "1", line: 23, column: 40], [1]}}]]}}]}, \
             {Traverse.Gladstone, [trailing_comments: [], leading_comments: [], \
             end_of_expression: [newlines: 2, line: 24, column: 38], line: 24, column: 3], nil}, \
             {Traverse.Gander, [trailing_comments: [], leading_comments: [], \
             end_of_expression: [newlines: 2, line: 24, column: 38], line: 24, column: 3], nil}]\
             """

      assert output =~ ~r/^189: module:.*Traverse.Timer/m
      assert output =~ ~r/^189: imports:.*:timer/m

      assert output =~ ~r/^202: module:.*Traverse.RequireAlias/m
      assert output =~ ~r/^202: aliases:.*Traverse.Pluto.*line: 45, column: 11/m
      assert output =~ ~r/^202: requirements:.*Traverse.Pluto.*line: 45, column: 3/m

      assert output =~ ~r/^221: module:.*Traverse.RequireAliasAs/m
      assert output =~ ~r/^221: aliases:.*Traverse.Pluto.*:Foo/m
      assert output =~ ~r/^221: requirements:.*Traverse.Pluto.*:Foo/m

      assert output =~ ~r/^234: module:.*Traverse.AliasRequire/m
      assert output =~ ~r/^234: aliases:.*Traverse.Pluto/m
      assert output =~ ~r/^234: requirements:.*Traverse.Pluto/m
    end

    test "traveses script with vars named alias, import, etc.." do
      src = File.read!("test/fixtures/context/vars.exs")

      output =
        capture_io(fn ->
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

      assert output |> String.split("\n") |> Enum.count() == 221
    end

    test "traveses module with vars named alias, import, etc.." do
      src = File.read!("test/fixtures/context/vars.ex")

      output =
        capture_io(fn ->
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

      assert output |> String.split("\n") |> Enum.count() == 848
    end
  end

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

    test "traverses modules and collects @moduledoc, @doc and @spec" do
      src = File.read!("test/fixtures/context/doc_and_spec.ex")

      {result, acc} =
        src
        |> Sourceror.parse_string!()
        |> Zipper.zip()
        |> Context.traverse([], fn zipper, context, acc ->
          context = inc(context)
          {zipper, context, [context | acc]}
        end)

      assert result |> Zipper.node() |> Sourceror.to_string() == String.trim(src)

      acc = Enum.reverse(acc)

      at = 0
      assert acc |> Enum.at(at) |> Map.get(:moduledoc) == nil
      assert acc |> Enum.at(at) |> Map.get(:doc) == nil
      assert acc |> Enum.at(at) |> Map.get(:spec) == nil

      at = 10
      assert acc |> Enum.at(at) |> Map.get(:module) |> elem(0) == Traverse.Simple
      assert acc |> Enum.at(at) |> Map.get(:moduledoc) != nil

      at = 25
      assert acc |> Enum.at(at) |> Map.get(:module) |> elem(0) == Traverse.Simpler
      assert acc |> Enum.at(at) |> Map.get(:moduledoc) == nil

      at = 52
      assert acc |> Enum.at(at) |> Map.get(:definition) |> elem(0) == {:def, :foo, 1}
      assert acc |> Enum.at(at) |> Map.get(:moduledoc) == nil
      assert acc |> Enum.at(at) |> Map.get(:doc) != nil
      assert acc |> Enum.at(at) |> Map.get(:spec) != nil

      at = 62
      assert acc |> Enum.at(at) |> Map.get(:definition) |> elem(0) == {:def, :foo, 1}
      assert acc |> Enum.at(at) |> Map.get(:doc) != nil
      assert acc |> Enum.at(at) |> Map.get(:spec) != nil

      at = 64
      assert acc |> Enum.at(at) |> Map.get(:definition) |> elem(0) == {:def, :baz, 0}
      assert acc |> Enum.at(at) |> Map.get(:moduledoc) == nil
      assert acc |> Enum.at(at) |> Map.get(:doc) == nil
      assert acc |> Enum.at(at) |> Map.get(:spec) == nil
    end

    test "traverses modules and collects @impl" do
      src = File.read!("test/fixtures/context/impl.ex")

      {_result, acc} =
        src
        |> Sourceror.parse_string!()
        |> Zipper.zip()
        |> Context.traverse([], fn zipper, context, acc ->
          {zipper, context, [context | acc]}
        end)

      acc = Enum.reverse(acc)

      assert acc |> Enum.at(17) |> Map.get(:impl) ==
               {{:def, :foo, 1},
                {:@,
                 [
                   trailing_comments: [],
                   leading_comments: [],
                   end_of_expression: [newlines: 1, line: 4, column: 13],
                   line: 4,
                   column: 3
                 ],
                 [
                   {:impl, [trailing_comments: [], leading_comments: [], line: 4, column: 4],
                    [
                      {:__block__,
                       [trailing_comments: [], leading_comments: [], line: 4, column: 9], [true]}
                    ]}
                 ]}}

      assert acc |> Enum.at(41) |> Map.get(:impl) ==
               {{:def, :baz, 0},
                {:@,
                 [
                   trailing_comments: [],
                   leading_comments: [],
                   end_of_expression: [newlines: 1, line: 7, column: 27],
                   line: 7,
                   column: 3
                 ],
                 [
                   {:impl, [trailing_comments: [], leading_comments: [], line: 7, column: 4],
                    [
                      {:__aliases__,
                       [
                         trailing_comments: [],
                         leading_comments: [],
                         last: [line: 7, column: 18],
                         line: 7,
                         column: 9
                       ], [:Traverse, :Something]}
                    ]}
                 ]}}
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

      contexts =
        acc
        |> Enum.group_by(fn
          %Context{module: nil} -> nil
          %Context{module: module} -> elem(module, 0)
        end)
        |> Enum.map(fn {key, list} -> {key, hd(list)} end)

      assert contexts[Traverse.Foo] == %Context{
               aliases: [
                 {
                   Traverse.Nested.Simple,
                   [
                     trailing_comments: [],
                     leading_comments: [],
                     end_of_expression: [newlines: 1, line: 18, column: 31],
                     line: 18,
                     column: 3
                   ],
                   nil
                 },
                 {
                   Donald.Duck,
                   [
                     trailing_comments: [],
                     leading_comments: [],
                     end_of_expression: [newlines: 1, line: 19, column: 31],
                     line: 19,
                     column: 3
                   ],
                   [
                     {
                       {:__block__,
                        [
                          trailing_comments: [],
                          leading_comments: [],
                          format: :keyword,
                          line: 19,
                          column: 22
                        ], [:as]},
                       {:__aliases__,
                        [
                          trailing_comments: [],
                          leading_comments: [],
                          last: [line: 19, column: 26],
                          line: 19,
                          column: 26
                        ], [:Goofy]}
                     }
                   ]
                 },
                 {
                   Foo.Bar,
                   [
                     trailing_comments: [],
                     leading_comments: [],
                     end_of_expression: [newlines: 2, line: 20, column: 23],
                     line: 20,
                     column: 3
                   ],
                   nil
                 },
                 {
                   Foo.Baz,
                   [
                     trailing_comments: [],
                     leading_comments: [],
                     end_of_expression: [newlines: 2, line: 20, column: 23],
                     line: 20,
                     column: 3
                   ],
                   nil
                 }
               ],
               assigns: %{},
               definition: {
                 {:def, :mouse, 0},
                 [
                   trailing_comments: [],
                   leading_comments: [],
                   do: [line: 35, column: 13],
                   end: [line: 37, column: 3],
                   line: 35,
                   column: 3
                 ]
               },
               imports: [
                 {Traverse.Pluto,
                  [
                    trailing_comments: [],
                    leading_comments: [],
                    end_of_expression: [newlines: 1, line: 22, column: 24],
                    line: 22,
                    column: 3
                  ], nil},
                 {Traverse.Mouse,
                  [
                    trailing_comments: [],
                    leading_comments: [],
                    end_of_expression: [newlines: 1, line: 23, column: 42],
                    line: 23,
                    column: 3
                  ],
                  [
                    {
                      {:__block__,
                       [
                         trailing_comments: [],
                         leading_comments: [],
                         format: :keyword,
                         line: 23,
                         column: 26
                       ], [:only]},
                      {:__block__,
                       [
                         trailing_comments: [],
                         leading_comments: [],
                         closing: [line: 23, column: 41],
                         line: 23,
                         column: 32
                       ],
                       [
                         [
                           {{:__block__,
                             [
                               trailing_comments: [],
                               leading_comments: [],
                               format: :keyword,
                               line: 23,
                               column: 33
                             ], [:micky]},
                            {:__block__,
                             [
                               trailing_comments: [],
                               leading_comments: [],
                               token: "1",
                               line: 23,
                               column: 40
                             ], [1]}}
                         ]
                       ]}
                    }
                  ]},
                 {Traverse.Gladstone,
                  [
                    trailing_comments: [],
                    leading_comments: [],
                    end_of_expression: [newlines: 2, line: 24, column: 38],
                    line: 24,
                    column: 3
                  ], nil},
                 {Traverse.Gander,
                  [
                    trailing_comments: [],
                    leading_comments: [],
                    end_of_expression: [newlines: 2, line: 24, column: 38],
                    line: 24,
                    column: 3
                  ], nil}
               ],
               module: {
                 Traverse.Foo,
                 [
                   trailing_comments: [],
                   leading_comments: [],
                   end_of_expression: [newlines: 2, line: 38, column: 4],
                   do: [line: 15, column: 24],
                   end: [line: 38, column: 1],
                   line: 15,
                   column: 1
                 ]
               },
               requirements: [
                 {
                   Logger,
                   [
                     trailing_comments: [],
                     leading_comments: [],
                     end_of_expression: [newlines: 1, line: 26, column: 17],
                     line: 26,
                     column: 3
                   ],
                   nil
                 },
                 {Traverse.Pluto,
                  [
                    trailing_comments: [],
                    leading_comments: [],
                    end_of_expression: [newlines: 2, line: 27, column: 37],
                    line: 27,
                    column: 3
                  ],
                  [
                    {
                      {:__block__,
                       [
                         trailing_comments: [],
                         leading_comments: [],
                         format: :keyword,
                         line: 27,
                         column: 27
                       ], [:as]},
                      {:__aliases__,
                       [
                         trailing_comments: [],
                         leading_comments: [],
                         last: [line: 27, column: 31],
                         line: 27,
                         column: 31
                       ], [:Animal]}
                    }
                  ]}
               ],
               usages: [
                 {
                   Traverse.Obelix,
                   [
                     trailing_comments: [],
                     leading_comments: [],
                     end_of_expression: [newlines: 2, line: 16, column: 37],
                     line: 16,
                     column: 3
                   ],
                   [
                     {
                       {:__block__,
                        [
                          trailing_comments: [],
                          leading_comments: [],
                          format: :keyword,
                          line: 16,
                          column: 24
                        ], [:app]},
                       {:__aliases__,
                        [
                          trailing_comments: [],
                          leading_comments: [],
                          last: [line: 16, column: 29],
                          line: 16,
                          column: 29
                        ], [:Traverse]}
                     }
                   ]
                 }
               ]
             }

      assert contexts[Traverse.Timer] ==
               %Context{
                 aliases: [],
                 assigns: %{},
                 definition: nil,
                 doc: nil,
                 impl: nil,
                 imports: [
                   {:timer, [trailing_comments: [], leading_comments: [], line: 41, column: 3],
                    nil}
                 ],
                 module:
                   {Traverse.Timer,
                    [
                      trailing_comments: [],
                      leading_comments: [],
                      end_of_expression: [newlines: 2, line: 42, column: 4],
                      do: [line: 40, column: 26],
                      end: [line: 42, column: 1],
                      line: 40,
                      column: 1
                    ]},
                 moduledoc: nil,
                 requirements: [],
                 spec: nil,
                 usages: []
               }

      assert contexts[Traverse.RequireAlias] == %Context{
               aliases: [
                 {Traverse.Pluto,
                  [trailing_comments: [], leading_comments: [], line: 45, column: 11], nil}
               ],
               assigns: %{},
               definition: nil,
               doc: nil,
               impl: nil,
               imports: [],
               module:
                 {Traverse.RequireAlias,
                  [
                    trailing_comments: [],
                    leading_comments: [],
                    end_of_expression: [newlines: 2, line: 46, column: 4],
                    do: [line: 44, column: 33],
                    end: [line: 46, column: 1],
                    line: 44,
                    column: 1
                  ]},
               moduledoc: nil,
               requirements: [
                 {Traverse.Pluto,
                  [trailing_comments: [], leading_comments: [], line: 45, column: 3], nil}
               ],
               spec: nil,
               usages: []
             }

      assert contexts[Traverse.RequireAliasAs] == %Context{
               aliases: [
                 {Traverse.Pluto,
                  [trailing_comments: [], leading_comments: [], line: 49, column: 11],
                  [
                    {{:__block__,
                      [
                        trailing_comments: [],
                        leading_comments: [],
                        format: :keyword,
                        line: 49,
                        column: 33
                      ], [:as]},
                     {:__aliases__,
                      [
                        trailing_comments: [],
                        leading_comments: [],
                        last: [line: 49, column: 37],
                        line: 49,
                        column: 37
                      ], [:Foo]}}
                  ]}
               ],
               assigns: %{},
               definition: nil,
               doc: nil,
               impl: nil,
               imports: [],
               module:
                 {Traverse.RequireAliasAs,
                  [
                    trailing_comments: [],
                    leading_comments: [],
                    end_of_expression: [newlines: 2, line: 50, column: 4],
                    do: [line: 48, column: 35],
                    end: [line: 50, column: 1],
                    line: 48,
                    column: 1
                  ]},
               moduledoc: nil,
               requirements: [
                 {[
                    {Traverse.Pluto,
                     [trailing_comments: [], leading_comments: [], line: 49, column: 11],
                     [
                       {{:__block__,
                         [
                           trailing_comments: [],
                           leading_comments: [],
                           format: :keyword,
                           line: 49,
                           column: 33
                         ], [:as]},
                        {:__aliases__,
                         [
                           trailing_comments: [],
                           leading_comments: [],
                           last: [line: 49, column: 37],
                           line: 49,
                           column: 37
                         ], [:Foo]}}
                     ]}
                  ], [trailing_comments: [], leading_comments: [], line: 49, column: 3], nil}
               ],
               spec: nil,
               usages: []
             }

      assert contexts[Traverse.AliasRequire] ==
               %Context{
                 aliases: [
                   {Traverse.Pluto,
                    [trailing_comments: [], leading_comments: [], line: 53, column: 3], nil}
                 ],
                 assigns: %{},
                 definition: nil,
                 doc: nil,
                 impl: nil,
                 imports: [],
                 module:
                   {Traverse.AliasRequire,
                    [
                      trailing_comments: [],
                      leading_comments: [],
                      do: [line: 52, column: 33],
                      end: [line: 54, column: 1],
                      line: 52,
                      column: 1
                    ]},
                 moduledoc: nil,
                 requirements: [
                   {Traverse.Pluto,
                    [trailing_comments: [], leading_comments: [], line: 53, column: 9], nil}
                 ],
                 spec: nil,
                 usages: []
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

  defp inc(%Context{assigns: %{count: count}} = context) do
    Context.assign(context, :count, count + 1)
  end

  defp inc(%Context{} = context) do
    Context.assign(context, :count, 1)
  end

  defp write(context) do
    %{count: count} = context.assigns
    IO.write("=== #{count} ===\n")
    IO.write("#{count}: module: #{inspect(context.module)}" <> "\n")
    IO.write("#{count}: definition: #{inspect(context.definition)}" <> "\n")
    IO.write("#{count}: usages: #{inspect(context.usages)}" <> "\n")
    IO.write("#{count}: aliases: #{inspect(context.aliases)}" <> "\n")
    IO.write("#{count}: requirements: #{inspect(context.requirements)}" <> "\n")
    IO.write("#{count}: imports: #{inspect(context.imports)}" <> "\n")
    IO.write("#{count}: moduledoc: #{inspect(context.moduledoc)}" <> "\n")
    IO.write("#{count}: doc: #{inspect(context.doc)}" <> "\n")
    IO.write("#{count}: spec: #{inspect(context.spec)}" <> "\n")
    IO.write("#{count}: impl: #{inspect(context.impl)}" <> "\n")
    context
  end
end
