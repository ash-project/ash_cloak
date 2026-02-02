# SPDX-FileCopyrightText: 2024 ash_cloak contributors <https://github.com/ash-project/ash_cloak/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshCloak.SetUpEncryptionTest do
  @moduledoc false

  @bad_fixtures_dir Application.app_dir(:ash_cloak, "priv/bad_fixtures")
  @bad_resource_file Path.join([@bad_fixtures_dir, "bad_resource.ex"])

  @external_resource @bad_resource_file

  use ExUnit.Case

  test "outputs the invalid attribute in the error message" do
    %Spark.Error.DslError{message: message} =
      assert_raise Spark.Error.DslError,
                   fn ->
                     Code.eval_file(@bad_resource_file)
                   end

    assert message =~ "No attribute called :huuge_typo_in_some_secret_lol"
  end
end
