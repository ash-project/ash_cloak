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
end
