defmodule AshCloak do
  @moduledoc """
  An extension for encrypting attributes of a resource.

  See the getting started guide for more information.
  """

  @transformers [
    AshCloak.Transformers.SetupEncryption
  ]

  @cloak %Spark.Dsl.Section{
    name: :cloak,
    describe: "Encrypt attributes of a resource",
    schema: [
      vault: [
        type: {:behaviour, Cloak.Vault},
        doc: "The vault to use to encrypt & decrypt the value",
        required: true
      ],
      attributes: [
        type: {:wrap_list, :atom},
        default: [],
        doc:
          "The attribute or attributes to encrypt. The attribute will be renamed to `encrypted_{attribute}`, and a calculation with the same name will be added."
      ],
      decrypt_by_default: [
        type: {:wrap_list, :atom},
        default: [],
        doc:
          "A list of attributes that should be decrypted (their calculation should be loaded) by default."
      ],
      on_decrypt: [
        type: {:or, [{:fun, 4}, :mfa]},
        doc:
          "A function to call when decrypting any value. Takes the resource, field, records, and calculation context. Must return `:ok` or `{:error, error}`"
      ]
    ]
  }

  use Spark.Dsl.Extension, sections: [@cloak], transformers: @transformers

  @doc """
  Encrypts and writes to an encrypted attribute.

  If the changeset is pending (i.e not currently running the action), then it is added as a before_action hook.
  Otherwise, it is run immediately
  """
  @spec encrypt_and_set(Ash.Changeset.t(), attr :: atom, term :: term) :: Ash.Changeset.t()
  def encrypt_and_set(changeset, key, value) do
    if key in AshCloak.Info.cloak_attributes!(changeset.resource) do
      if changeset.phase == :pending do
        Ash.Changeset.before_action(changeset, &do_encrypt_and_set(&1, key, value))
      else
        do_encrypt_and_set(changeset, key, value)
      end
    else
      raise "Attempted to encrypt and set attribute #{inspect(key)} for resource #{inspect(changeset.resource)}, but it is not configured for encryption."
    end
  end

  defp do_encrypt_and_set(changeset, key, value) do
    vault = AshCloak.Info.cloak_vault!(changeset.resource)
    encryption_target = String.to_existing_atom("encrypted_#{key}")

    encrypted_value =
      value
      |> :erlang.term_to_binary()
      |> vault.encrypt!()
      |> Base.encode64()

    changeset
    |> Ash.Changeset.force_change_attribute(encryption_target, encrypted_value)
    |> Ash.Changeset.delete_argument(key)
    |> Map.update!(:params, fn params ->
      Map.drop(params, [key, to_string(key)])
    end)
  end
end
