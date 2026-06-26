<!--
SPDX-FileCopyrightText: 2020 Zach Daniel

SPDX-License-Identifier: MIT
-->

# How does AshCloak work?

## Rewrite attributes to calculations

First, AshCloak changes the name of each cloaked attribute to `encrypted_<name>`, and sets `public?: false` and `sensitive?: true`.

Then it adds a _calculation_ matching the original attribute that, when loaded, will decrypt the given attribute and call any configured `on_decrypt` callbacks.

## Modify Actions

AshCloak then goes through each action that accepts the attribute and removes the attribute from the accept list.

Then it adds an argument by the same name, and a `change` that encrypts the attribute value.

This `change` also deletes the argument from the arguments list and from the params. This is a small extra layer of security to prevent accidental leakage of the value.

## Add `preparation` and `change`

Finally, it add a `preparation` and a `change` that will automatically load the corresponding calculations for any attribute in the `decrypt_by_default` list.

## Nil handling

By default (`encrypt_nil?: true`), a `nil` value is encrypted like any other value, so the backing `encrypted_*` column holds a non-null ciphertext. This hides whether the attribute has a value at all, but means `encrypted_<name> IS NOT NULL` is always true.

Set `encrypt_nil?: false` to store `nil` as SQL `NULL` in the backing column instead. This keeps `IS NOT NULL` queries meaningful for nullable attributes — useful for cleanup, backfill, and debugging without decrypting every row. On read, the decrypt calculation maps a `NULL` backing value back to `nil`, so the round-trip is unchanged. This option is intended for nullable attributes; assigning `nil` to a non-nullable attribute (for example, via an update) will surface the usual required-value error.

## The result

The cloaked attribute will now seamlessly encrypt when writing and decrypt on request.
