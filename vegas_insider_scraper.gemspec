Gem::Specification.new do |s|
  s.name        = 'vegas_insider_scraper'
  s.version     = '0.0.1'
  s.date        = '2017-06-19'
  s.summary     = "Vegas Insider Website Scraper API"
  s.description = "A gem to scrape vegasinsider.com for stats, teams, lines, and more!"
  s.authors     = ["Matthew Reitz"]
  s.email       = 'reitz1994@gmail.com'
  s.files       = [
                    'lib/vegas_insider_scraper.rb', 
                    'lib/sports/scraper_league.rb',
                    'lib/sports/ncaafb.rb',
                    'lib/sports/ncaabb.rb',
                    'lib/sports/nfl.rb',
                    'lib/sports/nba.rb',
                    'lib/sports/mlb.rb',
                    'lib/sports/nhl.rb',
                  ]
  s.homepage    = 'http://rubygems.org/gems/vegas_insider_scraper'
  s.license     = 'MIT'
end