# Get Started with AshCloak

## Installation

Add `ash_cloak` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ash_cloak, "~> 0.1.0-rc.0"}
  ]
end
```

Follow [the cloak getting started guide](https://hexdocs.pm/cloak/readme.html).

Technically, you just need a module that implements `encrypt!` and `decrypt!`, but we recommend using `Cloak` to achieve that goal.

### Add the extension to your resource(s):

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

## What does the extension do?

### Rewrite attributes to calculations

First, we change the name of each attribute in question to `encrypted_<name>`, and make it `public?: false` and `sensitive?: true`.

Then, we add a _calculation_ matching the original attribute that, when loaded, will decrypt the given attribute and calls any configured `on_decrypt` callback.

### Modify Actions

Then, we go through each create, udpate and destroy action that accepts the attribute, and remove the attribute from the accept list.

Then, we add an argument by the same name, and a change that encrypts the attribute value.

This change also deletes the argument from the arguments list and from the params. This is a small extra layer of security to prevent accidental leakage of the value.

## Add preparation & change

Finally, we add a preparation and a change that will automatically load the corresponding calculations for any attribute in the `decrypt_by_default` list.
