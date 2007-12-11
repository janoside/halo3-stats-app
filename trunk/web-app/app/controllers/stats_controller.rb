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
      user_player.visible = params[:active].to_i
      user_player.save()
    end
    
    load_watched_players()
    
    @watched_players = session[:watched_players]
    render(:partial => 'stats/watched_players')
  end
  
  def summary()
    @players = []
    session[:visible_players].each do |watched_player|
      @players << Player.get_summary_data(watched_player['player_name'], [])
    end
    
    load_filters()
  end
  
  def summary_sort()
    @players = []
    session[:visible_players].each do |watched_player|
      @players << Player.get_summary_data(watched_player['player_name'], [])
    end
    
    if ( params[:sort_name] == 'name' )
      @players.sort!{|a, b| a[:name].downcase() <=> b[:name].downcase()}
    else
      @players.sort!{|a, b| b[params[:sort_name].to_sym] <=> a[params[:sort_name].to_sym]}
    end
    
    render(:partial => 'stats/summary_data', :layout => false)
  end
  
  def apply_filters()
    @filters = {:playlists => [], :maps => [], :game_types => []}
    
    if ( !params[:playlists].nil? )
      params[:playlists].each do |playlist_id|
        @filters[:playlists] << playlist_id.to_i
      end
    end
    
    if ( !params[:maps].nil? )
      params[:maps].each do |map_id|
        @filters[:maps] << map_id.to_i
      end
    end
    
    if ( !params[:game_types].nil? )
      params[:game_types].each do |game_type_id|
        @filters[:game_types] << game_type_id.to_i
      end
    end
    
    @filters[:start_date] = params[:start_date]
    @filters[:end_date] = params[:end_date]
    
    session[:filters] = @filters
    
    puts "SET FILTERS: #{session[:filters].inspect}"
  end
  
  def summary_filter()
    apply_filters()
  
    @players = []
    session[:visible_players].each do |watched_player|
      @players << Player.get_summary_data(watched_player['player_name'], @filters)
    end
    
    render(:partial => 'stats/summary_data', :layout => false)
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
  
  def graphs()
    session[:graphs] = {}
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
    
    @graph_action = 'render_graph'
  end
  
  def compare()
    Player.get_comparison_data('jan0side', 'meesturbo', session[:filters])
    
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
  
  def set_compared_players()
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
    
    p1 = Player.find_by_name(params[:player1])
    p2 = Player.find_by_name(params[:player2])
    
    @p1 = p1.id
    @p2 = p2.id
    
    @graph_action = 'render_comparison'
    
    render(:template => 'stats/graphs', :layout => false)
  end
  
  def render_comparison()
    #apply_filters()
    
    players = Player.find_by_sql("select * from players where id in (#{Utility.list([params[:p1].to_i, params[:p2].to_i], ',')})")
    
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
    
    data = Player.get_comparison_data(players[0].name, players[1].name, session[:filters])
      
    data_points = []
    
    if ( params[:total].to_s == '1' )
      total = 0
      data.each do |key, dat|
        total = total + dat[params[:data_type].to_sym]
        data_points << total
      end
    else
      data.each do |key, dat|
        data_points << dat[params[:data_type].to_sym]
      end
    end
    
    g.data("#{players[0].name} / #{players[1].name}", data_points)
    
    g.maximum_value = 2
    g.minimum_value = -2
    
    guid = ApplicationController.GUID
    
    g.write("public/images/graphs/#{guid}.png")
    
    render(:text => "<img src=\"/images/graphs/#{guid}.png\"")
  end
  
  def render_graph()
    session[:graphs] ||= {}
    
    graph_name = params[:data_type].to_s
    if ( params[:total].to_s == '1' )
      graph_name = graph_name + '_total'
    end
    
    if ( session[:graphs][graph_name].nil? )
      #apply_filters()
      
      players = Player.find_by_sql("select * from players where id in (select player_id from user_players where user_id=#{session[:user_id]} and visible=1)")
      
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
        pdata[player.id] = Player.get_all_game_data(player.name, session[:filters])
      end
      
      players.each do |player|
        data = pdata[player.id]#dataPlayer.get_per_day_data(player.name)
        
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
      
      session[:graphs][graph_name] = guid
      
      g.write("public/images/graphs/#{session[:graphs][graph_name]}.png")
    else
      guid = session[:graphs][graph_name]
    end    
    
    render(:text => "<img src=\"/images/graphs/#{guid}.png\"")
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
