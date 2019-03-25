
module VegasInsiderScraper
  class NCAAFB < ScraperLeague
    def initialize
      @vegas_sport_identifier = 'college-football'
      super
    end

    def teams
      @teams ||= scrape_teams
    end
  end
end
