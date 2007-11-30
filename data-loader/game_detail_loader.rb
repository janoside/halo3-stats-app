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
  $adapter.query("select bungie_id from games where loaded=0 limit 1") {|results|
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
    puts "Game URL: #{BASE_PAGE_DETAIL_URL}#{bungie_game_id.to_s}"
    open(BASE_PAGE_DETAIL_URL + bungie_game_id.to_s, "User-Agent" => "Ruby/#{RUBY_VERSION}") { |f|
      # Save the response body
      @response = f.read
    }

    # HPricot RDoc: http://code.whytheluckystiff.net/hpricot/
    doc = Hpricot(@response)
    
    # Retrive number of comments
    playlist_str = (doc/"/html/body/div/form/div[3]/div[2]/div[2]/div/div/div[3]/div/ul/li[4]").inner_html.to_s
    if ( !playlist_str.nil? )
      playlist_str = playlist_str[playlist_str.index('-') + 2, playlist_str.index('&') - (playlist_str.index('-') + 2)]
      save_playlist(playlist_str)
    end
    save_playlist(playlist_str)
    
    time_str = (doc/"/html/body/div/form/div[3]/div[2]/div[2]/div/div/div[3]/div/ul/li[5]").inner_html.to_s
    if ( !time_str.nil? )
      time_str = time_str[0, time_str.index('&')]
      puts time_str.inspect
    end
    
    length_str = (doc/"/html/body/div/form/div[3]/div[2]/div[2]/div/div/div[3]/div/ul/li[6]").inner_html.to_s
    if ( !length_str.nil? )
      length_str = length_str['Length:'.length + 1, length_str.index('&') - ('Length:'.length + 1)]
      puts length_str.inspect
    end
    
    title_strs = []
    for i in 2..35
      title_str = (doc/"/html/body/div/form/div[3]/div[2]/div[2]/div/div/div[3]/div[2]/div[2]/div/div/div/div/div/div/table/tr[#{i.to_s}]/td/span").inner_html.to_s
      place_str = (doc/"/html/body/div/form/div[3]/div[2]/div[2]/div/div/div[3]/div[2]/div[2]/div/div/div/div/div/div/table/tr[#{i.to_s}]/td[2]").inner_html.to_s
      score_str = (doc/"/html/body/div/form/div[3]/div[2]/div[2]/div/div/div[3]/div[2]/div[2]/div/div/div/div/div/div/table/tr[#{i.to_s}]/td[3]").inner_html.to_s

      if ( title_str[0, 2] == '<a' )
        title_str = (doc/"/html/body/div/form/div[3]/div[2]/div[2]/div/div/div[3]/div[2]/div[2]/div/div/div/div/div/div/table/tr[#{i.to_s}]/td/span/a").inner_html.to_s
      end
      
      if ( !title_str.nil? )
        title_strs << {
          :str => title_str,
          :index => i,
          :place => place_str,
          :score => score_str
        }
      end
    end
    
    team = ''
    team_id = 0
    players = []
    place = ''
    
    title_strs.each do |dat|
      if ( dat[:str][dat[:str].length - ' Team'.length, ' Team'.length] == ' Team' )
        team = dat[:str][0, dat[:str].index(' ')]
        team_id = save_team(team)
        place = dat[:place]
      else
        if ( dat[:str].length > 0 )
          if ( dat[:place].to_s != '-' )
            place = dat[:place]
          end
          
          players << {
            :name => dat[:str],
            :team => team_id,
            :index => dat[:index],
            :place => place,
            :score => dat[:score]
          }
        end
      end
    end
    
    players.each do |player|
      kills_str     = (doc/"/html/body/div/form/div[3]/div[2]/div[2]/div/div/div[3]/div[2]/div[2]/div[3]/div/div/div/div/div/div/table/tr[#{player[:index]}]/td[2]").inner_html.to_s
      assists_str   = (doc/"/html/body/div/form/div[3]/div[2]/div[2]/div/div/div[3]/div[2]/div[2]/div[3]/div/div/div/div/div/div/table/tr[#{player[:index]}]/td[3]").inner_html.to_s
      deaths_str    = (doc/"/html/body/div/form/div[3]/div[2]/div[2]/div/div/div[3]/div[2]/div[2]/div[3]/div/div/div/div/div/div/table/tr[#{player[:index]}]/td[4]").inner_html.to_s
      suicides_str  = (doc/"/html/body/div/form/div[3]/div[2]/div[2]/div/div/div[3]/div[2]/div[2]/div[3]/div/div/div/div/div/div/table/tr[#{player[:index]}]/td[6]").inner_html.to_s
      betrays_str   = (doc/"/html/body/div/form/div[3]/div[2]/div[2]/div/div/div[3]/div[2]/div[2]/div[3]/div/div/div/div/div/div/table/tr[#{player[:index]}]/td[7]").inner_html.to_s
      headshots_str = (doc/"/html/body/div/form/div[3]/div[2]/div[2]/div/div/div[3]/div[2]/div[2]/div[5]/div/div/div/div/div/div/table/tr[#{player[:index]}]/td[2]").inner_html.to_s
      spree_str     = (doc/"/html/body/div/form/div[3]/div[2]/div[2]/div/div/div[3]/div[2]/div[2]/div[5]/div/div/div/div/div/div/table/tr[#{player[:index]}]/td[3]").inner_html.to_s

      player[:kills] = kills_str.to_i
      player[:assists] = assists_str.to_i
      player[:deaths] = deaths_str.to_i
      player[:suicides] = suicides_str.to_i
      player[:betrayals] = betrays_str.to_i
      player[:headshots] = headshots_str.to_i
      player[:best_spree] = spree_str.to_i
      
      save_player(player[:name])
    end
    
    puts players.inspect

  rescue Exception => e
    exception(e)
  end
end

def save_playlist(playlist_str)
  $adapter.query("select id from playlists where name='#{playlist_str}'") {|results|
    if ( results.num_rows() == 0 )
      insert_statement = $adapter.prepare("insert into playlists (name) values ('#{playlist_str}')")
      insert_statement.execute()
    end
  }
end

def save_team(team_name)
  $adapter.query("select id from teams where name='#{team_name}'") {|results|
    if ( results.num_rows() == 0 )
      insert_statement = $adapter.prepare("insert into teams (name) values ('#{team_name}')")
      insert_statement.execute()
    end
  }
  
  team_id = 0
  $adapter.query("select id from teams where name='#{team_name}'") {|results|
    results.each do |result|
      puts result.inspect
      team_id = result[0].to_i
    end
  }
  
  return team_id
end

def save_player(player_name)
  $adapter.query("select id from players where name='#{player_name}'") {|results|
    if ( results.num_rows() == 0 )
      insert_statement = $adapter.prepare("insert into players (name) values ('#{player_name}')")
      insert_statement.execute()
    end
  }
end