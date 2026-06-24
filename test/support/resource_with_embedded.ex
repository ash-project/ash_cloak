# SPDX-FileCopyrightText: 2024 ash_cloak contributors <https://github.com/ash-project/ash_cloak/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshCloak.Test.ResourceWithEmbedded do
  @moduledoc """
  A resource with an encrypted attribute whose type is an embedded resource.

  Used by tests to assert embedded values are encrypted via their embedded
  representation (`Ash.Type.dump_to_embedded/3`) and restored via
  `Ash.Type.cast_from_embedded/3`.
  """

  use Ash.Resource,
    domain: AshCloak.Test.Domain,
    data_layer: Ash.DataLayer.Ets,
    extensions: [AshCloak]

  ets do
    private?(true)
  end

  actions do
    defaults([:read, :destroy, create: [:profile], update: [:profile]])
  end

  cloak do
    vault(AshCloak.Test.Vault)
    attributes([:profile])
    decrypt_by_default([:profile])
  end

  attributes do
    uuid_primary_key(:id)
    attribute(:profile, AshCloak.Test.EmbeddedProfile, public?: true)
  end
end
