defmodule Recode.DotFormatterTest do
  use ExUnit.Case

  alias Recode.DotFormatter

  test "opts" do
    assert DotFormatter.opts() == [
             inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"]
           ]
  end

  test "inputs" do
    assert DotFormatter.inputs() == ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"]
  end

  test "locals_without_parens" do
    assert DotFormatter.locals_without_parens() == []
  end
end
