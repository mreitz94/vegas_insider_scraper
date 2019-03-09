
class Soccer < ScraperLeague
  def initialize
    @sport_id = 9
    @sport_name = :soccer
    super
    @moneyline_sport = true
  end

  def current_games
    @current_games ||= get_lines([
      "http://www.vegasinsider.com/#{sport_name}/odds/las-vegas/spread",
      "http://www.vegasinsider.com/#{sport_name}/odds/las-vegas/"
    ])
  end

  def teams
    []
  end

  def standings
    []
  end

  def team_schedules
    []
  end

  def live_scores
    []
  end

  private

  def get_lines(urls)
    games = []

    urls.each { |url|
      is_first_url = games.empty?
      doc = Nokogiri::HTML(open(url))
      doc.css('.viBodyBorderNorm .frodds-data-tbl tr').each do |game_row|
        game_cell = game_row.at_css('td:first-child')
        teams = game_cell_parser(game_cell)
        game = Game.new(home_team: teams[1], away_team: teams[0]) 

        if game.teams_found?
          game.update(time: get_game_time(game_cell))
          game.update(doubleheader: doubleheader_id(game_row.next&.next&.at_css('td:first-child')&.content))
          is_first_url ? (games.push game) : (game = game.find_equal(games))
          game.update(vegas_info: get_line(get_odds(game_row)))

        elsif is_first_url
          last_game = games.last
          if last_game then last_game.update(notes: (last_game.notes ? "#{last_game.notes} / " : '') + game_cell.content) end
        end
      end
    }
    games
  end

  def game_cell_parser(cell)
    cell.css('b').map(&:content)
  end

  def get_odds(odds_element)
    (odds_element.at_css('td:nth-child(3)')&.content || '')
      .gsub(' ', '')
      .gsub(/[[:space:]]/, '')
      .gsub('½','.5')
      .gsub('¼', '.25')
      .gsub('¾', '.75')
      .strip
  end

  def get_odds_inner_html(odds_element)
    ''
    # ((odds_element.at_css('td:nth-child(3) a'))&.inner_html || '').encode('utf-8').gsub(" ","").gsub("½",".5").strip
  end

  def get_line(odds_string)
    odds_string = odds_string.gsub('PK', '-0')
    result = matchdata_to_hash(RegularExpressions::SOCCER_MONEYLINE_ODDS.match(odds_string) || 
                               RegularExpressions::SOCCER_ODDS.match(odds_string))


    result.each { |k,v| result[k] = result[k].to_s.to_f if result[k] }
    get_home_and_away(result)
  end
end
