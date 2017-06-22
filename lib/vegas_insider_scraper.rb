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

	attr_reader :leagues
	LEAGUES = [NCAAFB, NCAABB, NFL, NBA, MLB, NHL]

	def initialize
		@leagues = LEAGUES.map { |league| league.new }
	end

	

	# def self.get_lines
	# 	LEAGUES.each do |league_scraper|
	# 		league_scraper.new.get_games
	# 	end
	# end

	# def self.update_standings
	# 	LEAGUES.each do |league_scraper|
	# 		league_scraper.new.update_standings
	# 	end
	# end

	# def self.get_results
	# 	LEAGUES.each do |league_scraper|
	# 		league_scraper.new.get_results
	# 	end
	# end

	# def self.scrape_team_page_for_nickname(vegas_identifier, url)
	# 	doc = Nokogiri::HTML(open(url))

	# 	title = doc.at_css('h1.page_title').content.gsub(' Team Page', '')
	# 	match = title.split(/\W+/)
	# 	url_formatted = vegas_identifier.gsub('-',' ').split.map(&:capitalize)
	# 	team_nickname = (match - url_formatted).join(' ')
	# 	return team_nickname
	# end

end