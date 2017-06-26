require 'nokogiri'
require 'open-uri'

require 'sports/scraper_league'
require 'sports/ncaafb'
require 'sports/ncaabb'
require 'sports/nba'
require 'sports/nfl'
require 'sports/mlb'
require 'sports/nhl'

class VegasInsiderScraper

	attr_reader :sports
	# supported sports
	SPORTS = [NCAAFB, NCAABB, NFL, NBA, MLB, NHL]

	def initialize
		@sports = SPORTS.map { |sport| sport.new }
	end

end