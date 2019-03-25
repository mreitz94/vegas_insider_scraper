
module VegasInsiderScraper
  class NFL < ScraperLeague
    def initialize
      @vegas_sport_identifier = 'nfl'
      super
    end
  end
end