# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def update_content(element_id, options = {})
    update_page do |page|
      page.replace_html(element_id, options[:content]) if options.has_key?(:content)
      if options.has_key?(:show)
        if options[:show]
          page.show(element_id)
        else
          page.hide(element_id)
        end
      end
      page.visual_effect(options[:effect], element_id) if options.has_key?(:effect)
      page.remove(element_id) if options.has_key?(:remove)
    end
  end
  
  def loading_tag(text = "Loading...")
    tag('img',
          :src   => '/images/indicator.gif',
          :alt   => 'loading-indicator',
          :class => 'loading-indicator'
       ) +
    '&nbsp;' + text
  end
end