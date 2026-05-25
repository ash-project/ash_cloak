# SPDX-FileCopyrightText: 2024 ash_cloak contributors <https://github.com/ash-project/ash_cloak/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshCloak.Test.EmbeddedResource do
  @moduledoc false

  use Ash.Resource,
    data_layer: :embedded,
    extensions: [AshCloak]

  actions do
    defaults([
      :read,
      :destroy,
      create: [:encrypted, :not_encrypted],
      update: [:encrypted, :not_encrypted]
    ])
  end

  cloak do
    vault(AshCloak.Test.Vault)
    attributes([:encrypted])
    decrypt_by_default([:encrypted])
  end

  attributes do
    uuid_primary_key(:id)
    attribute(:not_encrypted, :string, public?: true)
    attribute(:encrypted, :integer, public?: true)
  end
end
