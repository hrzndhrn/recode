defmodule MyCode.SameLine do
  def foo(x)
      when is_integer(x) do
    {
      :foo,
      x
    }
  end
end
