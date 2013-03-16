require 'rails'
require 'rack/mobile-detect'

module MobileFu
  autoload :Helper, 'mobile-fu/helper'

  class Railtie < Rails::Railtie
    initializer "mobile-fu.configure" do |app|
      app.config.middleware.use Rack::MobileDetect
    end

    if Rails::VERSION::MAJOR >= 3
      initializer "mobile-fu.action_controller" do |app|
        ActiveSupport.on_load :action_controller do
          include ActionController::MobileFu
        end
      end

      initializer "mobile-fu.action_view" do |app|
        ActiveSupport.on_load :action_view do
          include MobileFu::Helper
          alias_method_chain :stylesheet_link_tag, :mobilization
        end
      end
    end

    Mime::Type.register_alias "text/html", :mobile
    Mime::Type.register_alias "text/html", :tablet
  end
end

module ActionController
  module MobileFu
    # These are various strings that can be found in tablet devices.  Please feel free
    # to add on to this list.
    TABLET_USER_AGENTS =  /ipad|android 3.0|xoom|sch-i800|gt-p1000|playbook|tablet|kindle|honeycomb|nexus 7/.freeze

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
      # If you don't want mobile_fu to set the request format automatically,
      # you can pass false here.
      #
      #    class ApplicationController < ActionController::Base
      #      has_mobile_fu false
      #    end
      #
      def has_mobile_fu(set_request_format = true)
        include ActionController::MobileFu::InstanceMethods

        before_filter :set_request_format if set_request_format

        helper_method :is_mobile_device?
        helper_method :is_tablet_device?
        helper_method :in_mobile_view?
        helper_method :in_tablet_view?
        helper_method :is_device?
        helper_method :mobile_device
      end

      # Add this to your controllers to prevent the mobile format from being set for specific actions
      #   class AwesomeController < ApplicationController
      #     has_no_mobile_fu_for :index
      #
      #     def index
      #       # Mobile format will not be set, even if user is on a mobile device
      #     end
      #
      #     def show
      #       # Mobile format will be set as normal here if user is on a mobile device
      #     end
      #   end
      def has_no_mobile_fu_for(*actions)
        @mobile_exempt_actions = actions
      end
    end

    module InstanceMethods
      def set_request_format(force_mobile = false)
        force_mobile ? force_mobile_format : set_mobile_format
      end
      alias :set_device_type :set_request_format

      # Forces the request format to be :mobile
      def force_mobile_format
        unless request.xhr?
          request.format = :mobile
          session[:mobile_view] = true if session[:mobile_view].nil?
        end
      end

      # Forces the request format to be :tablet
      def force_tablet_format
        unless request.xhr?
          request.format = :tablet
          session[:tablet_view] = true if session[:tablet_view].nil?
        end
      end

      # Determines the request format based on whether the device is mobile or if
      # the user has opted to use either the 'Standard' view or 'Mobile' view or
      # 'Tablet' view.

      def set_mobile_format
        if request.format.html? && !mobile_exempt? && is_mobile_device? && !request.xhr?
          request.format = :mobile unless session[:mobile_view] == false
          session[:mobile_view] = true if session[:mobile_view].nil?
        elsif request.format.html? && !mobile_exempt? && is_tablet_device? && !request.xhr?
          request.format = :tablet unless session[:tablet_view] == false
          session[:tablet_view] = true if session[:tablet_view].nil?
        end
      end

      # Returns either true or false depending on whether or not the format of the
      # request is either :mobile or not.

      def in_mobile_view?
        return false unless request.format
        request.format.to_sym == :mobile
      end

      # Returns either true or false depending on whether or not the format of the
      # request is either :tablet or not.

      def in_tablet_view?
        return false unless request.format
        request.format.to_sym == :tablet
      end

      # Returns either true or false depending on whether or not the user agent of
      # the device making the request is matched to a device in our regex.

      def is_tablet_device?
        !!(request.user_agent.to_s.downcase =~ ActionController::MobileFu::TABLET_USER_AGENTS)
      end

      def is_mobile_device?
        !is_tablet_device? && !!mobile_device
      end

      def mobile_device
        request.headers['X_MOBILE_DEVICE']
      end

      # Can check for a specific user agent
      # e.g., is_device?('iphone') or is_device?('mobileexplorer')

      def is_device?(type)
        request.user_agent.to_s.downcase.include? type.to_s.downcase
      end

      # Returns true if current action isn't supposed to use mobile format
      # See #has_no_mobile_fu_for

      def mobile_exempt?
        self.class.instance_variable_get("@mobile_exempt_actions").try(:include?, params[:action].to_sym)
      end
    end
  end
end

# the following code are obtained from https://github.com/cannikin/format_fallback
module ActionView
  class PathSet
    def find_with_default_template(path, prefix = nil, partial = false, details = {}, keys = [], key = nil)
      if prefix == "layouts"
        # Layouts have their own way of managing fallback, better leave them alone
        find_without_default_template(path, prefix, partial, details, keys, key)
      else
        begin
          find_without_default_template(path, prefix, partial, details, keys, key)
        rescue MissingTemplate => e
          raise e if details[:formats] == [:html]
          html_details = details.dup.merge(:formats => [:html])
          find_without_default_template(path, prefix, partial, html_details, keys, key)
        end
      end
    end
    alias_method_chain :find, :default_template
  end

  class Resolver
    
    def cached(key, path_info, details, locals) #:nodoc:
      name, prefix, partial = path_info
      locals = locals.map { |x| x.to_s }.sort!

      if key && caching?
        if @cached[key][name][prefix][partial][locals].nil?
          fresh = decorate(yield, path_info, details, locals)
          return [] if fresh.empty?
        end
        @cached[key][name][prefix][partial][locals] ||= fresh

      else
        fresh = decorate(yield, path_info, details, locals)
        return fresh unless key

        scope = @cached[key][name][prefix][partial]
        cache = scope[locals]
        mtime = cache && cache.map(&:updated_at).max

        if !mtime || fresh.empty?  || fresh.any? { |t| t.updated_at > mtime }
          scope[locals] = fresh
        else
          cache
        end
      end
    end

  end 


end
# end of code obtained from https://github.com/cannikin/format_fallback

if Rails::VERSION::MAJOR < 3
  ActionController::Base.send :include, ActionController::MobileFu
  ActionView::Base.send :include, MobileFu::Helper
  ActionView::Base.send :alias_method_chain, :stylesheet_link_tag, :mobilization
end
