require 'recaptcha/configuration'
require 'recaptcha/client_helper'
require 'recaptcha/verify'

module RecaptchaV1
  class MissingPrivateKeyError < StandardError; end

  class Configuration
    RECAPTCHA_API_SERVER_URL = 'http://www.google.com/recaptcha/api'
    RECAPTCHA_API_SECURE_SERVER_URL = 'https://www.google.com/recaptcha/api'
    RECAPTCHA_API_VERIFY_URL = 'http://www.google.com/recaptcha/api/verify'

    attr_accessor :handle_timeouts_gracefully
    attr_accessor :use_ssl
    attr_accessor :private_key
    attr_accessor :proxy_server
    attr_accessor :proxy_server_username
    attr_accessor :proxy_server_password

    def reset
      @handle_timeouts_gracefully = true
      @use_ssl = false
    end

    def validate!
      raise MissingPrivateKeyError, "The private key is missing." if @private_key.nil?
    end
  end

  class Recaptcha
    class << self
      def verify(challenge: '', response: '')
        true
      end

      def config
        @config ||= Configuration.new
      end

      def setup(&block)
        yield self.config if block_given?
      end
    end
  end

  class HTTPClient
    # Here, you'll decide if you'll be using a proxy or not
    def initialize(private_key: '', timeout: 3, challenge: '', response: '')
      @private_key = private_key
      @timeout = timeout
      @challenge = challenge
      @response = response
    end

    def validate_recaptcha
    end
  end
end

module Recaptcha
  RECAPTCHA_API_SERVER_URL        = '//www.google.com/recaptcha/api'
  RECAPTCHA_API_SECURE_SERVER_URL = 'https://www.google.com/recaptcha/api'
  RECAPTCHA_VERIFY_URL            = 'http://www.google.com/recaptcha/api/verify'
  USE_SSL_BY_DEFAULT              = false

  HANDLE_TIMEOUTS_GRACEFULLY      = true
  SKIP_VERIFY_ENV = ['test', 'cucumber']

  # Gives access to the current Configuration.
  def self.configuration
    @configuration ||= Configuration.new
  end

  # Allows easy setting of multiple configuration options. See Configuration
  # for all available options.
  #--
  # The temp assignment is only used to get a nicer rdoc. Feel free to remove
  # this hack.
  #++
  def self.configure
    config = configuration
    yield(config)
  end

  def self.with_configuration(config)
    original_config = {}

    config.each do |key, value|
      original_config[key] = configuration.send(key)
      configuration.send("#{key}=", value)
    end

    result = yield if block_given?

    original_config.each { |key, value| configuration.send("#{key}=", value) }
    result
  end

  class RecaptchaError < StandardError
  end

  class VerifyError < RecaptchaError
  end

end

if defined?(Rails)
  require 'recaptcha/rails'
end
