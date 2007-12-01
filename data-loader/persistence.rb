$players = {}
$weapons = {}
$playlists = {}
$maps = {}

def save_playlist(playlist_str)
  if ( !$playlists.has_key?(playlist_str) )
    $adapter.query("select id from playlists where name='#{playlist_str}'") {|results|
      if ( results.num_rows() == 0 )
        insert_statement = $adapter.prepare("insert into playlists (name) values ('#{playlist_str}')")
        insert_statement.execute()
        
        $adapter.query("select id from playlists where name='#{playlist_str}'") {|results|
          results.each do |result|
            $playlists[playlist_str] = result[0].to_i
          end
        }
      else
        results.each do |result|
          $playlists[playlist_str] = result[0].to_i
        end
      end
    }
  end
  
  return $playlists[playlist_str]
end

def save_map(name)
  if ( !$maps.has_key?(name) )
    $adapter.query("select id from maps where name='#{name}'") {|results|
      if ( results.num_rows() == 0 )
        insert_statement = $adapter.prepare("insert into maps (name) values ('#{name}')")
        insert_statement.execute()
        
        $adapter.query("select id from maps where name='#{name}'") {|results|
          results.each do |result|
            $maps[name] = result[0].to_i
          end
        }
      else
        results.each do |result|
          $maps[name] = result[0].to_i
        end
      end
    }
  end
  
  return $maps[name]
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

def save_player(name)
  player_id = 0
  $adapter.query("select id from players where name='#{name}'") {|results|
    if ( results.num_rows() == 0 )
      insert_statement = $adapter.prepare("insert into players (name) values ('#{name}')")
      insert_statement.execute()
      
      $adapter.query("select id from players where name='#{name}'") {|results|
        results.each do |result|
          player_id = result[0].to_i
        end
      }
    else
      results.each do |result|
        player_id = result[0].to_i
      end
    end
  }
  
  return player_id
end

def save_weapon(name)
  $adapter.query("select id from weapons where name='#{name}'") {|results|
    if ( results.num_rows() == 0 )
      insert_statement = $adapter.prepare("insert into weapons (name) values ('#{name}')")
      insert_statement.execute()
    end
  }
  
  weapon_id = 0
  $adapter.query("select id from weapons where name='#{name}'") {|results|
    results.each do |result|
      weapon_id = result[0].to_i
    end
  }
  
  return weapon_id
end

def sql_time(time)
  return time.strftime('%Y-%m-%d %H:%M:%S')
end

def persist_game_detail(dat)
  playlist_id = save_playlist(dat[:playlist])
  map_id = save_map(dat[:playlist])
  
  sql = "update games set playlist_id=#{playlist_id}, map_id=#{map_id}, date='#{sql_time(dat[:time])}', length=#{dat[:length]}, loaded=1 where id=#{dat[:id]}"
  
  puts sql.to_s
  
  insert_statement = $adapter.prepare(sql)
  insert_statement.execute()
end

def persist_player_data(dat)
  player_id = save_player(dat[:name])
  team_id = save_team(dat[:team])
  
  columns = "player_id, game_id, kills, assists, deaths, suicides, betrayals, headshots, best_spree, team_id, place"
  values  = "#{player_id}, #{dat[:game_id]}, #{dat[:kills]}, #{dat[:assists]}, #{dat[:deaths]}, #{dat[:suicides]}, #{dat[:betrayals]}, #{dat[:headshots]}, #{dat[:best_spree]}, #{team_id}, '#{dat[:place]}'"
  
  sql = "insert into player_games (#{columns}) values (#{values})"
  
  puts sql.to_s
  
  insert_statement = $adapter.prepare(sql)
  insert_statement.execute()
  
  player_game_id = 0
  $adapter.query("select id from player_games where player_id=#{player_id} and game_id=#{dat[:game_id]}") {|results|
    results.each do |result|
      player_game_id = result[0].to_i
    end
  }
  
  dat[:weapons].each do |weapon|
    weapon_id = save_weapon(weapon[:name])
    
    sql = "insert into player_game_weapon_kills (player_game_id, weapon_id, count) values (#{player_game_id}, #{weapon_id}, #{weapon[:kills]})"
    
    puts sql.to_s
    
    insert_statement = $adapter.prepare(sql)
    insert_statement.execute()
  end
  
  dat[:killed_players].each do |killed_player|
    player_id = save_player(killed_player[:name])
    
    sql = "insert into player_game_player_kills (player_game_id, killed_player_id, count) values (#{player_game_id}, #{player_id}, #{killed_player[:kills]})"
    
    puts sql.to_s
    
    insert_statement = $adapter.prepare(sql)
    insert_statement.execute()
  end
end