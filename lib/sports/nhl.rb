
class NHL < ScraperLeague

  def initialize
    @sport_id = 5
    @sport_name = :nhl
    super
    @moneyline_sport = true
  end

  def current_games
    @current_games ||= get_lines(["http://www.vegasinsider.com/#{sport_name}/odds/las-vegas/puck/", 
      "http://www.vegasinsider.com/#{sport_name}/odds/las-vegas/"])
  end
end