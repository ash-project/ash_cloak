# SPDX-FileCopyrightText: 2024 ash_cloak contributors <https://github.com/ash-project/ash_cloak/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshCloak.Test.VaultSelector do
  @moduledoc false
  def select(_resource, nil), do: AshCloak.Test.Vault

  def select(_resource, context) do
    case Map.get(context, :source_context, %{}) do
      %{test_vault: :alt} -> AshCloak.Test.AltVault
      _ -> AshCloak.Test.Vault
    end
  end
end

defmodule AshCloak.Test.ResourceWithSelector do
  @moduledoc false

  use Ash.Resource,
    domain: AshCloak.Test.Domain,
    data_layer: Ash.DataLayer.Ets,
    extensions: [AshCloak]

  ets do
    private?(true)
  end

  actions do
    defaults([:read, :destroy, create: [:encrypted], update: [:encrypted]])
  end

  cloak do
    vault({AshCloak.Test.VaultSelector, :select, []})
    attributes([:encrypted])
  end

  attributes do
    uuid_primary_key(:id)
    attribute(:encrypted, :integer, public?: true)
  end
end
