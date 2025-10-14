# SPDX-FileCopyrightText: 2024 ash_cloak contributors <https://github.com/ash-project/ash_cloak/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshCloak.Test.Change do
  @moduledoc false
  use Ash.Resource.Change

  def change(changeset, _opts, _) do
    changeset |> Ash.Changeset.set_argument(:encrypted, 13)
  end
end
