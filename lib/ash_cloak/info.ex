# SPDX-FileCopyrightText: 2024 ash_cloak contributors <https://github.com/ash-project/ash_cloak/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshCloak.Info do
  @moduledoc "Introspection functions for the `AshCloak` extension."
  use Spark.InfoGenerator, extension: AshCloak, sections: [:cloak]
end
