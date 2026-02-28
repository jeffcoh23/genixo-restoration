require "test_helper"

class PhoneFormattingTest < ActiveSupport::TestCase
  include PhoneFormatting

  test "formats 10-digit number" do
    assert_equal "(203) 218-0897", format_phone("2032180897")
  end

  test "formats number with existing formatting" do
    assert_equal "(203) 218-0897", format_phone("203-218-0897")
  end

  test "returns non-10-digit numbers unchanged" do
    assert_equal "12345", format_phone("12345")
  end

  test "returns nil for nil" do
    assert_nil format_phone(nil)
  end

  test "returns blank for blank" do
    assert_equal "", format_phone("")
  end
end
