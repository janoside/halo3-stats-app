class User < ActiveRecord::Base

  def User.get_watched_players(user_id)
    User.connection.select_all("select * from v_user_players where user_id=" + user_id.to_s)
  end
end