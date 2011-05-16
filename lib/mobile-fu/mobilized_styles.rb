module MobileFu
  module MobilizedStyles

    # This logic was taken from Michael Bleigh's browserized styles
    # with modification to work for mobile browsers.

    def device_name
      @device_name ||= request.headers['X_MOBILE_DEVICE']
    end

    def stylesheet_link_tag_with_mobilization(*sources)
      mobilized_sources = Array.new
      sources.each do |source|
        mobilized_sources << source

        path = File.join config.stylesheets_dir, "#{source.to_s.gsub '.css', ''}_#{device_name}.css"
        mobilized_sources << possible_source if File.exist?(path)
      end

      stylesheet_link_tag *mobilized_sources
    end
  end
end

ActionView::Base.send :include, MobileFu::MobilizedStyles
ActionView::Base.send :alias_method_chain, :stylesheet_link_tag, :mobilization
