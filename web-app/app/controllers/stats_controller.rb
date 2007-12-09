require 'gruff'

class StatsController < ApplicationController  
  before_filter :check_login, :except => [:login]
  
  def index()
  end
  
  def watched_players()
    puts session[:watched_players].inspect
    @watched_players = session[:watched_players]
  end
  
  def add_watched_player()
    gamer_tag = params[:gamer_tag]
    player = Player.find_by_name(gamer_tag)
    if ( player.nil? )
      player = Player.new()
      player.name = gamer_tag
    end
    
    player.active = 1
    player.save()
    
    user_player = UserPlayer.find_by_user_id_and_player_id(session[:user_id], player.id)
    if ( user_player.nil? )
      user_player = UserPlayer.new()
      user_player.user_id = session[:user_id]
      user_player.player_id = player.id
      user_player.active = 1
      
      user_player.save()
    end
    
    load_watched_players()
    
    @watched_players = session[:watched_players]
    render(:partial => 'stats/watched_players')
  end
  
  def set_watched_player_visibility()
    gamer_tag = params[:gamer_tag]
    player = Player.find_by_name(gamer_tag)
    user_player = UserPlayer.find_by_user_id_and_player_id(session[:user_id], player.id)
    
    if ( !user_player.nil? )
      user_player.active = params[:active].to_i
      user_player.save()
    end
    
    load_watched_players()
    
    @watched_players = session[:watched_players]
    render(:partial => 'stats/watched_players')
  end
  
  def summary()
    @players = []
    session[:visible_players].each do |watched_player|
      @players << Player.get_summary_data(watched_player['player_name'], [], '', '')
    end
    
    load_filters()
  end
  
  def summary_sort()
    @players = []
    session[:visible_players].each do |watched_player|
      @players << Player.get_summary_data(watched_player['player_name'], [], '', '')
    end
    
    if ( params[:sort_name] == 'name' )
      @players.sort!{|a, b| a[:name].downcase() <=> b[:name].downcase()}
    else
      @players.sort!{|a, b| b[params[:sort_name].to_sym] <=> a[params[:sort_name].to_sym]}
    end
    
    render(:partial => 'stats/summary_data', :layout => false)
  end
  
  def summary_filter()
    @filters = {:playlists => [], :maps => [], :game_types => []}
    
    params[:playlists].each do |playlist_id|
      @filters[:playlists] << playlist_id.to_i
    end
    params[:maps].each do |map_id|
      @filters[:maps] << map_id.to_i
    end
    params[:game_types].each do |game_type_id|
      @filters[:game_types] << game_type_id.to_i
    end
    
    @start_date = params[:start_date]
    @end_date = params[:end_date]
  
    @players = []
    session[:visible_players].each do |watched_player|
      @players << Player.get_summary_data(watched_player['player_name'], @filters, @start_date, @end_date)
    end
    
    render(:partial => 'stats/summary_data', :layout => false)
    #render(:text => params.inspect, :layout => false)
  end
  
  def update_watched_players()
    @watched_players = session[:watched_players]
  end
  
  def player_weapons()
    @players = []
    session[:watched_players].each do |watched_player|
      @players << {:name => watched_player['player_name']}
    end
    
    @players.sort!{|a, b| a[:name].downcase() <=> b[:name].downcase()}
  end
  
  def stats
    g = Gruff::Line.new('1700x700')
    g.theme = {
       :colors => ['#ff6600', '#3bb000', '#1e90ff', '#efba00', '#0aaafd'],
       :marker_color => '#aaa',
       :background_colors => ['#fff', '#fff']
     }
     
    g.hide_dots()
     
    
#    @data = []
#    session[:watched_players].each do |player|
#      
#    end
 
    range = "date #{(12.months.ago.to_date..Date.today).to_s(:db)}"
    @games = Game.count(:all, :conditions => range, :group => "DATE_FORMAT(date, '%Y-%m-%d')", :order =>"date ASC")
 
    # Take the union of all keys & convert into a hash {1 => "month", 2 => "month2"...}
    # - This will be the x-axis.. representing the date range
    months = (@games.keys).sort
    keys = Hash[*months.collect {|v| [months.index(v),v.to_s] }.flatten]
 
    # Plot the data - insert 0's for missing keys
    g.data("Games", keys.collect {|k,v| @games[v].nil? ? 0 : @games[v]})
 
    g.labels = keys
 
    send_data(g.to_blob, :disposition => 'inline', :type => 'image/png', :filename => "site-stats.png")
  end
  
  def fruit
    g = Gruff::Line.new('1700x700')
    g.title = "Kills / Week"
    
    #g.theme_rails_keynote()
    
    g.data("Apples", [1, 2, 3, 4, 4, 3])
    g.data("Oranges", [4, 8, 7, 9, 8, 9])
    g.data("Watermelon", [2, 3, 1, 5, 6, 8])
    g.data("Peaches", [9, 9, 10, 8, 7, 9])
    
    g.labels = {0 => '2003', 2 => '2004', 4 => '2005'}
    
    send_data(g.to_blob, :disposition => 'inline', :type => 'image/png', :filename => "fruit.png")
  end
  
  def haha()
    players = Player.find_by_sql("select * from players where id in (select player_id from user_players where user_id=#{session[:user_id]})")
    
    g = Gruff::Line.new
    g.theme = {
      :colors => ['#ff6600', '#3bb000', '#1e90ff', '#efba00', '#0aaafd'],
      :marker_color => '#aaa',
      :background_colors => ['#fff', '#fff']
    }
    g.title_font_size=12
    g.legend_font_size=12
    g.marker_font_size=12
    g.hide_dots = true
    g.title = "Daily Totals"
    
    players.each do |player|
      data = Player.get_per_day_data(player.name)
      
      kills = []
      assists = []
      deaths = []
      kds = []
      reapers = []
      
      data[:data].each do |dat|
        kills << dat[:kills]
        assists << dat[:assists]
        deaths << dat[:deaths]
        kds << dat[:kd]
        reapers << dat[:reaper]
      end
      
      g.data(player.name, kds)
    end
    
    
#    g.data("Kills", kills)
#    g.data("Assists", assists)
#    g.data("Deaths", deaths)
    
    #g.data("Kill/Death", kds)
    #g.data("Reaper Ratio", reapers)
    
    g.labels = {0 => '2003', 2 => '2004', 4 => '2005'}
    
    g.write('public/images/haha2.png')
    #send_data(g.to_blob, :disposition => 'inline', :type => 'image/png', :filename => "kd_ratios.png")
  end
  
  def graphs()
    load_filters()
    
    @per_day_values = [
      {:data_type => 'kills', :name => 'Kill/Game'},
      {:data_type => 'assists', :name => 'Assist/Game'},
      {:data_type => 'deaths', :name => 'Death/Game'},
      {:data_type => 'kd', :name => 'KD Ratio/Game'},
      {:data_type => 'reaper', :name => 'Reaper/Game'}
      ]
      
    @total_values = [
      {:data_type => 'kills', :name => 'Total Kills'},
      {:data_type => 'assists', :name => 'Total Assists'},
      {:data_type => 'deaths', :name => 'Total Deaths'},
      {:data_type => 'kd', :name => 'Total KD Ratio'},
      {:data_type => 'reaper', :name => 'Total Reaper'}
    ]
  end
  
  def render_graph()
    players = Player.find_by_sql("select * from players where id in (select player_id from user_players where user_id=#{session[:user_id]} and active=1)")
    
    g = Gruff::Line.new('800x500')
    g.theme = {
      :colors => ['#ff6600', '#3bb000', '#1e90ff', '#efba00', '#0aaafd'],
      :marker_color => '#aaa',
      :background_colors => ['#fff', '#fff']
    }
    g.title_font_size=12
    g.legend_font_size=12
    g.marker_font_size=12
    g.hide_dots = true
    #g.title = "Daily Totals"
    
    pdata = {}
    players.each do |player|
      pdata[player.id] = Player.get_all_game_data(player.name)
    end
    
    min_doy = 1000
    players.each do |player|
      #puts "----------------------"
      #puts pdata[player.id].inspect
      if ( pdata[player.id][:data][0][:doy] < min_doy )
        min_doy = pdata[player.id][:data][0][:doy]
      end
    end
    players.each do |player|
      end_doy = pdata[player.id][:data][0][:doy]
      for i in min_doy..end_doy
        pdata[player.id][:data].insert(0, {
          :doy => i,
          :kills => 0,
          :assists => 0,
          :deaths => 0,
          :games => 0,
          :kd => 0,
          :reaper => 0
        })
      end
      
      data = pdata[player.id]#dataPlayer.get_per_day_data(player.name)
      
      #puts data.inspect
      
      data_points = []
      
      if ( params[:total].to_s == '1' )
        total = 0
        data[:data].each do |dat|
          total = total + dat[params[:data_type].to_sym]
          data_points << total
        end
      else
        data[:data].each do |dat|
          data_points << dat[params[:data_type].to_sym]
        end
      end
      
      g.data(player.name, data_points)
    end
    
    guid = ApplicationController.GUID
    
    g.write("public/images/graphs/#{guid}.png")
    render(:text => "<img src=\"/images/graphs/#{guid}.png\"")
  rescue Exception => e
    puts e.backtrace
  end
  
  private
  
  def load_filters()
    @playlists = Playlist.find(:all)
    @playlists.sort!{|a, b| a['name'].downcase() <=> b['name'].downcase()}
    @playlists.each do |playlist|
      playlist['name'] = (playlist['name'] + ' (R)') if ( playlist['ranked'].to_s == 'true' )
    end
    
    @maps = Map.find(:all)
    @maps.sort!{|a, b| a['name'].downcase() <=> b['name'].downcase()}
    
    @game_types = GameType.find(:all)
    @game_types.sort!{|a, b| a['name'].downcase() <=> b['name'].downcase()}
    
    @playlist_options = [['All', -1]]
    @map_options = [['All', -1]]
    @game_type_options = [['All', -1]]
    
    @playlists.each do |playlist|
      @playlist_options << [playlist['name'], playlist['id']]
    end
    
    @maps.each do |map|
      @map_options << [map['name'], map['id']]
    end
    
    @game_types.each do |game_type|
      @game_type_options << [game_type['name'], game_type['id']]
    end
  end
end
