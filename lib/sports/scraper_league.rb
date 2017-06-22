require 'nokogiri'
require 'open-uri'

class ScraperLeague

	attr_reader :sport_id
	attr_reader :sport_name
	attr_reader :moneyline_sport
	attr_reader :teams

	def initialize
		@moneyline_sport = false
		@teams ||= scrape_standings
	end

	# Gets the upcoming/current games for the sport
	def current_games
		@current_games ||= get_lines("http://www.vegasinsider.com/#{sport_name}/odds/las-vegas/")
	end

	# Gets all of the schedule and results for each team
	def team_schedules
		@team_schedules ||= teams.map { |team|
			puts " ### GETTING GAMES FOR:   #{team[:info][:full_name]}"
			url = "http://www.vegasinsider.com/#{sport_name}/teams/team-page.cfm/team/#{team[:info][:identifier]}"
			scrape_team_page(url, team[:info][:identifier])
		}
	end

	private

	######################################################
	# Gets the teams and scrapes the records for the teams
	def scrape_standings
		standings_teams = []

		url = "http://www.vegasinsider.com/#{sport_name}/standings/"
		doc = Nokogiri::HTML(open(url)).at_css('.main-content-cell')
		teams_doc = Nokogiri::HTML(open(url.gsub('standings','teams'))).at_css('.main-content-cell')

		doc.css(standings_table_class).each do |conference|

			conference_title = conference.at_css(".viHeaderNorm")
			next if conference_title.nil?
			table = conference.css('.viBodyBorderNorm table')[standings_table_index]

			if table
				table.css('tr').each_with_index do |row, index|
					next if (row.at_css('.viSubHeader1') != nil || row.at_css('.viSubHeader2') != nil)
					standings_teams.push(scrape_standings_row(row, conference_division_parser(conference_title.content), teams_doc))
				end
			end
		end
		standings_teams
	end

	# Utility method for scraping standings
	# * gets the standings table class
	def standings_table_class
		college_sport? ? '.SLTables1' : 'table' 
	end

	# Utility method for scraping standings
	# * gets the index of the table
	def standings_table_index
		college_sport? ? 1 : 0
	end

	# Utility method for scraping standings
	# * gets the standings table class
	def conference_division_parser(title)
		if college_sport?
			return { conference: title, division: nil }
		else
			result = /(?<conference>.+) - (?<division>.+)/.match(title)
			return { conference: result[:conference], division: result[:division] }
		end
	end


	# Utility method for scraping standings
	# * is a college sport?
	def college_sport?
		['college-football','college-basketball'].include?(sport_name)
	end

	# Utility method for scraping standings
	# * scrapes a row of the standings, chooses a helper method based on the league
	def scrape_standings_row(row, grouping, teams_doc)
		team_shell = { info: {}, record: {} }
		team = case sport_id
		when 0,1 then college_standings_row_parser(row, team_shell, teams_doc)
		when 2 then nfl_standings_row_parser(row, team_shell)
		when 3,4 then pro_standings_row_parser(row, team_shell)
		when 5 then hockey_standings_row_parser(row, team_shell)
		end
		team[:grouping] = grouping
		team
	end

	# Utility method for scraping standings
	# * scrapes a row of the standings, for COLLEGE sports
	def college_standings_row_parser(row, team, teams_doc)
		row.css('td').each_with_index do |cell, cell_index|
			value = remove_element_whitespace(cell)
			case cell_index
			when 0 then team[:info] = format_college_team(cell.at_css('a'), teams_doc)
			when 5 then team[:record][:overall_wins]   = value.to_i
			when 6 then team[:record][:overall_losses] = value.to_i
			when 9 then team[:record][:home_wins]		  = value.to_i
			when 10 then team[:record][:home_losses]   = value.to_i
			when 13 then team[:record][:away_wins] 		= value.to_i
			when 14 then team[:record][:away_losses] 	= value.to_i
			end
		end
		return team
	end

	# Utility method for scraping standings
	# * scrapes a row of the standings, for NFL
	def nfl_standings_row_parser(row, team)
		row.css('td').each_with_index do |cell, cell_index|
			content = remove_element_whitespace(cell)

			case cell_index
			when 0 then team[:info] = format_team(cell.at_css('a'))
			when 1 then team[:record][:overall_wins]   = content.to_i
			when 2 then team[:record][:overall_losses] = content.to_i
			when 3 then team[:record][:overall_ties]	  = content.to_i
			when 7
				record = RegularExpressions::NFL_RECORD_REGEX.match(content)
				team[:record][:home_wins] = record[:wins]
				team[:record][:home_losses] = record[:losses]
				team[:record][:home_ties] = record[:ties]
			when 8
				record = RegularExpressions::NFL_RECORD_REGEX.match(content)
				team[:record][:away_wins] = record[:wins]
				team[:record][:away_losses] = record[:losses]
				team[:record][:away_ties] = record[:ties]
			end
		end
		return team
	end

	# Utility method for scraping standings
	# * scrapes a row of the standings, for PRO (MLB)
	def pro_standings_row_parser(row, team)
		puts team
		row.css('td').each_with_index do |cell, cell_index|
			content = remove_element_whitespace(cell)

			case cell_index
			when 0 then team[:info] = format_team(cell.at_css('a'))
			when 1 then team[:record][:overall_wins] = content.to_i
			when 2 then team[:record][:overall_losses] = content.to_i
			when 5 
				record = RegularExpressions::RECORD_REGEX.match(content)
				team[:record][:home_wins]	= record[:wins]
				team[:record][:home_losses]	= record[:losses]
			when 6
				record = RegularExpressions::RECORD_REGEX.match(content)
				team[:record][:away_wins]	= record[:wins]
				team[:record][:away_losses]	= record[:losses]
			end
		end
		return team
	end

	# Utility method for scraping standings
	# * scrapes a row of the standings, for NHL
	def hockey_standings_row_parser(row, team)
		row.css('td').each_with_index do |cell, cell_index|
			content = remove_element_whitespace(cell)
			
			case cell_index
			when 0 then team[:info] = format_team(cell.at_css('a'))
			when 1 then team[:record][:overall_wins] = content.to_i
			when 2 then team[:record][:overall_losses] = content.to_i
			when 3 then team[:record][:over_time_losses] = content.to_i
			when 4 then team[:record][:shootout_losses] = content.to_i
			when 5 then team[:record][:points] = content.to_i
			when 8 
				record = RegularExpressions::NHL_RECORD_REGEX.match(content)	
				team[:record][:home_wins] = record[:wins]
				team[:record][:home_losses] = record[:losses]
				team[:record][:home_over_time_losses] = record[:ot_losses]
				team[:record][:home_shootout_losses] = record[:shootout_losses]
			when 9
				record = RegularExpressions::NHL_RECORD_REGEX.match(content)	
				team[:record][:away_wins] = record[:wins]
				team[:record][:away_losses] = record[:losses]
				team[:record][:away_over_time_losses] = record[:ot_losses]
				team[:record][:away_shootout_losses] = record[:shootout_losses]
			end
		end
		return team
	end

	# Utility method for scraping standings
	# * formats the team using the URL
	def format_team(url)
		full_name = url.content
		identifier = team_url_parser(url.attribute('href'))
		nickname = identifier.capitalize

		return {
			identifier: identifier,
			nickname: nickname,
			location: full_name.gsub(" #{nickname}", ''),
			full_name: full_name,
			url: url.attribute('href').value
		}
	end

	# Utility method for scraping standings
	# * formats the team using the URL and the Nokogiri document for the teams page
	def format_college_team(url, teams_doc)
		full_name = team_page_full_name(teams_doc, url)
		location = url.content
		identifier = team_url_parser(url.attribute('href'))
		nickname = full_name.gsub("#{location} ",'')

		return {
			identifier: identifier,
			nickname: nickname,
			location: location,
			full_name: full_name,
			url: url.attribute('href').value
		}
	end

	# Utility method for scraping standings
	# * gets the full team name using the teams page
	def team_page_full_name(doc,url)
		doc.at_css("a[href='#{url.attribute('href')}']").content
	end

	##########################################
	# Gets the current lines for a given sport
	def get_lines(url)
		games = []
		doc = Nokogiri::HTML(open(url))
		doc.css('.viBodyBorderNorm .frodds-data-tbl tr').each do |game_row|

			game_cell = game_row.at_css('td:first-child')
			game = {teams: game_cell_parser(game_cell), odds: nil, notes: nil, time: nil, sport_id: sport_id}

			if teams_found?(game)
				game[:time] = get_game_time(game_cell)
				odds = get_odds(game_row)
				game[:odds] = regular_lines(odds)
				games.push game
			else
				if games.last
					games.last[:notes] = game_cell.content
					doubleheader = doubleheader?(game_cell.content)
					if doubleheader then games.last[:doubleheader] = doubleheader[:id] end

				end
			end
		end
		games
	end

	# Utility method for scraping current lines
	# * find the identifier for each team
	def game_cell_parser(cell)
		cell.css('b a').map { |team| team_url_parser(team.attribute('href')) }
	end

	# Utility method for scraping current lines
	# * did the cell contain 2 teams?
	def teams_found?(game)
		game[:teams].size > 0
	end

	# Utility method for scraping current lines
	# * getting the time of the game
	def get_game_time(cell)
		time = RegularExpressions::TIME_REGEX.match(cell.at_css('span').content.to_s)
		year = ((Date.today.month > time[:mo].to_i) && (Date.today.month - 1 != time[:mo].to_i)) ? Date.today.year + 1 : Date.today.year

		ENV['TZ'] = 'US/Eastern'
		time = Time.strptime("#{year} #{time[:mo]} #{time[:d]} #{time[:h]}:#{time[:mi]}:00 #{time[:mer]}", "%Y %m %d %r")
		ENV['TZ'] = nil
		time
	end

	# Utility method for scraping current lines
	# * getting odds from the cell, removing whitespace, and converting 1/2 to 0.5
	def get_odds(odds_element)
		(odds_element.at_css('td:nth-child(3) a').content || '').gsub(" ","").gsub("½",".5").strip
	end

	# Utility method for scraping current lines
	# * parsing the lines for moneyline sports
	def moneyline_odds(odds_string)
		over_under = RegularExpressions::MONEYLINE_OVER_UNDER.match(odds_string) || {}
		odds = RegularExpressions::MONEYLINE_ODDS.match(odds_string) || {}
		
		{
			over_under: over_under[:ou],
			home_line: odds_reader(odds[:home_line]),
			away_line: odds_reader(odds[:away_line]),
		}
	end

	# Utility method for scraping current lines
	# * parsing the lines for non-moneyline sports
	def regular_lines(odds_string)
		away_fav_odds = RegularExpressions::ODDS.match(odds_string) || {}
		home_fav_odds = RegularExpressions::ALT_ODDS.match(odds_string) || {}
			
		result = {
			home_line: (home_fav_odds[:line] ? -odds_reader(home_fav_odds[:line]) : odds_reader(away_fav_odds[:line])),
			away_line: (away_fav_odds[:line] ? -odds_reader(away_fav_odds[:line]) : odds_reader(home_fav_odds[:line])),
			over_under: (home_fav_odds[:ou] || away_fav_odds[:ou])
		}
	end

	# Utility method for scraping current lines
	# * parsing the odds to get a number
	def odds_reader(odds)
		case odds when '' then nil when 'PK' then 0 else odds.to_f end
	end

	# Utility method for scraping current lines
	# * is the game a doubleheader?
	def doubleheader?(content)
		RegularExpressions::DOUBLEHEADER.match(content)
	end

	################################################
	# Gets the schedule and results for a team page
	def scrape_team_page(url, team)

		results = Nokogiri::HTML(open(url)).css('.main-content-cell table:nth-child(5) table').css('tr').each_with_index.map do |row,index|
			
			game = {}
			next if index == 0
			row.css('td').each_with_index do |cell,m|

				case m
				when 0 then game[:date] = get_game_date(cell,row)
				when 1 then game[:info] = get_game_info(cell)
				end

				if game_finished?(row)
					case m
					when 2
						unless moneyline_sport
							formatted = odds_reader(remove_element_whitespace(cell))
							game[:odds] = { home: formatted, away: (formatted ? -formatted : formatted) }
						end

					when 3 then game[:odds][:over_under] = remove_element_whitespace(cell)
					when 4 then game[:game_results] = game_result(cell)
					when 5 then game[:spread_results] = ats_results(cell)
					end
				end
			end
			game
		end
		{ team: team, schedule: results }
	end

	# Utility method for scraping team page results
	# * gets the date of the game, accounting for different years
	def get_game_date(date_string, row)
		date = Date.strptime(date_string.content.gsub!(/\s+/, ""), "%b%e")
		if game_finished?(row) && date.month > Date.today.month
			date = Date.new(Date.today.year - 1, date.month, date.day)
		elsif !game_finished?(row) && date.month < Date.today.month
			date = Date.new(Date.today.year + 1, date.month, date.day)
		end
		date
	end

	# Utility method for scraping team page results
	# * determines if the game has concluded
	def game_finished?(row)
		"#{RegularExpressions::GAME_RESULTS.match(remove_element_whitespace(row.at_css('td:nth-child(5)')))}" != ''
	end 

	# Utility method for scraping team page results
	# * gets the opponent identifier, location
	def get_game_info(cell)
		url = cell.at_css('a')
		doubleheader = RegularExpressions::RESULTS_DOUBLEHEADER.match(cell.content)
		{
			doubleheader: doubleheader ? doubleheader[:id] : nil,
			opponent_identifier: url ? team_url_parser(url.attribute('href')) : custom_opponent_identifier(cell),
			game_location: remove_element_whitespace(cell)[0] == "@" ? :away : :home
		}
	end

	# Utility method for scraping team page results
	# * gets the result of the game
	def game_result(cell)
		results = RegularExpressions::GAME_RESULTS.match(remove_element_whitespace(cell))
		{
			result: results&.names&.include?(:res) ? results[:res].downcase.to_sym : nil,
			score: results&.names&.include?(:team_score) ? results[:team_score] : nil,
			opponent_score: results&.names&.include?(:oppo_score) ? results[:oppo_score] : nil
		}
	end

	# Utility method for scraping team page results
	# * gets the spread results
	def ats_results(cell)
		results = RegularExpressions::SPREAD_RESULTS.match(remove_element_whitespace(cell))
		{
			ats_result: results&.names&.include?(:ats_result) ? results[:ats_result].downcase.to_sym : nil,
			ou_result: results&.names&.include?(:ou_result) ? results[:ou_result].downcase.to_sym : nil
		}
	end

	# Utility method for scraping team page results
	# * gets the identifier for an opponent without links
	def custom_opponent_identifier(cell)
		cell.content.strip.gsub(/(\s| )+/, '-').gsub('@-').downcase[0..-3]
	end

	# General Utility Method
	# used the get the team identifier from the URL
	def team_url_parser(url)
		/.+\/team\/(?<team_name>(\w|-)+)/.match(url)[:team_name]
	end

	# General Utility Method
	# used the remove all whitespace from the content of the element
	def remove_element_whitespace(element)
		string = element.content.gsub(/(\s| )+/, '')
		string.empty? ? nil : string
	end

	# Regular Expressions Module
	module RegularExpressions
		RECORD_REGEX = /(?<wins>\d+)-(?<losses>\d+)/
		NFL_RECORD_REGEX = /(?<wins>\d+)-(?<losses>\d+)-(?<ties>\d+)/
		NHL_RECORD_REGEX = /(?<wins>\d+)-(?<losses>\d+)-(?<ot_losses>\d+)-(?<shootout_losses>\d+)/

		TIME_REGEX = /(?<mo>\d{2})\/(?<d>\d{2})  (?<h>\d+):(?<mi>\d{2}) (?<mer>\w{2})/
		MONEYLINE_OVER_UNDER = /(?<ou>\d+(\.5)?)[ou]/x
		MONEYLINE_ODDS = /(?<away_line>.+(\.5)?)\/.\d{3}(?<home_line>.+(\.5)?)\/.\d{3}/x
		ODDS = /-?(?<line>\w+(\.5)?)-\d\d(?<ou>\d+(\.5)?)[ou]-\d\d/x
		ALT_ODDS = /(?<ou>\d+(\.5)?)[ou]-\d\d-?(?<line>\w+(\.5)?)-\d\d/x
		
		DOUBLEHEADER = /DH Gm (?<id>\d)/
		RESULTS_DOUBLEHEADER = /\(DH (?<id>\d)\)/

		GAME_RESULTS = /(?<res>\w+).(?<team_score>\d+)-(?<oppo_score>\d+)|Postponed|Cancelled/
		SPREAD_RESULTS = /((?<ats_result>\w+).\/.)?(?<ou_result>\w+)/
	end
end