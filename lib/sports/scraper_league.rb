require 'nokogiri'
require 'open-uri'

class ScraperLeague

  attr_reader :sport_id
  attr_reader :sport_name
  attr_reader :moneyline_sport
  attr_reader :teams

  def initialize
    @moneyline_sport = false
  end

  def teams
    @teams ||= standings
  end

  def standings
    @standings ||= scrape_standings
  end

  # Gets the upcoming/current games for the sport
  def current_games
    @current_games ||= get_lines(["http://www.vegasinsider.com/#{sport_name}/odds/las-vegas/","http://www.vegasinsider.com/#{sport_name}/odds/las-vegas/money/"])
  end

  # Gets all of the schedule and results for each team
  def team_schedules
    @team_schedules ||= teams.map { |team|
      puts " ### GETTING GAMES FOR:   #{team[:info][:full_name]}"
      url = "http://www.vegasinsider.com/#{sport_name}/teams/team-page.cfm/team/#{team[:info][:identifier]}"
      scrape_team_page(url, team[:info][:identifier])
    }
  end

  def live_scores
    @live_scores = get_live_scores("https://web.archive.org/web/20170704205945/http://www.vegasinsider.com/mlb/scoreboard/")
    nil
  end

  private

  def scrape_teams
    url = "http://www.vegasinsider.com/#{sport_name}/teams/"
    doc = Nokogiri::HTML(open(url)).at_css('.main-content-cell')

    doc.css('a').map do |team_link|
    	team = {}
      team[:info] = format_college_team(team_link, doc)

      row = team_link.parent.parent.previous
      while !(row.at_css('td') && row.at_css('td').attributes['class'].value.include?('viSubHeader1'))
        row = row.previous
      end
      team[:grouping] = { conference: row.at_css('td').content }
      team
    end
  end

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
      table = conference.css('.viBodyBorderNorm table')[2] if (conference_title.content == 'Conference USA' && sport_name == 'college-football')

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
    sport_name == "college-football" ? '.SLTables1' : 'table' 
  end

  # Utility method for scraping standings
  # * gets the index of the table
  def standings_table_index
    sport_name == "college-football" ? 1 : 0
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
    when 0 then ncaafb_standings_row_parser(row, team_shell, teams_doc)
    when 1 then ncaabb_standings_row_parser(row, team_shell, teams_doc)
    when 2 then nfl_standings_row_parser(row, team_shell)
    when 3,4 then pro_standings_row_parser(row, team_shell)
    when 5 then hockey_standings_row_parser(row, team_shell)
    end
    team[:grouping] = grouping
    team
  end

  # Utility method for scraping standings
  # * scrapes a row of the standings, for NCAAFB
  def ncaafb_standings_row_parser(row, team, teams_doc)
    row.css('td').each_with_index do |cell, cell_index|
      value = remove_element_whitespace(cell)
      case cell_index
      when 0 
        team[:info] = format_college_team(cell.at_css('a'), teams_doc)
      when 1 then team[:record][:conf_wins]   = value.to_i
      when 2 then team[:record][:conf_losses] = value.to_i
      when 5 then team[:record][:overall_wins]   = value.to_i
      when 6 then team[:record][:overall_losses] = value.to_i
      when 9 then team[:record][:home_wins]      = value.to_i
      when 10 then team[:record][:home_losses]   = value.to_i
      when 13 then team[:record][:away_wins]     = value.to_i
      when 14 then team[:record][:away_losses]   = value.to_i
      end
    end
    return team
  end

  # Utility method for scraping standings
  # * scrapes a row of the standings, for NCAABB
  def ncaabb_standings_row_parser(row, team, teams_doc)
    row.css('td').each_with_index do |cell, cell_index|
      value = remove_element_whitespace(cell)
      case cell_index
      when 0 
        team[:info] = format_college_team(cell.at_css('a'), teams_doc)
      when 1 then team[:record][:overall_wins]   = value.to_i
      when 2 then team[:record][:overall_losses] = value.to_i
      when 5 
        record = RegularExpressions::RECORD_REGEX.match(value) || { wins: 0, losses: 0 }
        team[:record][:home_wins]  = record[:wins].to_i
        team[:record][:home_losses]  = record[:losses].to_i
      when 6
        record = RegularExpressions::RECORD_REGEX.match(value) || { wins: 0, losses: 0 }
        team[:record][:away_wins]  = record[:wins].to_i
        team[:record][:away_losses]  = record[:losses].to_i
      when 7
        record = RegularExpressions::RECORD_REGEX.match(value) || { wins: 0, losses: 0 }
        team[:record][:conf_wins]  = record[:wins].to_i
        team[:record][:conf_losses]  = record[:losses].to_i
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
      when 3 then team[:record][:overall_ties]    = content.to_i
      when 7
        record = RegularExpressions::NFL_RECORD_REGEX.match(content) || { wins: 0, losses: 0, ties: 0 }
        team[:record][:home_wins] = record[:wins]
        team[:record][:home_losses] = record[:losses]
        team[:record][:home_ties] = record[:ties]
      when 8
        record = RegularExpressions::NFL_RECORD_REGEX.match(content) || { wins: 0, losses: 0, ties: 0 }
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
    row.css('td').each_with_index do |cell, cell_index|
      content = remove_element_whitespace(cell)

      case cell_index
      when 0 then team[:info] = format_team(cell.at_css('a'))
      when 1 then team[:record][:overall_wins] = content.to_i
      when 2 then team[:record][:overall_losses] = content.to_i
      when 5 
        record = RegularExpressions::RECORD_REGEX.match(content) || { wins: 0, losses: 0 }
        team[:record][:home_wins]  = record[:wins]
        team[:record][:home_losses]  = record[:losses]
      when 6
        record = RegularExpressions::RECORD_REGEX.match(content) || { wins: 0, losses: 0 }
        team[:record][:away_wins]  = record[:wins]
        team[:record][:away_losses]  = record[:losses]
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
        record = RegularExpressions::NHL_RECORD_REGEX.match(content) || { wins: 0, losses: 0, ot_losses: 0, shootout_losses: 0 }
        team[:record][:home_wins] = record[:wins]
        team[:record][:home_losses] = record[:losses]
        team[:record][:home_over_time_losses] = record[:ot_losses]
        team[:record][:home_shootout_losses] = record[:shootout_losses]
      when 9
        record = RegularExpressions::NHL_RECORD_REGEX.match(content) || { wins: 0, losses: 0, ot_losses: 0, shootout_losses: 0 }
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
    nickname = humanize_identifier(identifier)

    {
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
    location = url.content.gsub('AM', 'A&M').gsub('AT', 'A&T')
    identifier = team_url_parser(url.attribute('href'))
    nickname = full_name.gsub("#{location} ",'')

    if nickname == full_name
      nickname = full_name.gsub('&','').gsub("#{humanize_identifier(identifier)}", '').strip
    end

    if nickname == full_name.gsub('&','').strip
      nickname_array = nickname.split(' ')
      nickname = nickname_array.each_slice( (nickname_array.size/2.0).round ).to_a[1].join(' ')
      nickname = nickname_exceptions(identifier,nickname)
    end

    return {
      identifier: identifier,
      nickname: nickname,
      location: full_name.gsub(" #{nickname}", ''),
      full_name: full_name,
      url: url.attribute('href').value
    }
  end

  def humanize_identifier(identifier)
    identifier.split('-').map { |x| x.capitalize }.join(' ')
  end

  def nickname_exceptions(identifier,nickname)
    case identifier
    when 'california-state-long-beach' then '49ers'
    when 'texas-am-corpus-christi' then 'Islanders'
    when 'southern-am' then 'Jaguars'
    when 'saint-marys-college-california' then 'Gaels'
    else nickname end
  end

  # Utility method for scraping standings
  # * gets the full team name using the teams page
  def team_page_full_name(doc,url)
    doc.at_css("a[href='#{url.attribute('href')}']").content
  end

  ##########################################
  # Gets the current lines for a given sport
  def get_live_scores(url)
    doc = Nokogiri::HTML(open(url))

    date = doc.at_css('.ff_txt2 tr:nth-child(2) font')
    date = Date.strptime(date.content, '%a, %b %d') if date

    games = []

    doc.css('.SLTables4 table > tr').each do |row|

      date_row = row.attribute('valign')

      if date_row
        date = parse_score_date(row)
      else

        row.css('.yeallowBg .sportPicksBorder').each do |game|

          result = {}
          game.css('.tanBg a').each_with_index do |team, i|
            if i == 0 
              result[:away_team] = team_url_parser(team.attribute('href'))
            else
              result[:home_team] = team_url_parser(team.attribute('href'))
            end
          end

          game_status = remove_element_whitespace(game.at_css('.sub_title_red'), true)
          game_status = case
            when game_status == 'Final Score' then :ended
            when game_status == 'PPD' then :Postponed
            when game_status == '' then :Cancelled
            when game_status.include?('Game Time') then nil
            else game_status end

          if game_status
            segment_titles = []
            game.css('.sportPicksBg td').each_with_index do |col,i|
              puts remove_element_whitespace(col)
              next if ['Teams', 'Odds', 'ATS', ''].include?(remove_element_whitespace col)
              segment_titles.push remove_element_whitespace col
            end

            away_values = []
            game.css('.tanBg')[0].css('td').each_with_index do |col,i|
              next if i < 3
              away_values.push remove_element_whitespace(col).to_i
            end
            away_values.pop

            home_values = []
            game.css('.tanBg')[1].css('td').each_with_index do |col,i|
              next if i < 3
              home_values.push remove_element_whitespace(col).to_i
            end
            home_values.pop

          end

          if segment_titles
            result[:scoring] = segment_titles.each_with_index.map { |s,i| 
              { period: s, away: away_values[i], home: home_values[i] } 
            }
          end

          result[:status] = game_status
          result[:date] = date

          games.push(result)
        end
      end

    end
    return games
  end

  def parse_score_date(element)
    str = remove_element_whitespace(element, true).gsub(/Week\s+\d+\s+-\s/,'')
    Date.strptime(str, '%A %B %d, %Y')
  end

  ##########################################
  # Gets the current lines for a given sport
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
          game.update(vegas_info: get_line(get_odds_inner_html(game_row)))

        elsif is_first_url
          last_game = games.last
          if last_game then last_game.update(notes: (last_game.notes ? "#{last_game.notes} / " : '') + game_cell.content) end
        end
      end
    }
    games
  end

  # Utility method for scraping current lines
  # * find the identifier for each team
  def game_cell_parser(cell)
    cell.css('b a').map { |team| team_url_parser(team.attribute('href')) }
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
    (odds_element.at_css('td:nth-child(3) a')&.content || '').gsub(" ","").gsub("½",".5").strip
  end
  def get_odds_inner_html(odds_element)
    ((odds_element.at_css('td:nth-child(3) a'))&.inner_html || '').encode('utf-8').gsub(" ","").gsub("½",".5").strip
  end

  # Utility method for scraping current lines
  # * parsing the lines for non-moneyline sports
  def get_line(odds_string)
    odds_string = odds_string.gsub('PK', '-0')
    odds = matchdata_to_hash(RegularExpressions::ODDS.match(odds_string)) || {}
    runlines_odds = matchdata_to_hash(RegularExpressions::RUNLINE_ODDS.match(odds_string)) || {}
    moneyline_odds = matchdata_to_hash(RegularExpressions::MONEYLINE_ODDS.match(odds_string)) || {}

    result = odds.merge(runlines_odds).merge(moneyline_odds)

    result.each { |k,v| result[k] = result[k].to_s.to_f if result[k] }
    get_home_and_away(result)

  end

  # Utility method for scraping current lines
  # * filling the home/away lines
  def get_home_and_away(result)
    result['away_line'] = -result['home_line'] if result['home_line']
    result['home_line'] = -result['away_line'] if result['away_line']
    result
  end

  # Utility method for scraping current lines
  # * parsing the odds to get a number
  def odds_reader(odds)
    case odds&.strip when '',nil then nil when 'PK' then 0 else odds.to_f end
  end

  # Utility method for scraping current lines
  # * is the game a doubleheader
  def doubleheader_id(content)
    dh = RegularExpressions::DOUBLEHEADER.match(content)
    dh ? dh[:id] : nil
  end

  ################################################
  # Gets the schedule and results for a team page
  def scrape_team_page(url, team)

    games = Nokogiri::HTML(open(url)).css('.main-content-cell table:nth-child(5) table').css('tr').each_with_index.map do |row,index|

      next if index == 0
      game = Game.new(vegas_info: {})
      opponent = nil

      row.css('td').each_with_index do |cell,m|

        case m
        when 0 then game.update(time: get_game_date(cell,row))
        when 1 
          info = get_game_info(cell, team)
          opponent = info[:opponent]
          game.update(info[:game_info])
        end

        if game_finished?(row)
          case m
          when 2
            formatted = odds_reader(remove_element_whitespace(cell))
            home_team  = (game.home_or_away_team(team) == :home)
            if moneyline_sport
              home_team ? game.update(vegas_info: {home_moneyline: formatted}) : game.update(vegas_info: {away_moneyline: formatted})
            else
              home_line = (formatted && !home_team) ? -formatted : formatted
              game.update(vegas_info: {home_line: home_line, away_line: (home_line ? -home_line : nil)})
            end

          when 3 then game.update(vegas_info: { over_under: remove_element_whitespace(cell)})
          when 4 then game.update(game_results(cell, team, opponent))
          when 5 then game.update(ats_results(cell, team, opponent))
          end
        end
      end
      game
    end
    { team: team, games: games.compact.map{ |game| game } }
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
    date.to_time
  end

  # Utility method for scraping team page results
  # * determines if the game has concluded
  def game_finished?(row)
    !"#{RegularExpressions::GAME_RESULTS.match(remove_element_whitespace(row.at_css('td:nth-child(5)')))}".empty?
  end 

  # Utility method for scraping team page results
  # * gets the home_team, away_team, and doubleheader info
  def get_game_info(cell, primary_team)
    url = cell.at_css('a')
    home_or_away = remove_element_whitespace(cell)[0] == "@" ? :away : :home
    opponent = url ? team_url_parser(url.attribute('href')) : custom_opponent_identifier(cell)

    {
      opponent: opponent,
      game_info: {
        doubleheader: matchdata_to_hash(RegularExpressions::RESULTS_DOUBLEHEADER.match(cell.content))['doubleheader'],
        home_team: home_or_away == :home ? primary_team : opponent,
        away_team: home_or_away == :away ? primary_team : opponent,
      }
    }
  end

  # Utility method for scraping team page results
  # * gets the result of the game
  def game_results(cell, primary_team, opponent)
    results = RegularExpressions::GAME_RESULTS.match(remove_element_whitespace(cell))
    results_hash = matchdata_to_hash(results)
    {
      ending: (results_hash['result'] ? :ended : results.to_s),
      winning_team: case results_hash['result'] when :won then primary_team when :lost then opponent else nil end,
      winning_score: case results_hash['result'] when :won then results['team_score'] when :lost then results['oppo_score'] else nil end,
      losing_score: case results_hash['result'] when :won then results['oppo_score'] when :lost then results['team_score'] else nil end,
    }
  end

  # Utility method for scraping team page results
  # * gets the spread results
  def ats_results(cell, primary_team, opponent)
    results = RegularExpressions::SPREAD_RESULTS.match(remove_element_whitespace(cell))
    results_hash = matchdata_to_hash(results)
    {
      ats_winner: case results_hash['ats_result'] when :win then primary_team when :loss then opponent else nil end,
      over_under_result: results_hash['ou_result']
    }
  end

  # Utility method for scraping team page results
  # * gets the identifier for an opponent without links
  def custom_opponent_identifier(cell)
    cell.content.strip.gsub(/(\s| )+/, '-').gsub('@-','').downcase[0..-2]
  end

  # General Utility Method
  # used the get the team identifier from the URL
  def team_url_parser(url)
    /.+\/team\/(?<team_name>(\w|-)+)/.match(url)[:team_name]
  end

  # General Utility Method
  # used the remove all whitespace from the content of the element
  def remove_element_whitespace(element, only_end = false)
    string = element.content.gsub(only_end ? /^(\s| )+|(\s| )+\z/ : /(\s| )+/, '')
    string.empty? ? '' : string
  end

  def matchdata_to_hash(matchdata)
    matchdata ? Hash[*matchdata.names.map{ |name| [name,(matchdata[name] ? matchdata[name].downcase.to_sym : nil)] }.flatten].compact : {}
  end

  # Regular Expressions Module
  module RegularExpressions
    RECORD_REGEX = /(?<wins>\d+)-(?<losses>\d+)/
    NFL_RECORD_REGEX = /(?<wins>\d+)-(?<losses>\d+)-(?<ties>\d+)/
    NHL_RECORD_REGEX = /(?<wins>\d+)-(?<losses>\d+)-(?<ot_losses>\d+)-(?<shootout_losses>\d+)/

    TIME_REGEX = /(?<mo>\d{2})\/(?<d>\d{2})  (?<h>\d+):(?<mi>\d{2}) (?<mer>\w{2})/
    MONEYLINE_OVER_UNDER = /(?<ou>\d+(\.5)?)[ou]/x

    ODDS = /(<br><br>(?<home_line>-\d+(\.5)?))|(<br>(?<away_line>-\d+(\.5)?)[+-]\d\d<br>)|
      ((?<over_under>\d+(\.5)?)[ou]((-\d{2})|EV)(?<home_line>-\d+(.5)?)-\d\d\z)|
      ((?<away_line>-\d+(.5)?)-\d\d(?<over_under>\d+(\.5)?)[ou]((-\d{2})|EV)\z)/x
    SOCCER_ODDS = /(?<away_line>(-|\+)?((-0)|(\d|\.)+))(((\+|-)\d\d)|(EV))(?<home_line>(-|\+)?((-0)|(\d|\.)+))(((\+|-)\d\d)|(EV))/
    SOCCER_MONEYLINE_ODDS = /(?<away_moneyline>(-|\+)\d+)(?<home_moneyline>(-|\+)\d+)(?<draw>(-|\+)\d+)(?<over_under>\d((\.5)|(\.25)|(\.75))?)(o|u).\d\d/
    RUNLINE_ODDS = /(?<away_line>(\+|-)\d+(\.5)?)\/(\+|-)\d{3}(?<home_line>(\+|-)\d+(\.5)?)\/(\+|-)\d{3}/
    MONEYLINE_ODDS = /((?<over_under>\d+(\.5)?)[ou]-\d{2})?(?<away_moneyline>(\+|-)\d{3}\d*)(?<home_moneyline>(\+|-)\d{3}\d*)/
    
    DOUBLEHEADER = /DH Gm (?<id>\d)/
    RESULTS_DOUBLEHEADER = /\(DH (?<doubleheader>\d)\)/

    GAME_RESULTS = /(?<result>\D+)(?<team_score>\d+)-(?<oppo_score>\d+)|(Postponed)|(Cancelled)/
    SPREAD_RESULTS = /((?<ats_result>\w+)\/)?(?<ou_result>\w+)/
  end

  class Game
    attr_reader :time, :away_team, :home_team, :vegas_info,
      :ending, :winning_team, :winning_score, :losing_score,
      :ats_winner, :over_under_result, :doubleheader, :notes

    def initialize(args = {})
      Game.sanitize(args).map { |attribute, value| instance_variable_set("@#{attribute}", value) }
    end

    def update(args = {})
      Game.sanitize(args).map { |attribute, value| 
        new_val = (attribute == :vegas_info && value && vegas_info) ? value.merge(vegas_info) : value
        instance_variable_set("@#{attribute}", new_val)
      }
      return self
    end

    def teams_found?
      home_team && away_team
    end

    def find_equal(games)
      games.detect { |g| g == self }
    end

    def ==(other_game)
      home_team == other_game.home_team && away_team == other_game.away_team && time.to_date == other_game.time.to_date && doubleheader == other_game.doubleheader
    end

    def home_or_away_team(team)
      case team
      when home_team then :home
      when away_team then :away
      else nil end
    end

    def as_json
      instance_variables.each_with_object({}) { |var, hash| hash[var.to_s.delete("@").to_sym] = instance_variable_get(var) }
    end

    private
    def self.sanitize(args)
      permitted_keys = [:time, :away_team, :home_team, :vegas_info,
        :ending, :winning_team, :winning_score, :losing_score,
        :ats_winner, :over_under_result, :doubleheader, :notes]
      args.select { |key,_| permitted_keys.include? key }
    end
  end

end

class Array
  def as_json(options = nil)
    map { |v| v.as_json }
  end
end

class Hash
  def compact
    self.select { |_, value| !value.nil? }
  end
end