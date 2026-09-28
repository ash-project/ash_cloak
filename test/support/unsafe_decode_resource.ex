# SPDX-FileCopyrightText: 2024 ash_cloak contributors <https://github.com/ash-project/ash_cloak/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshCloak.Test.UnsafeDecodeResource do
  @moduledoc """
  A resource with `safe_decode?(false)`, so decrypted payloads are decoded without
  `:safe` and may contain atoms that do not exist in the VM yet.
  """

  use Ash.Resource,
    domain: AshCloak.Test.Domain,
    data_layer: Ash.DataLayer.Ets,
    extensions: [AshCloak]

  ets do
    private?(true)
  end

  actions do
    defaults([:read, :destroy, create: [:data, :profile], update: [:data, :profile]])
  end

  cloak do
    vault(AshCloak.Test.Vault)
    attributes([:data, :profile])
    safe_decode?(false)
  end

  attributes do
    uuid_primary_key(:id)
    attribute(:data, :term, public?: true)
    attribute(:profile, AshCloak.Test.EmbeddedProfile, public?: true)
  end
end
