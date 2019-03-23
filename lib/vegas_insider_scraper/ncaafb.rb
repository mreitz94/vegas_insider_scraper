
module VegasInsiderScraper
  class NCAAFB < ScraperLeague
    def initialize
      @sport_name = 'college-football'
      super
    end

    def teams
      @teams ||= scrape_teams
    end
  end
end
