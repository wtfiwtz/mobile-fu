module MobileFu
  module Helper
    def js_enabled_mobile_device?
      is_device?('iphone') || is_device?('ipod') || is_device?('ipad') || is_device?('mobileexplorer') || is_device?('android')
    end

    def stylesheet_link_tag_with_mobilization(*sources)
      mobilized_sources = Array.new
      sources.each do |source|
        mobilized_sources << source

        possible_source = "#{source.to_s.gsub '.css', ''}_#{mobile_device}.css"
        path = File.join config.stylesheets_dir, possible_source
        mobilized_sources << possible_source if File.exist?(path)
      end

      stylesheet_link_tag_without_mobilization *mobilized_sources
    end
  end
end
