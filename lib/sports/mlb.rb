
class MLB < ScraperLeague

  def initialize
    @sport_id = 4
    @sport_name = :mlb
    super
    @moneyline_sport = true
  end

  def current_games
    @current_games ||= get_lines(["http://www.vegasinsider.com/#{sport_name}/odds/las-vegas/run/", 
      "http://www.vegasinsider.com/#{sport_name}/odds/las-vegas/"])
  end

end
