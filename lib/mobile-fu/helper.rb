module MobileFu
  module Helper
    def js_enabled_mobile_device?
      is_device?('iphone') || is_device?('ipod') || is_device?('ipad') || is_device?('mobileexplorer') || is_device?('android')
    end
  end
end

ActionView::Base.send :include, MobileFu::Helper
