defmodule MyCode.RaiseTask do
  @moduledoc false

  use Recode.Task, corrector: true

  @impl Recode.Task
  def run(_source, _opts) do
    raise "Ups"
  end
end
