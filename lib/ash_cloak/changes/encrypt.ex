defmodule AshCloak.Changes.Encrypt do
  @moduledoc false
  use Ash.Resource.Change

  def change(changeset, opts, _) do
    Ash.Changeset.before_action(changeset, fn changeset ->
      attribute = opts[:field]

      case Ash.Changeset.fetch_argument(changeset, attribute) do
        {:ok, value} ->
          vault = AshCloak.Info.cloak_vault!(changeset.resource)
          encryption_target = String.to_existing_atom("encrypted_#{attribute}")

          encrypted_value =
            value
            |> :erlang.term_to_binary()
            |> vault.encrypt!()
            |> Base.encode64()

          changeset
          |> Ash.Changeset.force_change_attribute(encryption_target, encrypted_value)
          |> Ash.Changeset.delete_argument(attribute)
          |> Map.update!(:params, fn params ->
            Map.drop(params, [attribute, to_string(attribute)])
          end)

        :error ->
          changeset
      end
    end)
  end
end
