require 'rails'
require 'rack/mobile-detect'

module MobileFu
  autoload :Helper, 'mobile-fu/helper'
  autoload :MobilizedStyles, 'mobile-fu/mobilized_styles'

  class Railtie < Rails::Railtie
    initializer "mobile-fu.configure" do |app|
      app.config.middleware.use Rack::MobileDetect
    end
    Mime::Type.register_alias "text/html", :mobile
  end
end

module ActionController
  module MobileFu

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods

      # Add this to one of your controllers to use MobileFu.
      #
      #    class ApplicationController < ActionController::Base
      #      has_mobile_fu
      #    end
      #
      # You can also force mobile mode by passing in 'true'
      #
      #    class ApplicationController < ActionController::Base
      #      has_mobile_fu true
      #    end

      def has_mobile_fu(test_mode = nil, &test_mode_block)
        include ActionController::MobileFu::InstanceMethods
        @@test_mode = test_mode || block
        before_filter :set_device_type
        
        helper_method :is_mobile_device?
        helper_method :in_mobile_view?
        helper_method :is_device?
        helper_method :mobile_device
      end

      def is_mobile_device?
        @@is_mobile_device
      end

      def in_mobile_view?
        @@in_mobile_view
      end

      def is_device?(type)
        @@is_device
      end
    end

    module InstanceMethods

      def set_device_type
        # see if we want to force mobile
        force_mobile = if @@test_mode.is_a?(Proc)
          @@test_mode.call
        elsif (@@test_mode.is_a?(String) || @@test_mode.is_a?(Symbol)) && self.respond_to?(@@test_mode)
          self.send(@@test_mode)
        else
          @@test_mode
        end
      end

      # Forces the request format to be :mobile
      def force_mobile_format
        unless request.xhr?
          request.format = :mobile
          session[:mobile_view] = true if session[:mobile_view].nil?
        end
      end

      # Determines the request format based on whether the device is mobile or if
      # the user has opted to use either the 'Standard' view or 'Mobile' view.

      def set_mobile_format
        if is_mobile_device? && !request.xhr?
          request.format = session[:mobile_view] == false ? :html : :mobile
          session[:mobile_view] = true if session[:mobile_view].nil?
        end
      end

      # Returns either true or false depending on whether or not the format of the
      # request is either :mobile or not.

      def in_mobile_view?
        request.format.to_sym == :mobile
      end

      # Returns either true or false depending on whether or not the user agent of
      # the device making the request is matched to a device in our regex.

      def is_mobile_device?
        !!mobile_device
      end

      def mobile_device
        request.headers['X_MOBILE_DEVICE']
      end

      # Can check for a specific user agent
      # e.g., is_device?('iphone') or is_device?('mobileexplorer')

      def is_device?(type)
        request.user_agent.to_s.downcase.include? type.to_s.downcase
      end
    end

  end

end

ActionController::Base.send :include, ActionController::MobileFu
