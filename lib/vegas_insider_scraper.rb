require 'nokogiri'
require 'open-uri'
require 'byebug'

require 'sports/scraper_league'
require 'sports/ncaafb'
require 'sports/ncaabb'
require 'sports/nba'
require 'sports/nfl'
require 'sports/mlb'
require 'sports/nhl'

class VegasInsiderScraper
  attr_reader :sports

  SPORTS = [NCAAFB, NCAABB, NFL, NBA, MLB, NHL]

  def initialize
    @sports = SPORTS.map { |sport_class| sport_class.new }
  end

  SPORTS.each do |sport_class|
    define_method(sport_class.to_s.downcase) do
      @sports.select { |sport| sport.class == sport_class }.first
    end
  end
end