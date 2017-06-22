Gem::Specification.new do |s|
  s.name        = 'vegas-insider-scraper'
  s.version     = '0.0.0'
  s.date        = '2017-06-19'
  s.summary     = "Vegas Insider Website Scraper API"
  s.description = "A gem to scrape vegasinsider.com for stats, teams, lines, and more!"
  s.authors     = ["Matthew Reitz"]
  s.email       = 'reitz1994@gmail.com'
  s.files       = [
                    'lib/vegas-insider-scraper.rb', 
                    'lib/leagues/scraper_league.rb',
                    'lib/leagues/ncaafb.rb',
                    'lib/leagues/ncaabb.rb',
                    'lib/leagues/nfl.rb',
                    'lib/leagues/mlb.rb',
                    'lib/leagues/nba.rb',
                    'lib/leagues/nhl.rb'
                  ]
  s.homepage    = 'http://rubygems.org/gems/vegas-insider-scraper'
  s.license     = 'MIT'
end