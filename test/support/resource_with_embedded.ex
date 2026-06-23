# SPDX-FileCopyrightText: 2024 ash_cloak contributors <https://github.com/ash-project/ash_cloak/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshCloak.Test.ResourceWithEmbedded do
  @moduledoc """
  A resource with an encrypted attribute whose type is an embedded resource.

  Used to reproduce how ash_cloak serializes embedded values: via
  `:erlang.term_to_binary/1` on the in-memory struct, rather than through the
  type's storage representation (`dump_to_native/2`).
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
