
module VegasInsiderScraper
  class NBA < ScraperLeague
    def initialize
      @sport_name = 'nba'
      super
    end
  end
end
