
module VegasInsiderScraper
  class NBA < ScraperLeague
    def initialize
      @vegas_sport_identifier = 'nba'
      super
    end
  end
end
