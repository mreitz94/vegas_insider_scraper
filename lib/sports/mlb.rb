
class MLB < ScraperLeague

	def initialize
		@sport_id = 4
		@sport_name = :mlb
		@moneyline_sport = true
		super
	end

	def get_games
		urls = %w[http://www.vegasinsider.com/mlb/odds/las-vegas/ http://www.vegasinsider.com/mlb/odds/las-vegas/run]
		urls.each do |url|
			get_lines(url, sport_id)
		end
		return true
	end

end
