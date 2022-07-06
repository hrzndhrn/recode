defmodule Vars do
  def vars do
    alias = "alias"
    import = "import"
    require = "require"
    use = "use"
    defimpl = "defimpl"
    def = "def"
  end

  def vars(x) do
    alias = identity(x)
    import = identity(x)
    require = identity(x)
    use = identity(x)
    defimpl = identity(x)
    def = identity(x)
  end

  defp identity(x), do: x
end
