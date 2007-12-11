# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
require 'log.rb'

class ApplicationController < ActionController::Base
  # Pick a unique cookie name to distinguish our session data from others'
  session :session_key => '_one_two_session_id'
  
  before_filter :check_login, :except => [:login]
  
  def index()
  end
  
  def test()
    player = Player.new()
    player.name = 'jan0side'
    
    player.save()
  end
  
  def login()
    if ( request.post? )
      user = User.find_by_email(params[:email])
      if ( !user.nil? )
        session[:user_id] = user.id
        on_login()
        redirect_to(:controller => 'application', :action => 'index')
      else
        user = User.new()
        user.email = params[:email]
        
        if ( user.save() )
          session[:user_id] = user.id
          on_login()
          redirect_to(:controller => 'application', :action => 'index')
        else
          flash[:error] = 'Failed to create user account, please try again.'
          render(:layout => 'login')
        end
      end
    end
  end
  
  def logout()
    session[:user_id] = nil
    redirect_to(:controller => 'application', :action => 'login')
  end
  
  def rescue_action(exception)
    Log.exception(exception)
  end
  
  private
  
  def check_login()
    if ( session[:user_id].blank? )
      redirect_to(:controller => 'application', :action => 'login')
      return false
    else
      @logged_in = true
      @email = session[:email]
      return true
    end
  end
  
  def on_login()
    session[:email] = User.find_by_id(session[:user_id]).email
    UserLogin.save(session[:user_id])
    load_watched_players()
  end
  
  def load_watched_players()
    session[:watched_players] = User.get_watched_players(session[:user_id])
    
    session[:visible_players] = []
    session[:watched_players].each do |watched_player|
      if ( watched_player['visible'].to_s == '1' )
        session[:visible_players] << watched_player
      end
    end
  end
  
  def ApplicationController.GUID
    g = ''

    50.times do
      rand_num = srand

      case rand_num % 3
      when 1
        rand_char = (rand_num % 9) + 48  # 0-9
      when 2
        rand_char = (rand_num % 26) + 65 # A-Z
      else
        rand_char = (rand_num % 26) + 97 # a-z
      end

      g << sprintf('%c', rand_char)
    end

    g
  end
end
