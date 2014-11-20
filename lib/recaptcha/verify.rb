require "uri"
module Recaptcha
  module Verify
    # Your private API can be specified in the +options+ hash or preferably
    # using the Configuration.
    def verify_recaptcha(options = {})
      options = {:model => options} unless options.is_a? Hash

      #= --- obsolete ---
      env = options[:env] || ENV['RAILS_ENV']
      return true if Recaptcha.configuration.skip_verify_env.include? env # This can be taken care of by a partial double
      #= --- obsolete ---

      # e.g. in RSpec, allow(Recaptcha).to receive(:verify) { true }
      # so this logic is obsolete
      model = options[:model]
      attribute = options[:attribute] || :base

      #= --- obsolete ---
      private_key = options[:private_key] || Recaptcha.configuration.private_key # this is the responsibility of the config object
      # perhaps have a validate! method on the config to ensure we have a private key
      raise RecaptchaError, "No private key specified." unless private_key
      #= --- obsolete ---

      begin
        recaptcha = nil # the response from the http client
        # Rather than doing this, wrap the logic of choosing a proxy or not inside an HTTPClient class
        if Recaptcha.configuration.proxy
          proxy_server = URI.parse(Recaptcha.configuration.proxy) # Need a proxy address
          http = Net::HTTP::Proxy(proxy_server.host, proxy_server.port, proxy_server.user, proxy_server.password)
        else
          http = Net::HTTP
        end

        # This timeout logic should also be inside the HTTPClient class
        Timeout::timeout(options[:timeout] || 3) do
          recaptcha = http.post_form(URI.parse(Recaptcha.configuration.verify_url), {
            "privatekey" => private_key,
            "remoteip"   => request.remote_ip,
            "challenge"  => params[:recaptcha_challenge_field],
            "response"   => params[:recaptcha_response_field]
          })
        end

        answer, error = recaptcha.body.split.map { |s| s.chomp } # This is what the client should spit back to us

        unless answer == 'true'
          flash[:recaptcha_error] = if defined?(I18n) # If we are using Recaptcha in Rails, have a specialized object to do the Railsy things it needs to do: set flash messages, add errors to the model, do i18n of error messages, etc.
            I18n.translate("recaptcha.errors.#{error}", {:default => error})
          else
            error
          end if request_in_html_format?

          if model
            message = "Word verification response is incorrect, please try again."
            message = I18n.translate('recaptcha.errors.verification_failed', {:default => message}) if defined?(I18n)
            model.errors.add attribute, options[:message] || message
          end
          return false
        else
          flash.delete(:recaptcha_error)
          return true
        end
      rescue Timeout::Error
        if Recaptcha.configuration.handle_timeouts_gracefully
          flash[:recaptcha_error] = if defined?(I18n)
            I18n.translate('recaptcha.errors.recaptcha_unreachable', {:default => 'Recaptcha unreachable.'})
          else
            'Recaptcha unreachable.'
          end

          if model
            message = "Oops, we failed to validate your word verification response. Please try again."
            message = I18n.translate('recaptcha.errors.recaptcha_unreachable', :default => message) if defined?(I18n)
            model.errors.add attribute, options[:message] || message
          end
          return false
        else
          raise RecaptchaError, "Recaptcha unreachable."
        end
      rescue Exception => e
        raise RecaptchaError, e.message, e.backtrace
      end
    end # verify_recaptcha

    def request_in_html_format?
      request.format == :html
    end
    def verify_recaptcha!(options = {})
      verify_recaptcha(options) or raise VerifyError
    end #verify_recaptcha!
  end # Verify
end # Recaptcha
