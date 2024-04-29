defmodule Vector.Consumer.LoggerTest do
  use ExUnit.Case

  alias Vector.Consumer.Logger

  describe "parse_stderr/2" do
    test "will correctly parse multiple logs" do
      line1 = "2024-01-01T00:00:00.000000Z ERROR foo\n"
      line2 = "2024-01-01T00:00:00.000000Z  INFO bar\n"
      raw = to_string([line1, line2])
      logs = Logger.parse_stderr(raw)

      assert logs == [{:error, "foo"}, {:info, "bar"}]
    end

    test "will correctly parse logs with newlines" do
      line1 = "2024-01-01T00:00:00.000000Z DEBUG foo\n"
      line2 = "2024-01-01T00:00:00.000000Z  INFO bar\nbaz\n\nqux\n"
      line3 = "2024-01-01T00:00:00.000000Z  INFO quxx\n\n"
      raw = to_string([line1, line2, line3])
      logs = Logger.parse_stderr(raw)

      assert logs == [{:debug, "foo"}, {:info, "bar baz qux"}, {:info, "quxx"}]
    end
  end
end
