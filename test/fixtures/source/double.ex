defmodule Double.Foo do
  def foo(x) do
    x * 2
  end
end

defmodule Double.Bar do
  def foo(x) do
    bar(x)
  end

  defp bar(x), do: x * 2
end
