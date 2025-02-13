defmodule AshCloak.Changes.Encrypt do
  @moduledoc "Takes an argument, and encrypts it into an attribute called `encrypted_{attribute}`"
  use Ash.Resource.Change

  def change(changeset, opts, _) do
    Ash.Changeset.before_action(changeset, fn changeset ->
      attribute = opts[:field]

      case Ash.Changeset.fetch_argument(changeset, attribute) do
        {:ok, value} ->
          AshCloak.encrypt_and_set(changeset, attribute, value)

        :error ->
          changeset
      end
    end)
  end

  def atomic(changeset, opts, _) do
    attribute = opts[:field]

    case Ash.Changeset.fetch_argument(changeset, attribute) do
      {:ok, value} ->
        encryption_target = String.to_existing_atom("encrypted_#{attribute}")
        {:atomic, %{encryption_target => AshCloak.do_encrypt(changeset.resource, value)}}

      :error ->
        {:ok, changeset}
    end
  end
end
