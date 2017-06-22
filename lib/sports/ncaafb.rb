require_relative 'scraper_league'

class NCAAFB < ScraperLeague

	def initialize
		@sport_id = 0
		@sport_name = 'college-football'
		super
	end

	# def get_nicknames
	# 	start_time = Time.now
	# 	Team.where(sport_id: 0).each_with_index do |team, i|
	# 		next if team.nickname
	# 		url = "http://www.vegasinsider.com/college-football/teams/team-page.cfm/team/#{team.vegas_insider_identifier}"
	# 		nickname = Scraper.scrape_team_page_for_nickname(team.vegas_insider_identifier, url)
	# 		team.nickname = nickname
	# 		team.save
	# 	end
	# 	Time.now - start_time
	# end

	# def get_locations
	# 	start_time = Time.now
	# 	Team.where(sport_id: 0, custom_team_flag: 1).each_with_index do |team, i|
	# 		team.location = nil
	# 		team.save
	# 	end
	# 	Time.now - start_time
	# end

	# def scrape_custom_team_page_for_location(vegas_identifier, url)
	# 	doc = Nokogiri::HTML(open(url))
	# 	title = doc.at_css('h1.page_title').content.gsub(' Team Page', '')
	# 	return title
	# end

	# def remove_nickname_from_location
	# 	start_time = Time.now
	# 	Team.where(sport_id: 0).each_with_index do |team, i|
	# 		puts team.location
	# 		puts team.location.gsub(" #{team.nickname}", '')
	# 	end
	# 	Time.now - start_time
	# end

	# def scrape_fcs_teams
	# 	url = 'http://www.vegasinsider.com/college-football/teams/'
	# 	doc = Nokogiri::HTML(open(url))

	# 	current_conference = nil
	# 	fcs = []

	# 	doc.css('.main-content-cell table table table').each_with_index do |col,i|
	# 		col.css('tr').each do |row|
	# 			new_conference = row.at_css('td.viSubHeader1')

	# 			if new_conference
	# 				current_conference = new_conference.content
	# 			else
	# 				team = row.at_css('a')
	# 				if team 
	# 					team_formatted = { 
	# 						team_name: team.content,
	# 						team_url_id: team_url_parser(team.attribute('href')),
	# 						conference: current_conference,
	# 						league: sport_id
	# 					}
	# 					puts team_formatted
	# 					fcs.push team_formatted
	# 				end
	# 			end
	# 		end
	# 	end

	# 	Team.save_teams(fcs)
	# 	return true

	# end

end