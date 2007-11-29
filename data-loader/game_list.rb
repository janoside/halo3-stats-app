require 'rubygems'
require 'open-uri'
require 'hpricot'

BASE_PAGE_ID_URL = "http://www.bungie.net/stats/PlayerStatsHalo3.aspx?ctl00_mainContent_bnetpgl_recentgamesChangePage=XXX&player="
@response = ''

def get_game_ids(page, gamer_tag)
  begin
    # open-uri RDoc: http://stdlib.rubyonrails.org/libdoc/open-uri/rdoc/index.html
    open(BASE_PAGE_ID_URL.gsub('XXX', page.to_s) + gamer_tag.to_s, "User-Agent" => "Ruby/#{RUBY_VERSION}") { |f|
    
    # Save the response body
    @response = f.read
    }

    # HPricot RDoc: http://code.whytheluckystiff.net/hpricot/
    doc = Hpricot(@response)

    game_list = []

    for i in 1..25
      begin
        # Retrive number of comments
        page_string = ((i > 1) ? "[#{i.to_s}]" : '')
        str = (doc/"/html/body/div/form/div[3]/div[2]/div[2]/div/div/div/div[4]/div/div/div/table/tbody/tr#{page_string}/td").inner_html.to_s

        if ( !str.nil? )
          str = str[str.index('/Stats/GameStatsHalo3.aspx?') + '/Stats/GameStatsHalo3.aspx?'.length, 20]
          
          equal_index = str.index('=')
          str = str[equal_index + 1, str.index('&') - equal_index - 1]
      
          game_list << str.to_i
        end
      rescue Exception => e
      end
    end
    
		return game_list

	rescue Exception => e
	 exception(e)
		return []
  end
end