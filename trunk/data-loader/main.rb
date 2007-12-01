require 'player_games.rb'
require 'game_detail_loader.rb'
require 'exception.rb'

begin
  $adapter = Mysql.new('127.0.0.1', 'root', 'dandan', 'halo3')
  
  $adapter.query("select name from players where active=1") {|results|
    results.each do |gamer_tag|
      find_player_games(gamer_tag)
    end
  }
  
  save_unloaded_games()
  
  $adapter.close()
  
rescue Exception => e
  exception(e)
end