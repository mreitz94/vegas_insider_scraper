
class NHL < ScraperLeague

	def initialize
		@sport_id = 5
		@sport_name = :nhl
		@moneyline_sport = false
		super
	end

	def get_games
		urls = %w[http://www.vegasinsider.com/nhl/odds/las-vegas/ http://www.vegasinsider.com/nhl/odds/las-vegas/puck]
		urls.each do |url|
			get_lines(url, sport_id)
			Game.save_games(games)
		end
	end
end