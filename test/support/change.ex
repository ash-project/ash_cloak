# SPDX-FileCopyrightText: 2020 Zach Daniel
#
# SPDX-License-Identifier: MIT

defmodule AshCloak.Test.Change do
  @moduledoc false
  use Ash.Resource.Change

  def change(changeset, _opts, _) do
    changeset |> Ash.Changeset.set_argument(:encrypted, 13)
  end
end
