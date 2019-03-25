require 'nokogiri'
require 'open-uri'
# require 'byebug'

require 'vegas_insider_scraper/scraper_league'
require 'vegas_insider_scraper/ncaafb'
require 'vegas_insider_scraper/ncaabb'
require 'vegas_insider_scraper/nba'
require 'vegas_insider_scraper/nfl'
require 'vegas_insider_scraper/mlb'
require 'vegas_insider_scraper/nhl'
require 'vegas_insider_scraper/soccer'

module VegasInsiderScraper
  SPORTS = [
    VegasInsiderScraper::NCAAFB,
    VegasInsiderScraper::NCAABB,
    VegasInsiderScraper::NFL,
    VegasInsiderScraper::NBA,
    VegasInsiderScraper::MLB,
    VegasInsiderScraper::NHL,
    VegasInsiderScraper::Soccer
  ]

  def self.ncaafb
    VegasInsiderScraper::NCAAFB.new
  end

  def self.ncaabb
    VegasInsiderScraper::NCAABB.new
  end

  def self.nfl
    VegasInsiderScraper::NFL.new
  end

  def self.nba
    VegasInsiderScraper::NBA.new
  end

  def self.mlb
    VegasInsiderScraper::MLB.new
  end

  def self.nhl
    VegasInsiderScraper::NHL.new
  end

  def self.soccer
    VegasInsiderScraper::Soccer.new
  end
end