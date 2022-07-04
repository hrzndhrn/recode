defmodule MyCode.AliasExpansion do
  alias MyCode.{PipeFunOne, SinglePipe}

  def foo(x) do
    SinglePipe.double(x) + PipeFunOne.double(x)
  end
end
