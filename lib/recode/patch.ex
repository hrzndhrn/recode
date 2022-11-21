defmodule Recode.Patch do
  @moduledoc """
  TODO: add moduledoc
  """

  alias Recode.Traverse
  alias Sourceror.Zipper

  def insert(zipper, ast, opts) do
    zipper =
      case Traverse.to(zipper, opts[:after]) do
        :error -> zipper
        {:ok, zipper} -> zipper
      end

    Zipper.insert_right(zipper, ast)
  end
end
