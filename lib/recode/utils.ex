defmodule Recode.Utils do
  @moduledoc false

  def ends_with?(module1, module2) when is_atom(module1) and is_atom(module2) do
    module1 = Module.split(module1)
    module2 = Module.split(module2)

    ends_with?(module1, module2)
  end

  def ends_with?(list, postfix) when is_list(list) and is_list(postfix) do
    case length(list) - length(postfix) do
      diff when diff < 0 -> false
      diff -> Enum.drop(list, diff) == postfix
    end
  end
end
