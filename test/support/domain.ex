# SPDX-FileCopyrightText: 2020 Zach Daniel
#
# SPDX-License-Identifier: MIT

defmodule AshCloak.Test.Domain do
  @moduledoc false
  use Ash.Domain

  resources do
    resource(AshCloak.Test.Resource)
  end
end
