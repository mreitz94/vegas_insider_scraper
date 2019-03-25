
module VegasInsiderScraper
  class NHL < ScraperLeague
    def initialize
      @vegas_sport_identifier = 'nhl'
      super
      @moneyline_sport = true
    end

    def current_games
      @current_games ||= get_lines(["http://www.vegasinsider.com/#{vegas_sport_identifier}/odds/las-vegas/puck/", 
        "http://www.vegasinsider.com/#{vegas_sport_identifier}/odds/las-vegas/"])
    end
  end
end