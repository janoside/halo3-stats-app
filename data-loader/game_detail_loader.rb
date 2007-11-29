require 'rubygems'
require 'open-uri'
require 'hpricot'

BASE_PAGE_DETAIL_URL = "http://www.bungie.net/stats/gamestatshalo3.aspx?gameid="
@response = ''

def save_unloaded_games()
  bungie_ids = get_unloaded_games()
  
  bungie_ids.each do |bungie_id|
    save_game_detail(bungie_id)
  end
end

def get_unloaded_games()
  bungie_ids = []
  $adapter.query("select bungie_id from games where loaded=0 limit 5") {|results|
    puts "Found #{results.num_rows()} Unloaded Games."
    results.each do |bungie_id|
      bungie_ids << bungie_id[0].to_i
    end
  }
  
  return bungie_ids
end

def save_game_detail(bungie_game_id)
  begin
    # open-uri RDoc: http://stdlib.rubyonrails.org/libdoc/open-uri/rdoc/index.html
    open(BASE_PAGE_DETAIL_URL + bungie_game_id.to_s, "User-Agent" => "Ruby/#{RUBY_VERSION}") { |f|
      # Save the response body
      @response = f.read
    }

    # HPricot RDoc: http://code.whytheluckystiff.net/hpricot/
    doc = Hpricot(@response)
    
    # Retrive number of comments
    playlist_str = (doc/"/html/body/div[2]/form/div[3]/div[2]/div[2]/div/div/div[3]/div/ul/li[4]").inner_html.to_s

    if ( !playlist_str.nil? )
      playlist_str = playlist_str[playlist_str.index('-') + 2, 20]
      
      puts playlist_str
    end

  rescue Exception => e
    exception(e)
  end
end