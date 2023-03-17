defmodule MyCode.AliasExpansion do
  alias MyCode.PipeFunOne
  alias MyCode.SinglePipe

  def foo(x) do
    SinglePipe.double(x) + PipeFunOne.double(x)
  end
end
