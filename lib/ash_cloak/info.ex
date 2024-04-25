defmodule AshCloak.Info do
  @moduledoc "Introspection functions for the `AshCloak` extension."
  use Spark.InfoGenerator, extension: AshCloak, sections: [:cloak]
end
