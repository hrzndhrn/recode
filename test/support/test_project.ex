defmodule TestProject do
  @moduledoc """
  A module to fake projects in tests.
  """

  @doc """
  Creates a new project.
  """
  def new do
    nr = :erlang.unique_integer([:positive])

    {{:module, module, _bin, _meta}, _binding} =
      Code.eval_string("""
      defmodule FormatWithDepsApp#{nr} do
        def project do
          [
            app: :test_project_#{nr},
            version: "0.1.0"
          ]
        end
      end
      """)

    module
  end
end
