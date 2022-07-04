defmodule Double.Foo do
  defmodule Bar do
    def foo(x) do
      bar(x)
    end

    defp bar(x), do: x * 2
  end

  def foo(x) do
    Bar.foo(x)
  end
end
