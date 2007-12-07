class Player < ActiveRecord::Base

  def Player.get_summary_data(name, filters)
    puts filters.inspect
    
    player = Player.find_by_name(name)
    
    if ( filters.length == 0 )
      results = Player.connection.select_all("select count(pg.id) as games, sum(pg.kills) as kills, sum(pg.assists) as assists, sum(pg.deaths) as deaths from player_games pg where pg.player_id=#{player.id}")
    else
      playlist_names = []
      map_names = []
      game_type_names = []
      
      playlist_ids = Player.connection.select_all("select id from playlists where name in (#{Utility.list()})")
      playlist_sql = 'g.playlist_id in ()'
      filter = filters[0]
      if ( filter[:filter_type] == 'playlist' )
        playlist_name = filter[:filter_value].gsub('_', ' ')
        results = Player.connection.select_all("select count(pg.id) as games, sum(pg.kills) as kills, sum(pg.assists) as assists, sum(pg.deaths) as deaths from games g, player_games pg where g.id=pg.game_id and pg.player_id=#{player.id} and g.playlist_id=(select id from playlists where name='#{playlist_name}')")
      elsif ( filter[:filter_type] == 'map' )
        map_name = filter[:filter_value].gsub('_', ' ')
        results = Player.connection.select_all("select count(pg.id) as games, sum(pg.kills) as kills, sum(pg.assists) as assists, sum(pg.deaths) as deaths from games g, player_games pg where g.id=pg.game_id and pg.player_id=#{player.id} and g.map_id=(select id from maps where name='#{map_name}')")
      elsif ( filter[:filter_type] == 'weapon' )
        weapon_name = filter[:filter_value].gsub('_', ' ')
        results = Player.connection.select_all("select count(*) as games, sum(count) as kills from player_game_weapon_kills where player_game_id in (select id from player_games where player_id=#{player.id}) and weapon_id=(select id from weapons where name='#{weapon_name}') group by weapon_id;")
      elsif ( filter[:filter_type] == 'game_type' )
        game_type_name = filter[:filter_value].gsub('_', ' ')
        results = Player.connection.select_all("select count(pg.id) as games, sum(pg.kills) as kills, sum(pg.assists) as assists, sum(pg.deaths) as deaths from games g, player_games pg where g.id=pg.game_id and pg.player_id=#{player.id} and g.game_type_id=(select id from game_types where name='#{game_type_name}')")
      end
    end
    
    data = {:name => name}
    
    if ( results.length > 0 )
      data[:kills] = results[0]['kills'].to_i
      data[:deaths] = results[0]['deaths'].to_i
      data[:assists] = results[0]['assists'].to_i
      data[:games] = results[0]['games'].to_i
      
      data[:kd_ratio] = (data[:kills] / (1.0 * data[:deaths])).to_s
      data[:kd_ratio] = data[:kd_ratio][0, 6].to_f
      
      data[:kill_per_game] = (data[:kills] / (1.0 * data[:games])).to_s
      data[:kill_per_game] = data[:kill_per_game][0, 6].to_f
      
      data[:assist_per_game] = (data[:assists] / (1.0 * data[:games])).to_s
      data[:assist_per_game] = data[:assist_per_game][0, 6].to_f
      
      data[:death_per_game] = (data[:deaths] / (1.0 * data[:games])).to_s
      data[:death_per_game] = data[:death_per_game][0, 6].to_f
      
      data[:reaper_ratio] = ((data[:kills] + data[:assists]) / (1.0 * data[:deaths])).to_s
      data[:reaper_ratio] = data[:reaper_ratio][0, 6].to_f
    end
    
    return data
  end
  
  def Player.get_per_day_data(name)
    player = Player.find_by_name(name)
    
    results = Player.connection.select_all("select dayofyear(g.date) as doy, sum(pg.kills) as kills, sum(pg.assists) as assists, sum(pg.deaths) as deaths, (sum(pg.kills) / sum(pg.deaths)) as kd, ((sum(pg.kills)+sum(pg.assists))/sum(pg.deaths)) as reaper, count(g.id) as games, g.date as date from player_games pg, games g where pg.game_id=g.id and pg.player_id=#{player.id} group by dayofyear(g.date)")
    
    data = {:name => name, :data => []}
    
    first_result = true
    doy = 0
    results.each do |result|
      if ( first_result )
        doy = result['doy'].to_i
        puts "DOY=#{doy.inspect}"
      end
      
      while ( doy < result['doy'].to_i )
        # no data for today, enter 0's
        data[:data] << {
          :date => result['date'],
          :doy => doy,
          :kills => 0,
          :assists => 0,
          :deaths => 0,
          :games => 0,
          :kd => 0,
          :reaper => 0,
          :kpg => 0,
          :apg => 0,
          :dpg => 0
        }
        
        doy = doy + 1
      end
      
      data_set = {
        :date => result['date'],
        :doy => result['doy'].to_i,
        :kills => result['kills'].to_i,
        :assists => result['assists'].to_i,
        :deaths => result['deaths'].to_i,
        :games => result['games'].to_i,
        :kd => result['kd'].to_f,
        :reaper => result['reaper'].to_f
      }
      data_set[:kpg] = Utility.to_float(1.0 * data_set[:kills] / data_set[:games], 6)
      data_set[:apg] = Utility.to_float(1.0 * data_set[:assists] / data_set[:games], 6)
      data_set[:dpg] = Utility.to_float(1.0 * data_set[:deaths] / data_set[:games], 6)
      
      data[:data] << data_set
      
      doy = doy + 1
      first_result = false
    end
    
    return data
  end
end