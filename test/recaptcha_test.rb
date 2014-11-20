require 'minitest/autorun'
require 'cgi'
require File.dirname(File.expand_path(__FILE__)) + '/../lib/recaptcha'

class HTTPClientTest < Minitest::Test
  include RecaptchaV1

  def setup
    @client = HTTPClient.new
  end

  def test_client_is_not_nil
    assert !@client.nil?
  end
end

class RecaptchaConfigTest < Minitest::Test
  include RecaptchaV1

  def setup
    Recaptcha.config.reset
  end

  def test_handles_timeouts_gracefully_by_default
    assert Recaptcha.config.handle_timeouts_gracefully
  end

  def test_doesnt_use_ssl_by_default
    refute Recaptcha.config.use_ssl
  end

  def test_can_override_defaults
    Recaptcha.setup do |config|
      config.handle_timeouts_gracefully = false
      config.use_ssl = true
    end

    refute Recaptcha.config.handle_timeouts_gracefully
    assert Recaptcha.config.use_ssl
  end
end

class RecaptchaTest < Minitest::Test
  include RecaptchaV1

  def setup
  end

  def test_verify_returns_true
    assert Recaptcha.verify
  end
end

class RecaptchaClientHelperTest < Minitest::Test
  include Recaptcha
  include Recaptcha::ClientHelper
  include Recaptcha::Verify

  attr_accessor :session

  def setup
    @session = {}
    Recaptcha.configure do |config|
      config.public_key = '0000000000000000000000000000000000000000'
      config.private_key = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
    end
  end

  def test_recaptcha_tags
    # Might as well match something...
    skip
    assert_match /"\/\/www.google.com\/recaptcha\/api\/challenge/, recaptcha_tags
  end

  def test_ssl_by_default
    Recaptcha.configuration.use_ssl_by_default = true
    assert_match /https:\/\/www.google.com\/recaptcha\/api\/challenge/, recaptcha_tags
  end

  def test_relative_protocol_by_default_without_ssl
    Recaptcha.configuration.use_ssl_by_default = false
    assert_match /\/\/www.google.com\/recaptcha\/api\/challenge/, recaptcha_tags(:ssl => false)
  end

  def test_recaptcha_tags_with_ssl
    assert_match /https:\/\/www.google.com\/recaptcha\/api\/challenge/, recaptcha_tags(:ssl => true)
  end

  def test_recaptcha_tags_without_noscript
    refute_match /noscript/, recaptcha_tags(:noscript => false)
  end

  def test_should_raise_exception_without_public_key
    assert_raises RecaptchaError do
      Recaptcha.configuration.public_key = nil
      recaptcha_tags
    end
  end

  def test_different_configuration_within_with_configuration_block
    key = Recaptcha.with_configuration(:public_key => '12345') do
      Recaptcha.configuration.public_key
    end

    assert_equal('12345', key)
  end

  def test_reset_configuration_after_with_configuration_block
    Recaptcha.with_configuration(:public_key => '12345')
    assert_equal('0000000000000000000000000000000000000000', Recaptcha.configuration.public_key)
  end
end
