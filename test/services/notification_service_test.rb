require "test_helper"
require "minitest/mock"

class NotificationServiceTest < ActiveSupport::TestCase
  test "send_voice logs when Twilio is not configured" do
    # With no TwilioClient defined in test, it should just log
    assert_nothing_raised do
      NotificationService.send_voice(to: "555-123-4567", message: "Emergency test")
    end
  end

  test "send_voice calls Twilio with correct TwiML when configured" do
    created_args = nil
    mock_calls = Object.new
    mock_calls.define_singleton_method(:create) { |**kwargs| created_args = kwargs }

    mock_client = Object.new
    mock_client.define_singleton_method(:calls) { mock_calls }

    with_twilio_client(mock_client) do
      with_env("TWILIO_PHONE_NUMBER" => "+15075433639") do
        NotificationService.send_voice(to: "555-123-4567", message: "Emergency test")
      end
    end

    assert_not_nil created_args, "Expected Twilio call to be made"
    assert_equal "+15551234567", created_args[:to]
    assert_equal "+15075433639", created_args[:from]
    assert_includes created_args[:twiml], "<Say"
    assert_includes created_args[:twiml], "Emergency test"
  end

  test "send_voice does not raise on API failure" do
    error_calls = Object.new
    error_calls.define_singleton_method(:create) { |**_| raise Twilio::REST::TwilioError, "API down" }

    mock_client = Object.new
    mock_client.define_singleton_method(:calls) { error_calls }

    with_twilio_client(mock_client) do
      assert_nothing_raised do
        NotificationService.send_voice(to: "555-123-4567", message: "Emergency test")
      end
    end
  end

  test "send_voice repeats message twice in TwiML" do
    created_args = nil
    mock_calls = Object.new
    mock_calls.define_singleton_method(:create) { |**kwargs| created_args = kwargs }

    mock_client = Object.new
    mock_client.define_singleton_method(:calls) { mock_calls }

    with_twilio_client(mock_client) do
      with_env("TWILIO_PHONE_NUMBER" => "+15075433639") do
        NotificationService.send_voice(to: "555-0001", message: "Emergency test")
      end
    end

    assert_equal 2, created_args[:twiml].scan("Emergency test").length
  end

  test "normalize_phone prepends +1 for 10-digit numbers" do
    assert_equal "+15551234567", NotificationService.send(:normalize_phone, "555-123-4567")
    assert_equal "+15551234567", NotificationService.send(:normalize_phone, "(555) 123-4567")
    assert_equal "+15551234567", NotificationService.send(:normalize_phone, "5551234567")
  end

  test "normalize_phone preserves country code for 11-digit numbers" do
    assert_equal "+15551234567", NotificationService.send(:normalize_phone, "15551234567")
    assert_equal "+15551234567", NotificationService.send(:normalize_phone, "+1 555 123 4567")
  end

  test "send_voice does not call Twilio in non-production environments" do
    # Even with TwilioClient defined and env vars set, dev/test should just log
    mock_calls = Object.new
    mock_calls.define_singleton_method(:create) { |**_| raise "Should not be called!" }

    mock_client = Object.new
    mock_client.define_singleton_method(:calls) { mock_calls }

    was_defined = Object.const_defined?(:TwilioClient)
    old_value = Object.const_get(:TwilioClient) if was_defined
    Object.send(:remove_const, :TwilioClient) if was_defined
    Object.const_set(:TwilioClient, mock_client)

    with_env("TWILIO_PHONE_NUMBER" => "+15075433639") do
      # Rails.env is "test" — should NOT call Twilio
      assert_nothing_raised do
        NotificationService.send_voice(to: "555-0001", message: "Should only log")
      end
    end
  ensure
    Object.send(:remove_const, :TwilioClient) if Object.const_defined?(:TwilioClient)
    Object.const_set(:TwilioClient, old_value) if was_defined
  end

  test "send_sms logs message without error" do
    assert_nothing_raised do
      NotificationService.send_sms(to: "555-0001", message: "Test SMS")
    end
  end

  private

  def with_env(vars)
    old_values = vars.map { |k, _| [ k, ENV[k] ] }.to_h
    vars.each { |k, v| ENV[k] = v }
    yield
  ensure
    old_values.each { |k, v| ENV[k] = v }
  end

  def with_twilio_client(mock_client)
    was_defined = Object.const_defined?(:TwilioClient)
    old_value = Object.const_get(:TwilioClient) if was_defined
    Object.send(:remove_const, :TwilioClient) if was_defined
    Object.const_set(:TwilioClient, mock_client)

    # Simulate production so twilio_configured? returns true
    Rails.env.stub(:production?, true) do
      yield
    end
  ensure
    Object.send(:remove_const, :TwilioClient) if Object.const_defined?(:TwilioClient)
    Object.const_set(:TwilioClient, old_value) if was_defined
  end
end
