defmodule MyCode.Autocorrect.AliasExpansion do
  alias MyCode.Autocorrect.{SinglePipe, PipeFunOne}

  def foo(x) do
    SinglePipe.double(x) + PipeFunOne.double(x)
  end
end
