# Get Started with AshCloak

## Installation

Add `ash_cloak` to your list of dependencies in `mix.exs`:

```elixir
{:ash_cloak, "~> 0.1.0"}
```

Follow [the cloak getting started guide](https://hexdocs.pm/cloak/readme.html) to add `cloak` as a dependency, as AshCloak does not add a vault implementation for you. Note that you do not need `cloak_ecto` because your Ash data layer will take care of this.

Alternatively you could use your own vault module that implements `encrypt!` and `decrypt!`, but we recommend using `Cloak` to achieve that goal. See the [cloak vault guide](https://hexdocs.pm/cloak/install.html#create-a-vault)

### Add the `AshCloak` extension to your resource

```elixir
defmodule User do
  use Ash.Resource, extensions: [AshCloak]

  cloak do
    # the vault to use to encrypt them
    vault MyApp.Vault

    # the attributes to encrypt
    attributes [:address, :phone_number]
    
    # This is just equivalent to always providing `load: fields` on all calls
    decrypt_by_default [:address]
    
    # An MFA or function to be invoked beforce any decryption
    on_decrypt fn records, field, context ->
      # Ash has policies that allow forbidding certain users to load data.
      # You should generally use those for authorization rules, and
      # only use this callback for auditing/logging.
      Audit.user_accessed_encrypted_field(records, field, context)

      if context.user.name == "marty" do
        {:error, "No martys at the party!"}
      else
        :ok
      end
    end
  end
end
```
