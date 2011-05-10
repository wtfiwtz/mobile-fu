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

      def has_mobile_fu(test_mode = nil)
        raise ArgumentError, "test_mode argument to has_mobile_fu is no longer supported, please invoke set_device_type as or in a before_filter instead" unless test_mode.nil?
        include ActionController::MobileFu::InstanceMethods
        
        helper_method :is_mobile_device?
        helper_method :in_mobile_view?
        helper_method :is_device?
        helper_method :mobile_device
      end
    end

    module InstanceMethods
      def set_device_type(force_mobile = false)
        force_mobile ? force_mobile_format : set_mobile_format
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
