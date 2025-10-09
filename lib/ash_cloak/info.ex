# SPDX-FileCopyrightText: 2020 Zach Daniel
#
# SPDX-License-Identifier: MIT

defmodule AshCloak.Info do
  @moduledoc "Introspection functions for the `AshCloak` extension."
  use Spark.InfoGenerator, extension: AshCloak, sections: [:cloak]
end
