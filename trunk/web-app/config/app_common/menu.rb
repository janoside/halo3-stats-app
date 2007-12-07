APP_MENU = [
  {
    :name => 'Profile',
    :links => [
      {:name => 'Preferences', :url => '/'},
      {:name => 'Watched Players', :url => '/stats/watched_players'},
      {:name => 'Logout', :url => '/application/logout'}
    ]
  },
  {
    :name => 'Stats',
    :links => [
      {:name => 'Summary', :url => '/stats/summary'},
      {:name => 'Graphs', :url => '/stats/graphs'},
      {:name => 'Weapon Breakdown', :url => '/stats/player_weapons'}
    ]
  }
]