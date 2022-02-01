defmodule RecodeTest do
  use ExUnit.Case

  import ExUnit.CaptureIO

  doctest Recode

  alias Recode.Context
  alias Sourceror.Zipper

  describe "traverse/3" do
    test "traverse a simple module" do
      src = File.read!("test/fixtures/traverse/simple.ex")

      {result, acc} =
        src
        |> Sourceror.parse_string!()
        |> Zipper.zip()
        |> Recode.traverse([], fn zipper, context, acc ->
          {zipper, context, ["#{inspect(context.module)}, #{inspect(context.definition)}" | acc]}
        end)

      assert result |> Zipper.node() |> Sourceror.to_string() == String.trim(src)

      assert acc |> Enum.uniq() |> Enum.reverse() |> Enum.join("\n") == """
             [:Traverse, :Simple], nil
             [:Traverse, :Simple], {:def, :foo, 1}\
             """
    end
  end

  describe "traverse/2" do
    test "traverses a simple module" do
      src = File.read!("test/fixtures/traverse/simple.ex")

      {result, output} =
        assert with_io(fn ->
                 src
                 |> Sourceror.parse_string!()
                 |> Zipper.zip()
                 |> Recode.traverse(fn zipper, context ->
                   context =
                     context
                     |> inc()
                     |> write()

                   {zipper, context}
                 end)
               end)

      assert result |> Zipper.node() |> Sourceror.to_string() == String.trim(src)

      assert output =~
               ~r/count:.1.*definition:.nil.*imports:.\[\].*module:.\[:Traverse,.:Simple\]/

      assert output =~ ~r/count:.9.,.definition:.\{:def,.:foo,.1\}/
    end

    test "traverse a nested module" do
      src = File.read!("test/fixtures/traverse/nested.ex")

      {result, output} =
        assert with_io(fn ->
                 src
                 |> Sourceror.parse_string!()
                 |> Zipper.zip()
                 |> Recode.traverse(fn zipper, context ->
                   context =
                     context
                     |> inc()
                     |> write()

                   {zipper, context}
                 end)
               end)

      assert result |> Zipper.node() |> Sourceror.to_string() == String.trim(src)
      assert output =~ ~r/^.*count:.1.*module:.\[\].*$/m
      assert output =~ ~r/^.*count:.16.*module:.\[:Traverse,.:SomeModule\].*$/m
      assert output =~ ~r/^.*count:.66.*module:.\[:Traverse,.:Simple\].*$/m
      assert output =~ ~r/^.*count:.67.*module:.\[:Traverse,.:Simple,.:Nested\].*$/m
      assert output =~ ~r/^.*count:.85.*module:.\[:Traverse,.:Simple\].*$/m
    end
  end

  defp inc(%Context{assigns: %{count: count}} = context) do
    Context.assign(context, :count, count + 1)
  end

  defp inc(%Context{} = context) do
    Context.assign(context, :count, 1)
  end

  defp write(context) do
    IO.write(inspect(context) <> "\n")
    context
  end
end
