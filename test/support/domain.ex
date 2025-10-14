# SPDX-FileCopyrightText: 2024 ash_cloak contributors <https://github.com/ash-project/ash_cloak/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshCloak.Test.Domain do
  @moduledoc false
  use Ash.Domain

  resources do
    resource(AshCloak.Test.Resource)
  end
end
