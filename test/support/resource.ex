defmodule AshCloak.Test.Resource do
  @moduledoc false

  use Ash.Resource,
    domain: AshCloak.Test.Domain,
    data_layer: Ash.DataLayer.Ets,
    extensions: [AshCloak]

  ets do
    private?(true)
  end

  @attributes [:encrypted, :encrypted_always_loaded, :encrypted_with_default, :not_encrypted]
  actions do
    defaults([:read, :destroy, create: @attributes, update: @attributes])

    create :change_before_encrypt do
      accept(@attributes)
      change(AshCloak.Test.Change)
    end

    create :change_without_accept do
      change(AshCloak.Test.Change)
    end
  end

  cloak do
    vault(AshCloak.Test.Vault)
    attributes([:encrypted, :encrypted_always_loaded, :encrypted_with_default])
    decrypt_by_default([:encrypted_always_loaded, :encrypted_with_default])

    on_decrypt(fn resource, records, field, context ->
      send(self(), {:decrypting, resource, records, field, context})

      if Enum.any?(records, &(&1.not_encrypted == "dont allow decryption")) do
        {:error, "can't do it dude"}
      else
        :ok
      end
    end)
  end

  attributes do
    uuid_primary_key(:id)
    attribute(:not_encrypted, :string)
    attribute(:encrypted, :integer, public?: true)
    attribute(:encrypted_always_loaded, :map, public?: true)
    attribute(:encrypted_with_default, :integer, default: 42, allow_nil?: false, public?: true)
  end
end
