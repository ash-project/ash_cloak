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
end
