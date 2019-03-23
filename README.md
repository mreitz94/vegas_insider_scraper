# VegasInsiderScraper

VegasInsiderScraper is a gem used to scrape sports related data for various different leagues in order to get up-to-date information for free!

The data that can be retrieved includes teams, standings information, and games.

## Installation

```ruby
gem install vegas_insider_scraper
```

or put it in your Gemfile and run `bundle install`

```ruby
gem "vegas_insider_scraper"
```

## 1 Usage

To access all league classes:

```ruby
scraper = VegasInsiderScraper::SPORTS
```

or to instantiate a specific league

```ruby
mlb_scraper = VegasInsiderScraper::MLB.new
```

Available leagues are NCAAFB, NCAABB, NFL, MLB, NBA, NHL, and Soccer

### 1.1 Getting Teams

```ruby
VegasInsiderScraper::NCAAFB.new.teams

# [
#    ...,
#   {
#      info: {
#        indentifier: "maryland",
#        nickname: "Terrapins",
#        location: "Maryland",
#        full_name: "Maryland Terrapins",
#        url: "/college-football/teams/team-page.cfm/team/maryland"
#      },
#      record: {
#        overall_wins: 6,
#        overall_losses: 7,
#        home_wins: 4,
#        home_losses: 2,
#        away_wins: 2,
#        away_losses: 5
#      },
#      grouping: {
#        conference: "Big Ten Conference",
#        division: nil
#      }
#   },
#   ...
# ]
```

### 1.2 Getting Current Games

```ruby
VegasInsiderScraper::NCAAFB.new.current_games

# [
#    ...,
#   { 
#     time: 2017-09-03 19:30:00 -400,
#     doubleheader: nil,
#     home_team: 'north-carolina-state',
#     away_team: 'south-carolina',
#     vegas_info: {
#       away_moneyline: -135.0,
#       home_moneyline: 115.0,
#       away_line: -5,
#       home_line: 5,
#       over_under: 167.5  
#     }
#     notes: "Time change to 3:00pm EDT | TV: ESPN, DTV: 206",
#   }
#   ...
# ]
```

### 1.3 Getting Schedule of Games

```ruby
VegasInsiderScraper::NCAAFB.new.team_schedules

# [
#   ...,
#   {
#     team: 'alabama',
#     games: [
#       #<ScraperLeague::Game:...>,
#       ...
#     ]
#   }
#   ...,
# ]

VegasInsiderScraper::NCAAFB.new.team_schedule_for('alabama')

# {
#   team: 'alabama',
#   games: [
#     #<ScraperLeague::Game:...>,
#     ...
#   ]
# }
```
