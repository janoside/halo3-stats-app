require 'net/http'
require '/var/lib/gems/1.8/gems/xml-simple-1.0.11/lib/xmlsimple.rb'
require 'http.rb'
require 'bungie.rb'
require 'game_page_count.rb'
require 'game_list.rb'
require 'mysql'
require 'constants.rb'

def find_player_games(gamer_tag)
  puts "Finding Games for #{gamer_tag}"
  begin
    game_page_count = get_game_page_count(gamer_tag)
    
    player_pages = 0
    $adapter.query("select game_page_count from player_game_pages where player_id=(select id from players where name='#{gamer_tag.to_s}')") {|results|
      if ( results.num_rows() == 0 )
        # game page count not present, add it so that future game searching is shorter
        player_id = 0
        $adapter.query("select id from players where name='#{gamer_tag.to_s}'") {|gamer_id_results|
          gamer_id_results.each do |gamer_id_result|
            player_id = gamer_id_result[0].to_i
          end
        }
        
        insert_statement = $adapter.prepare("insert into player_game_pages (player_id, game_page_count) values (#{player_id}, #{game_page_count})")
        insert_statement.execute()
        
        puts "Player Game Page Count (PlayerID=#{player_id}, Pages=#{game_page_count}) Inserted."
      else
        results.each do |player_page_result|
          player_pages = player_page_result[0].to_i
        end
      end
    }
    
    puts "Player #{gamer_tag} Has #{game_page_count} Pages of Games."
    
    for i in 1..(1 + game_page_count - player_pages)
      game_page_list = get_game_ids(i, gamer_tag)
      
      puts "Game List Page #{i} (#{game_page_list.length} Games) Retrieved for #{gamer_tag}."
      
      game_page_list.each do |bungie_id|
        $adapter.query("select id from games where id=#{bungie_id.to_s}") {|results|
          if ( results.num_rows() == 0 )
            # game not present, add it
            insert_statement = $adapter.prepare("insert into games (id) values (#{bungie_id})")
            insert_statement.execute()
            
            puts "Bungie Game (ID=#{bungie_id}) Inserted."
          end
        }
      end
    end
    
    puts "All Games Found for #{gamer_tag}"
  
  rescue Exception => e
    exception(e)
  end
end