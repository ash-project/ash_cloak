# SPDX-FileCopyrightText: 2024 ash_cloak contributors <https://github.com/ash-project/ash_cloak/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshCloak.Test.NilResource do
  @moduledoc false

  use Ash.Resource,
    domain: AshCloak.Test.Domain,
    data_layer: Ash.DataLayer.Ets,
    extensions: [AshCloak]

  ets do
    private?(true)
  end

  @attributes [:encrypted, :not_encrypted]
  actions do
    defaults([:read, :destroy, create: @attributes, update: @attributes])
  end

  cloak do
    vault(AshCloak.Test.Vault)
    attributes([:encrypted])
    encrypt_nil?(false)
  end

  attributes do
    uuid_primary_key(:id)
    attribute(:not_encrypted, :string)
    # nullable (allow_nil? defaults to true) so a nil value can be stored as SQL NULL
    attribute(:encrypted, :integer, public?: true)
  end
end
