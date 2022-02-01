defmodule Recode.Equal do
  def mfa?({module, fun, nil}, {module, fun, _}), do: true
  def mfa?({module, fun, _}, {module, fun, nil}), do: true
  def mfa?({module, fun, arity}, {module, fun, arity}), do: true
  def mfa?({_, _, _}, {_, _, _}), do: false
end
