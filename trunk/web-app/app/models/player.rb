class Player < ActiveRecord::Base

  def Player.filter_where_clause(filters)
    playlist_names = []
    map_names = []
    game_type_names = []
    
    playlist_sql = ''
    map_sql = ''
    game_type_sql = ''
    where_clause = ''
    
    if ( !filters.nil? )
      sql_parts = []
      if ( !filters[:playlists].nil? && filters[:playlists].length > 0 && filters[:playlists][0] != 0 && filters[:playlists][0] != -1 )
        playlist_sql = "g.playlist_id in (#{Utility.list(filters[:playlists], ',')})"
        sql_parts << playlist_sql
      end
      
      if ( filters[:maps].length > 0 && filters[:maps][0] != 0 && filters[:maps][0] != -1 )
        map_sql = "g.map_id in (#{Utility.list(filters[:maps], ',')})"
        sql_parts << map_sql
      end
      
      if ( filters[:game_types].length > 0 && filters[:game_types][0] != 0 && filters[:game_types][0] != -1 )
        game_type_sql = "g.game_type_id in (#{Utility.list(filters[:game_types], ',')})"
        sql_parts << game_type_sql
      end
      
      if ( !filters[:start_date].nil? && filters[:start_date].length > 0 )
        sql_parts << "g.date > '#{filters[:start_date].to_s}'"
      end
      
      if ( !filters[:end_date].nil? && filters[:end_date].length > 0 )
        sql_parts << "g.date < '#{filters[:end_date].to_s}'"
      end
      
      where_clause = Utility.list(sql_parts, ' and ')
      if ( where_clause.length > 0 )
        where_clause = ' and ' + where_clause
      end
    end
    
    return where_clause
  end

  def Player.get_summary_data(name, filters)
    player = Player.find_by_name(name)
    
    if ( filters.length == 0 )
      results = Player.connection.select_all("select count(pg.id) as games, sum(pg.kills) as kills, sum(pg.assists) as assists, sum(pg.deaths) as deaths from player_games pg where pg.player_id=#{player.id}")
    else
      where_clause = Player.filter_where_clause(filters)
      
      sql = "select count(pg.id) as games, sum(pg.kills) as kills, sum(pg.assists) as assists, sum(pg.deaths) as deaths from games g, player_games pg where g.id=pg.game_id and pg.player_id=#{player.id} #{where_clause}" 
      
      puts sql.to_s
      
      results = Player.connection.select_all(sql)
    end
    
    data = {:name => name}
    
    if ( results.length > 0 )
      data[:kills] = results[0]['kills'].to_i
      data[:deaths] = results[0]['deaths'].to_i
      data[:assists] = results[0]['assists'].to_i
      data[:games] = results[0]['games'].to_i
      
      data[:kd_ratio] = (data[:kills] / (1.0 * data[:deaths])).to_s
      data[:kd_ratio] = Utility.to_float(data[:kd_ratio], 5)
      
      data[:kill_per_game] = (data[:kills] / (1.0 * data[:games])).to_s
      data[:kill_per_game] = Utility.to_float(data[:kill_per_game], 5)
      
      data[:assist_per_game] = (data[:assists] / (1.0 * data[:games])).to_s
      data[:assist_per_game] = Utility.to_float(data[:assist_per_game], 5)
      
      data[:death_per_game] = (data[:deaths] / (1.0 * data[:games])).to_s
      data[:death_per_game] = Utility.to_float(data[:death_per_game], 5)
      
      data[:reaper_ratio] = ((data[:kills] + data[:assists]) / (1.0 * data[:deaths])).to_s
      data[:reaper_ratio] = Utility.to_float(data[:reaper_ratio], 5)
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
      data_set[:kpg] = Utility.to_float(1.0 * data_set[:kills] / data_set[:games], 5)
      data_set[:apg] = Utility.to_float(1.0 * data_set[:assists] / data_set[:games], 5)
      data_set[:dpg] = Utility.to_float(1.0 * data_set[:deaths] / data_set[:games], 5)
      
      data[:data] << data_set
      
      doy = doy + 1
      first_result = false
    end
    
    return data
  end
  
  def Player.get_all_game_data(name, filters)
    puts "hahaha"
    puts filters.inspect
    player = Player.find_by_name(name)
    
    where_clause = Player.filter_where_clause(filters)
    
    sql = "select g.id as game_id, dayofyear(g.date) as doy, g.date as date, pg.kills as kills, pg.assists as assists, pg.deaths as deaths, (pg.kills / pg.deaths) as kd, ((pg.kills+pg.assists)/pg.deaths) as reaper, 1 as games from player_games pg, games g where pg.game_id=g.id and pg.player_id=#{player.id} #{where_clause}" 
    
    puts sql.to_s
    
    results = Player.connection.select_all(sql)
    
    data = {:name => name, :data => []}
    
    results.each do |result|
      data_set = {
        :game_id => result['game_id'].to_i,
        :date => result['date'],
        :doy => result['doy'].to_i,
        :kills => result['kills'].to_i,
        :assists => result['assists'].to_i,
        :deaths => result['deaths'].to_i,
        :games => result['games'].to_i,
        :kd => result['kd'].to_f,
        :reaper => result['reaper'].to_f
      }
      
      data[:data] << data_set
    end
    
    return data
  end
  
  def Player.get_comparison_data(p1_name, p2_name, filters)
    where_clause = Player.filter_where_clause(filters)
    p1 = Player.find_by_name(p1_name)
    p2 = Player.find_by_name(p2_name)
    
    data = {p1_name => {}, p2_name => {}}
    
    sql = "select id from games g where exists (select id from player_games where game_id=g.id and player_id=#{p1.id}) and exists (select id from player_games where game_id=g.id and player_id=#{p2.id}) #{where_clause}"
  
    results = Player.connection.select_all(sql)
    
    game_ids = []
    results.each do |result|
      game_ids << result['id'].to_i
    end
    
    sql = "select * from player_games where player_id=#{p1.id} and game_id in (#{Utility.list(game_ids, ',')}) order by game_id"
    
    results = Player.connection.select_all(sql)
    
    results.each do |result|
      data[p1_name][result['game_id'].to_i] = result
    end
    
    sql = "select * from player_games where player_id=#{p2.id} and game_id in (#{Utility.list(game_ids, ',')}) order by game_id"
    
    results = Player.connection.select_all(sql)
    
    results.each do |result|
      data[p2_name][result['game_id'].to_i] = result
    end
    
    compare_data = {}
    game_ids.each do |game_id|
      if ( data[p1_name][game_id]['kills'].to_i == 0 )
        data[p1_name][game_id]['kills'] = '1'
      end
      
      if ( data[p2_name][game_id]['kills'].to_i == 0 )
        data[p2_name][game_id]['kills'] = '1'
      end
      
      if ( data[p1_name][game_id]['deaths'].to_i == 0 )
        data[p1_name][game_id]['deaths'] = '1'
      end
      
      if ( data[p2_name][game_id]['deaths'].to_i == 0 )
        data[p2_name][game_id]['deaths'] = '1'
      end
      
      compare_data[game_id] = {
        :kills => data[p1_name][game_id]['kills'].to_i - data[p2_name][game_id]['kills'].to_i,
        :assists => data[p1_name][game_id]['assists'].to_i - data[p2_name][game_id]['assists'].to_i,
        :deaths => data[p1_name][game_id]['deaths'].to_i - data[p2_name][game_id]['deaths'].to_i,
        :kd => (data[p1_name][game_id]['kills'].to_f / data[p1_name][game_id]['deaths'].to_f) / (data[p2_name][game_id]['kills'].to_f / data[p2_name][game_id]['deaths'].to_f) - 1,
        :reaper => ((data[p1_name][game_id]['kills'].to_f + data[p1_name][game_id]['assists'].to_f) / data[p1_name][game_id]['deaths'].to_f) / ((data[p2_name][game_id]['kills'].to_f + data[p2_name][game_id]['assists'].to_f) / data[p2_name][game_id]['deaths'].to_f) - 1
      }
    end
    
    return compare_data
  end
end