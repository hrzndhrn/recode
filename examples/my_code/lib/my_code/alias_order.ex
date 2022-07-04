defmodule MyCode.Echo do
  @moduledoc false

  def say, do: :echo
end

defmodule MyCode.Foxtrot do
  @moduledoc false

  def say, do: :foxtrot
end

defmodule Mycode.AliasOrder do
  alias MyCode.SinglePipe
  alias MyCode.PipeFunOne
  alias MyCode.{Foxtrot, Echo}

  @doc false
  def foo do
    {SinglePipe.double(2), PipeFunOne.double(3)}
  end

  @doc false
  def echo_foxtrot, do: {Echo.say(), Foxtrot.say()}
end
