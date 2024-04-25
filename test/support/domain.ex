defmodule AshCloak.Test.Domain do
  @moduledoc false
  use Ash.Domain

  resources do
    resource(AshCloak.Test.Resource)
  end
end
