
module VegasInsiderScraper
  class NFL < ScraperLeague
    def initialize
      @sport_name = 'nfl'
      super
    end
  end
end