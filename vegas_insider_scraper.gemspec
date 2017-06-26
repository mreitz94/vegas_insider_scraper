Gem::Specification.new do |s|
  s.name        = 'vegas_insider_scraper'
  s.version     = '0.0.2'
  s.date        = '2017-06-24'
  s.summary     = "Sports statistics and betting lines scraper"
  s.description = "A gem to scrape the web for sports statistics, teams, betting lines, records, and results!"
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
  s.homepage    = 'https://github.com/mreitz94/betting-tools-scraper'
  s.license     = 'MIT'
  
  s.add_dependency "nokogiri"
end