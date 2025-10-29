defmodule Recode.Task.TagTODO do
  @shortdoc "Checks if there are TODO tags in the sources."

  @moduledoc """
  #{@shortdoc}

  TODO tags in comments and docs are used as a reminder and should be handled in
  the near future.

  ## Examples

      # TODO: refactor this function
      def fun do
        # ...
      end

  ## Options

    * `:include_docs` - includes `@doc`, `@moduledoc` and `@shortdoc` to the
                        check when set to `true`. Defaults to `true`.

  """

  use Recode.Task, category: :design

  alias Recode.Task.Tags

  @impl Recode.Task
  def init(opts) do
    Tags.init(Keyword.merge([tag: "TODO", reporter: __MODULE__], opts))
  end

  @impl Recode.Task
  defdelegate run(source, opts), to: Tags
end
