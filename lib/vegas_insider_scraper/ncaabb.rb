
module VegasInsiderScraper
  class NCAABB < ScraperLeague
    def initialize
      @vegas_sport_identifier = 'college-basketball'
      super
    end
  end
end
