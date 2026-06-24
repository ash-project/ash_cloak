# SPDX-FileCopyrightText: 2024 ash_cloak contributors <https://github.com/ash-project/ash_cloak/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshCloak.Test.EmbeddedProfile do
  @moduledoc """
  A plain embedded resource used as the *type* of an encrypted attribute.

  It is intentionally not encrypted itself — the point is to observe how
  ash_cloak serializes a value of this type when that value lives in an
  encrypted attribute on another resource.
  """

  use Ash.Resource, data_layer: :embedded

  actions do
    defaults([:read, :destroy, create: [:nickname, :age], update: [:nickname, :age]])
  end

  attributes do
    attribute(:nickname, :string, public?: true)
    attribute(:age, :integer, public?: true)
  end
end
