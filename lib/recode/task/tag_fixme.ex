defmodule Recode.Task.TagFIXME do
  @shortdoc "Checks if there are FIXME tags in the sources."

  @moduledoc """
  #{@shortdoc}

  FIXME tags in comments and docs are used as a reminder and should be handeld in
  the near future.

  ## Examples

      # FIXME: this function returns a wrong value
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
    Tags.init(Keyword.merge([tag: "FIXME", reporter: __MODULE__], opts))
  end

  @impl Recode.Task
  defdelegate run(source, opts), to: Tags
end
