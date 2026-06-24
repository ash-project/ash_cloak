# SPDX-FileCopyrightText: 2024 ash_cloak contributors <https://github.com/ash-project/ash_cloak/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshCloak.Test.ResourceWithUnion do
  @moduledoc """
  A resource with an encrypted attribute whose type is a union that includes an
  embedded resource. Exercises that union values are encrypted via their storage
  representation rather than the raw `%Ash.Union{}`/embedded struct.
  """

  use Ash.Resource,
    domain: AshCloak.Test.Domain,
    data_layer: Ash.DataLayer.Ets,
    extensions: [AshCloak]

  ets do
    private?(true)
  end

  actions do
    defaults([:read, :destroy, create: [:thing], update: [:thing]])
  end

  cloak do
    vault(AshCloak.Test.Vault)
    attributes([:thing])
    decrypt_by_default([:thing])
  end

  attributes do
    uuid_primary_key(:id)

    attribute(:thing, :union,
      public?: true,
      constraints: [
        types: [
          profile: [type: AshCloak.Test.EmbeddedProfile],
          note: [type: :string]
        ]
      ]
    )
  end
end
