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

To start using, simply instantiate a VegasInsiderScraper object to access all leagues

```ruby
scraper = VegasInsiderScraper.new
```

or for a specific league

```ruby
mlb_scraper = VegasInsiderScraper::MLB.new
```

Available leagues are NCAAFB, NCAABB, NFL, MLB, NBA, NHL

### 1.1 Getting Teams

To get the teams for a sport, simply call teams on a ScraperSport

If you created a generic VegasInsiderScraper, you can access the sports array, containing all of the ScraperSports. By calling teams on any of these ScraperSports, you will instantiate the teams.

```ruby
scraper.sports.each do |sport|
  sport.teams
end

sports.first.teams

# [
#	  ...,
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

or for a specific league

```ruby
mlb_scraper.teams

# [
#   {
#      info: {
#        indentifier: "giants",
#        nickname: "Giants",
#        location: "San Francisco",
#        full_name: "San Francisco Giants",
#        url: "/mlb/teams/team-page.cfm/team/giants"
#      },
#      record: {
#        overall_wins: 27,
#        overall_losses: 49,
#        home_wins: "14",
#        home_losses: "19",
#        away_wins: "13",
#        away_losses: "30"
#      },
#      grouping: {
#        conference: "NATIONAL",
#        division: "WEST"
#      }
#   },
#   ...
# ]
```

### 1.2 Getting Current Games

To get the current (today's and future) games for a sport, simply call current_games on a ScraperSport

If you created a generic VegasInsiderScraper, you can access the sports array, containing all of the ScraperSports. By calling teams on any of these ScraperSports, you will instantiate the current_games.

```ruby
scraper.sports.each do |sport|
  sport.current_games
end

sports.first.current_games

# [
#	  ...,
#   { 
#     time: 2017-09-03 19:30:00 -400,
#     doubleheader: nil,
#     home_team: 'north-carolina-state',
#     away_team: 'south-carolina',
#     home_team_odds: -5.0,
#     away_team_odds: 5.0,
#     over_under: "176.5",
#     sport_id: 0,
#     notes: "Time change to 3:00pm EDT | TV: ESPN, DTV: 206",
#   }
#   ...
# ]
```

or for a specific league

```ruby
mlb_scraper.current_games

# [
#	  ...,
#   { 
#     time: 2017-06-24 22:10:00 -400,
#     doubleheader: nil,
#     home_team: 'padres',
#     away_team: 'tigers',
#     home_team_odds: -1.5,
#     away_team_odds: 1.5,
#     over_under: "8.5",
#     sport_id: 4,
#     notes: "TV: FS-Detroit, FS-San Diego, DTV: 663, 694",
#   }
#   ...
# ]
```

### 1.3 Getting Schedule of Games

By getting the schedule of games, you will be retriving the entire schedule and results for each team in the league, by calling:

```ruby
scraper.sports.first.team_schedules

# [
#   ...,
#   {
#     team: 'alabama',
#     games: [
#       ...
#     ]
#   }
#   ...,
# ]
```
