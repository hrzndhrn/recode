defmodule Recode.ASTTest do
  use ExUnit.Case

  doctest Recode.AST, import: true

  alias Recode.AST
  alias Sourceror.Zipper

  describe "atom?/1" do
    test "returns true for an atom" do
      assert AST.atom?(:atom) == true
      assert ":atom" |> Code.string_to_quoted!() |> AST.atom?() == true
      assert ":atom" |> Sourceror.parse_string!() |> AST.atom?() == true
      assert ":atom" |> Sourceror.parse_string!() |> Zipper.zip() |> AST.atom?() == true
    end
  end
end
