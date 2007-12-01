require 'rubygems'
require 'open-uri'
require 'hpricot'
require 'persistence.rb'

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
  $adapter.query("select id from games where loaded=0") {|results|
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
    
    game_detail = {:id => bungie_game_id}
    
    # Retrive number of comments
    playlist_str = (doc/"/html/body/div/form/div[3]/div[2]/div[2]/div/div/div[3]/div/ul/li[4]").inner_html.to_s
    if ( !playlist_str.nil? )
      playlist_str = playlist_str[playlist_str.index('-') + 2, playlist_str.index('&') - (playlist_str.index('-') + 2)]
      game_detail[:playlist] = playlist_str
    end
    
    map_str = (doc/"/html/body/div/form/div[3]/div[2]/div[2]/div/div/div[3]/div/ul/li").inner_html.to_s
    if ( !map_str.nil? )
      map_str = map_str[map_str.index(' on ') + ' on '.length, map_str.length - (map_str.index(' on ') + ' on '.length)]
      map_str = map_str[0, map_str.index('&')]
      game_detail[:map] = map_str
    end
    
    time_str = (doc/"/html/body/div/form/div[3]/div[2]/div[2]/div/div/div[3]/div/ul/li[5]").inner_html.to_s
    if ( !time_str.nil? )
      time_str = time_str[0, time_str.index('&')]
      game_time = Time.parse(time_str)
      game_detail[:time] = game_time
    end
    
    length_str = (doc/"/html/body/div/form/div[3]/div[2]/div[2]/div/div/div[3]/div/ul/li[6]").inner_html.to_s
    if ( !length_str.nil? )
      length_str = length_str['Length:'.length + 1, length_str.index('&') - ('Length:'.length + 1)]
      
      hours = length_str[0, length_str.index(':')].to_i
      length_str = length_str[length_str.index(':')+ 1, length_str.length - (length_str.index(':')+ 1)]
      mins = length_str[0, length_str.index(':')].to_i
      length_str = length_str[length_str.index(':')+ 1, length_str.length - (length_str.index(':')+ 1)]
      secs = length_str.to_i
      
      total_secs = 3600 * hours + 60 * mins + secs
      game_detail[:length] = total_secs
    end
    
    puts game_detail.inspect
    
    persist_game_detail(game_detail)
    
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
            :score => dat[:score],
            :game_id => bungie_game_id
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
               #             /html/body/div/form/div[3]/div[2]/div[2]/div/div/div[3]/div[2]/div[2]/div[4]/div/div/div/div/div/div/table/tr[3]/td[7]/div/div/div/ul/li[2]/div/div[2]
  #                          /html/body/div/form/div[3]/div[2]/div[2]/div/div/div[3]/div[2]/div[2]/div[5]/div/div/div/div/div/div/table/tr[#{player[:index]}]/td[6]/div/div/div/ul/li[2]
   #                         /html/body/div/form/div[3]/div[2]/div[2]/div/div/div[3]/div[2]/div[2]/div[5]/div/div/div/div/div/div/table/tr[#{player[:index]}]/td[6]/div/div/div/ul/li[2]/div/div
   #                         /html/body/div/form/div[3]/div[2]/div[2]/div/div/div[3]/div[2]/div[2]/div[4]/div/div/div/div/div/div/table/tr[3]/td[7]/div/div/div/ul/li[2]/div/div[2]

      player[:kills] = kills_str.to_i
      player[:assists] = assists_str.to_i
      player[:deaths] = deaths_str.to_i
      player[:suicides] = suicides_str.to_i
      player[:betrayals] = betrays_str.to_i
      player[:headshots] = headshots_str.to_i
      player[:best_spree] = spree_str.to_i
      
      player[:killed_players] = []
      player[:weapons] = []
      
      for i in 2..20
        kill_data = (doc/"/html/body/div/form/div[3]/div[2]/div[2]/div/div/div[3]/div[2]/div[2]/div[5]/div/div/div/div/div/div/table/tr[#{player[:index]}]/td[6]/div/div/div/ul/li[#{i.to_s}]/div/div").inner_html.to_s
        if ( kill_data.length > 0 )
          name = kill_data[0, kill_data.index(':')]
          count = kill_data[kill_data.index(':') + 2, kill_data.length - (kill_data.index(':') + 2)].to_i
          
          player[:killed_players] << {:name => name, :kills => count}
        end
      end
      
      for i in 2..15
        weapon = (doc/"/html/body/div/form/div[3]/div[2]/div[2]/div/div/div[3]/div[2]/div[2]/div[4]/div/div/div/div/div/div/table/tr[#{player[:index]}]/td[7]/div/div/div/ul/li[#{i.to_s}]/div/div[2]").inner_html.to_s
        kills =  (doc/"/html/body/div/form/div[3]/div[2]/div[2]/div/div/div[3]/div[2]/div[2]/div[4]/div/div/div/div/div/div/table/tr[#{player[:index]}]/td[7]/div/div/div/ul/li[#{i.to_s}]/div/div[3]").inner_html.to_s
        
        if ( weapon.length > 0 )
          save_weapon(weapon)
          
          if ( kills.index(' ').nil? )
            kill_count = kills.to_i
          else
            kill_count = kills[0, kills.index(' ')].to_i
          end
          
          player[:weapons] << {:name => weapon, :kills => kill_count}
        end
      end
      
      persist_player_data(player)
    end

  rescue Exception => e
    exception(e)
  end
end