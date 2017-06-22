
class NCAABB < ScraperLeague

	def initialize
		@sport_id = 1
		@sport_name = 'college-basketball'
		super
	end

	# def get_nicknames
	# 	start_time = Time.now
	# 	num_successes = 0
	# 	Team.ncaabb_teams.each_with_index do |team, i|
	# 		url = "http://www.vegasinsider.com/college-basketball/teams/team-page.cfm/team/#{team.vegas_insider_identifier}"
	# 		nickname = Scraper.scrape_team_page_for_nickname(team.vegas_insider_identifier, url)
	# 		team.nickname = nickname
	# 		team.save
	# 	end
	# 	Time.now - start_time
	# end

end