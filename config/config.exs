# SPDX-FileCopyrightText: 2020 Zach Daniel
#
# SPDX-License-Identifier: MIT

import Config

config :ash, :disable_async?, true
config :ash, :validate_domain_resource_inclusion?, false
config :ash, :validate_domain_config_inclusion?, false
config :ash, :keep_read_action_loads_when_loading?, false

if Mix.env() == :dev do
  config :git_ops,
    mix_project: AshCloak.MixProject,
    changelog_file: "CHANGELOG.md",
    repository_url: "https://github.com/ash-project/ash_cloak",
    # Instructs the tool to manage your mix version in your `mix.exs` file
    # See below for more information
    manage_mix_version?: true,
    # Instructs the tool to manage the version in your README.md
    # Pass in `true` to use `"README.md"` or a string to customize
    manage_readme_version: [
      "README.md",
      "documentation/tutorials/getting-started-with-ash-cloak.md"
    ],
    version_tag_prefix: "v"
end
