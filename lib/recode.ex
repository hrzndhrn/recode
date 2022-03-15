defmodule Recode do
  @moduledoc """
  A linter with autocorrection and a refactoring tool.
  """
  left =
    {:ok,
     %{
       attributes: [],
       compile_opts: [],
       definitions: [{{:bar, 0}, :def, [line: 2], [{[line: 2], [], [], :bar}]}],
       deprecated: [],
       file: "nofile",
       is_behaviour: false,
       line: 1,
       module: Bar,
       relative_file: "nofile",
       unreachable: []
     }}

  right =
    {:ok,
     %{
       attributes: [],
       compile_opts: [],
       definitions: [
         {{:bar, 0}, :def, [line: 2], [{[line: 2], [], [], :bar}]}
       ],
       deprecated: [],
       file: "nofile",
       is_behaviour: false,
       line: 1,
       module: Bar,
       relative_file: "nofile",
       struct: nil,
       unreachable: []
     }}
end
