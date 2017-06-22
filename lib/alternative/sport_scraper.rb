require 'nokogiri'
require 'open-uri'

class SportScraper

	attr_reader :sport
	attr_reader :moneyline_sport
	attr_reader :teams
	
	def initialize(sport)
		@sport = sport
		initialize_teams
		@moneyline_sport = [:mlb,:nhl].include?(sport)
	end


	private
	def initialize_teams
		start = Time.now
		standings = StandingsScraper.new("http://www.vegasinsider.com/#{sport}/standings/", standings_type)
		@teams = standings.teams
		length = Time.now - start
		puts "%%%%%%%%% #{length} SECONDS TO COMPLETE #{length/@teams.length.to_f} per team"
	end

	def standings_type
		case sport
		when 'college-football', 'college-basketball' then :college
		when :nfl, :nba, :mlb, :nhl										then :professional
		end
	end

end

class StandingsScraper
	def initialize(url, standings_type)
		@doc ||= Nokogiri::HTML(open(url)).at_css('.main-content-cell')
		@teams_doc ||= Nokogiri::HTML(open(url.gsub('standings','teams'))).at_css('.main-content-cell')
		@standings_type = standings_type
	end

	def teams
		@teams ||=  case standings_type
								when :professional then pro_teams
								when :college then college_teams
								end
	end

	def standings
		teams
		@standings ||= (doc.css('.viBodyBorderNorm') || []).map { |division|  }
	end

	private 
	attr_reader :doc
	attr_reader :teams_doc
	attr_reader :standings_type

	def college_teams
		(doc.css('.SLTables1 .cellTextNorm a') || []).map { |url| ScraperUtilities.format_college_team(url, teams_doc) }
	end

	def pro_teams
		(doc.css('table a') || []).map { |url| ScraperUtilities.format_team(url) }
	end
end

module ScraperUtilities

	def self.format_team(url)
		full_name = url.content
		identifier = url_parser(url.attribute('href'))
		nickname = identifier.capitalize
		conference_division = url.ancestors('.viBodyBorderNorm').first.parent.parent.at_css('.viHeaderNorm').content

		return {
			identifier: identifier,
			nickname: nickname,
			location: full_name.gsub(" #{nickname}", ''),
			full_name: full_name,
			grouping: conference_division_parser(conference_division),
			url: url.attribute('href').value
		}
	end

	def self.format_college_team(url, teams_doc)
		full_name = team_page_full_name(teams_doc, url)
		location = url.content
		identifier = url_parser(url.attribute('href'))
		conference = url.ancestors('.SLTables1').first.at_css('.viHeaderNorm').content;
		division = url.parent.parent.parent.at_css('tr td.headerTextHot').content;
		nickname = full_name.gsub("#{location} ",'')

		return {
			identifier: identifier,
			nickname: nickname,
			location: location,
			full_name: full_name,
			grouping: {
				conference: conference,
				division: division
			},
			url: url.attribute('href').value
		}
	end

	def self.scrape_standings_row(row, team)
		case sport_id
		when 0,1 then college_standings_row_parser(row, team)
		when 2 then nfl_standings_row_parser(row, team)
		when 3,4 then pro_standings_row_parser(row, team)
		when 5 then hockey_standings_row_parser(row, team)
		end
	end

	def self.college_standings_row_parser(row, team)
		row.css('td').each_with_index do |cell, cell_index|
			value = cell.content.gsub(" ","")
			case cell_index
			when 0 then team = get_id_and_name(cell, team)
			when 5 then team[:overall_wins]   = value.to_i
			when 6 then team[:overall_losses] = value.to_i
			when 9 then team[:home_wins]		  = value.to_i
			when 10 then team[:home_losses]   = value.to_i
			when 13 then team[:away_wins] 		= value.to_i
			when 14 then team[:away_losses] 	= value.to_i
			end
		end
		return team
	end

	def self.nfl_standings_row_parser(row, team)
		row.css('td').each_with_index do |cell, cell_index|
			content = cell.content.gsub(" ","")
			case cell_index
			when 0 then team = get_id_and_name(cell, team)
			when 1 then team[:overall_wins]   = content.to_i
			when 2 then team[:overall_losses] = content.to_i
			when 3 then team[:overall_ties]	  = content.to_i
			when 7
				home_record = nfl_record_regex.match(content)
				team[:home_wins] = home_record[:wins]
				team[:home_losses] = home_record[:losses]
				team[:home_ties] = home_record[:ties]
			when 8
				away_record = nfl_record_regex.match(content)
				team[:away_wins] = away_record[:wins]
				team[:away_losses] = away_record[:losses]
				team[:away_ties] = away_record[:ties]
			end
		end
		return team
	end

	def self.pro_standings_row_parser(row, team)
		row.css('td').each_with_index do |cell, cell_index|
			content = cell.content.gsub(" ","")		
			case cell_index
			when 0 then team = get_id_and_name(cell, team)
			when 1 then team[:overall_wins] = content.to_i
			when 2 then team[:overall_losses] = content.to_i
			when 5 
				team[:home_wins]	= record_regex.match(content)[:wins]
				team[:home_losses]	= record_regex.match(content)[:losses]
			when 6
				team[:away_wins]	= record_regex.match(content)[:wins]
				team[:away_losses]	= record_regex.match(content)[:losses]
			end
		end
		return team
	end

	def self.hockey_standings_row_parser(row, team)
		row.css('td').each_with_index do |cell, cell_index|
			content = cell.content.gsub(" ","")		
			case cell_index
			when 0 then team = get_id_and_name(cell, team)
			when 1 then team[:overall_wins] = content.to_i
			when 2 then team[:overall_losses] = content.to_i
			when 3 then team[:over_time_losses] = content.to_i
			when 4 then team[:shootout_losses] = content.to_i
			when 5 then team[:points] = content.to_i
			when 8 
				home_record = hockey_record_regex.match(content)
				team[:home_wins] = home_record[:wins]
				team[:home_losses] = home_record[:losses]
				team[:home_over_time_losses] = home_record[:ot_losses]
				team[:home_shootout_losses] = home_record[:shootout_losses]
			when 9
				away_record = hockey_record_regex.match(content)
				team[:away_wins] = away_record[:wins]
				team[:away_losses] = away_record[:losses]
				team[:away_over_time_losses] = away_record[:ot_losses]
				team[:away_shootout_losses] = away_record[:shootout_losses]
			end
		end
		return team
	end

	def self.team_page_full_name(doc,url)
		doc.at_css("a[href='#{url.attribute('href')}']").content
	end

	def self.url_parser(url)
		/.+\/team\/(?<team_name>(\w|-)+)/.match(url)[:team_name]
	end

	def self.conference_division_parser(content)
		result = /(?<conference>.+) - (?<division>.+)/.match(content)
		return {
			conference: result[:conference],
			division: result[:division]
		}
	end

end

