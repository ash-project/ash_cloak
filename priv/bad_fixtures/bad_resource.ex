# SPDX-FileCopyrightText: 2024 ash_cloak contributors <https://github.com/ash-project/ash_cloak/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshCloak.Test.BadResource do
  @moduledoc false

  use Ash.Resource,
    domain: AshCloak.Test.Domain,
    data_layer: Ash.DataLayer.Ets,
    extensions: [AshCloak]

  actions do
    defaults([:read, :destroy, create: :*, update: :*])
  end

  attributes do
    uuid_primary_key(:id)

    attribute :some_secret, :string do
      allow_nil?(false)
      public?(false)
      sensitive?(true)
    end
  end

  cloak do
    vault AshCloak.Test.Vault

    attributes [:huuge_typo_in_some_secret_lol]
  end
end
