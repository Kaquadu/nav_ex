defmodule NavEx.ConnCase do
  @moduledoc false
  use ExUnit.CaseTemplate

  using do
    quote do
      import Plug.Conn
      import Plug.Test
      import NavEx.ConnCase
    end
  end
end
