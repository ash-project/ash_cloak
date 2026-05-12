# SPDX-FileCopyrightText: 2024 ash_cloak contributors <https://github.com/ash-project/ash_cloak/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshCloak.Changes.Encrypt do
  @moduledoc "Takes an argument, and encrypts it into an attribute called `encrypted_{attribute}`"
  use Ash.Resource.Change

  def change(changeset, opts, context) do
    Ash.Changeset.before_action(changeset, fn changeset ->
      attribute = opts[:field]
      # Refresh source_context from the changeset at hook-run time, not at change/3 call time.
      # for_create/for_update runs changes immediately, before callers can set_context.
      current_context = %{context | source_context: changeset.context}

      case Ash.Changeset.fetch_argument(changeset, attribute) do
        {:ok, value} ->
          AshCloak.encrypt_and_set(changeset, attribute, value, current_context)

        :error ->
          changeset
      end
    end)
  end

  def atomic(changeset, opts, context) do
    attribute = opts[:field]
    current_context = %{context | source_context: changeset.context}

    case Ash.Changeset.fetch_argument(changeset, attribute) do
      {:ok, value} ->
        encryption_target = String.to_existing_atom("encrypted_#{attribute}")
        {:atomic, %{encryption_target => AshCloak.do_encrypt(changeset.resource, value, current_context)}}

      :error ->
        {:ok, changeset}
    end
  end
end
