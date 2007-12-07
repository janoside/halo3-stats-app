class UserLogin < ActiveRecord::Base
  
  def UserLogin.save(user_id)
    login = UserLogin.new()
    login.user_id = user_id
    login.time = Time.now()
    
    login.save()
  end
end