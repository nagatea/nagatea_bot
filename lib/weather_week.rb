require 'open-uri'
require 'mechanize'

Encoding.default_external = 'utf-8'

class WeatherWeek
  def initialize(url = "http://www.jma.go.jp/jp/week/319.html")
    @url = url
    @agent = Mechanize.new
    @agent.max_history = 1
    @agent.open_timeout = 30
    @agent.read_timeout = 60
    @page = @agent.get(@url)
  end

  def get_region #場所を取得する
    xpath = '//*[@id="infotablefont"]/caption'
    region = @page.search(xpath).inner_text
    res = region[/　(.+)/, 1]
    return res
  end

  def get_date(days) #日付を取得する
    day = days + 1
    xpath = "//*[@id='infotablefont']/tr[1]/th[#{day}]"
    date = @page.search(xpath).inner_text
    res = date[/(\d?\d)./, 1] + "(" + date[/\d?\d(.)/, 1] + ")"
    return res
  end

  def get_weather(day) #天気(名前)を取得する
    xpath = "//*[@id='infotablefont']/tr[2]/td[#{day}]"
    weather_title = @page.search(xpath).inner_text
    weather_title.gsub!(/晴れ?/,"☀")
    weather_title.gsub!(/曇り?/,"☁")
    weather_title.gsub!(/雨/,"☂")
    weather_title.gsub!(/雪/,"❄")
    weather_title.gsub!(/止む/,"🌂")
    weather_title.gsub!(/後|のち/,"/")
    weather_title.gsub!(/時々/,"|")
    weather_title.gsub!(/\/\|/,"/時々")
    weather_title.slice!(/\n/)
    return weather_title
  end

  def get_length(str) #天気の文字数を数える
    res = str.length
    res2 = 0
    if str.match(/\|/) != nil
      res = res - 1
      res2 = res2 + 1
    end
    if str.match(/\//) != nil
      res = res - 1
      res2 = res2 + 1
    end
    return [res, res2]
  end

  def get_rain(days)
    day = days + 1
    xpath = "//*[@id='infotablefont']/tr[3]/td[#{day}]"
    rain = @page.search(xpath).inner_text
    return rain
  end
  
  def get_reliable(days)
    day = days + 1
    xpath = "//*[@id='infotablefont']/tr[4]/td[#{day}]"
    reliable = @page.search(xpath).inner_text
    return reliable
  end

  def get_master #天気のまとめを取得する
    region = self.get_region
    data = []
    for i in 1..7 do
      hash = Hash.new
      hash["date"] = self.get_date(i).to_s
      hash["weather"] = self.get_weather(i)
      hash["length"] = self.get_length(hash["weather"])
      hash["rain"] = self.get_rain(i)
      hash["reliable"] = self.get_reliable(i)
      data.push(hash)
    end
    res = region + "\n"
    for i in 0..6 do
      z_count = 2-data[i]["length"][0]
      h_count = 2-data[i]["length"][1]
      z_count = 0 if z_count <= 0
      h_count = 0 if h_count <= 0
      res = res + data[i]["date"] + data[i]["weather"] + "　"*z_count + "\s"*h_count + data[i]["rain"] + "%(" + data[i]["reliable"] + ")\n"
    end
    return res
  end
end