# SPDX-FileCopyrightText: 2024 ash_cloak contributors <https://github.com/ash-project/ash_cloak/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshCloak.Test.ContainerResource do
  @moduledoc false

  use Ash.Resource,
    domain: AshCloak.Test.Domain,
    data_layer: Ash.DataLayer.Ets

  ets do
    private?(true)
  end

  actions do
    defaults([:read, :destroy, create: [:embedded], update: [:embedded]])
  end

  attributes do
    uuid_primary_key(:id)
    attribute(:embedded, AshCloak.Test.EmbeddedResource, public?: true)
  end
end
