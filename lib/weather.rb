require 'open-uri'
require 'nokogiri'

class Weather
  def initialize(url = 'http://www.jma.go.jp/jp/yoho/319.html')
    @url = url
    charset = nil
    html = open(@url) do |f|
          charset = f.charset
          f.read
    end
    @doc = Nokogiri::HTML.parse(html, nil, charset)
  end

  def get_region #場所を取得する
    region = @doc.xpath("//title").to_s
    region.slice!(/<\/title>/)
    region.slice!(/.+\n：\s/)
    return region
  end

  def get_date(day) #日付を取得する
    case day
      when "today" then
        tds = @doc.xpath("//th[@class='weather']")
      when "tomorrow" then
        tds = @doc.xpath("//tr[3]/th[@class='weather']")
      when "day_after_tomorrow"
        tds = @doc.xpath("//tr[4]/th[@class='weather']")
    end
    date = tds[0].to_s
    date.slice!(/<th class="weather">\n/)
    date.slice!(/\n<\/th>/)
    date.slice!(/<br>.+/)
    return date
  end

  def get_weather(day) #天気(名前)を取得する
    case day
      when "today" then
        tds = @doc.xpath("//th[@class='weather']")
      when "tomorrow" then
        tds = @doc.xpath("//tr[3]/th[@class='weather']")
      when "day_after_tomorrow"
        tds = @doc.xpath("//tr[4]/th[@class='weather']")
    end
    wea = tds[0].to_s
    weather = wea.match(/title="(.+)" alt/)
    return weather[1]
  end

  def get_max_temperature(day) #最高気温を取得する
    case day
      when "today" then
        tds = @doc.xpath("//td[@class='temp']")
      when "tomorrow" then
        tds = @doc.xpath("//tr[3]/td[@class='temp']")
      when "day_after_tomorrow"
        tds = @doc.xpath("//tr[4]/td[@class='temp']")
    end
    max = tds[0].to_s
    max_temp = max.match(/<td class="max">(.+度)\n?\t?\t?\t?<\/td>/)
    if max_temp != nil
      return max_temp[1]
    else
      return "not"
    end
  end

  def get_min_temperature(day) #最低気温を取得する
    case day
      when "today" then
        tds = @doc.xpath("//td[@class='temp']")
      when "tomorrow" then
        tds = @doc.xpath("//tr[3]/td[@class='temp']")
      when "day_after_tomorrow"
        tds = @doc.xpath("//tr[4]/td[@class='temp']")
    end
    min = tds[0].to_s
    min_temp = min.match(/<td class="min">(.+度)\n?\t?\t?\t?<\/td>/)
    if min_temp != nil
      return min_temp[1]
    else
      return "not"
    end
  end

  def get_rain(day) #降水確率を取得する
    case day
      when "today" then
        tds = @doc.xpath("//table[@class='rain']")
      when "tomorrow" then
        tds = @doc.xpath("//tr[3]/td/div/table[@class='rain']")
      when "day_after_tomorrow"
        return "不明"
    end
    rain = tds[0].to_s
    rain.slice!(/<table class="rain">/)
    rain.slice!(/<\/table>/)
    rain.delete!("<tr>")
    rain.delete!("<td align=\"left\">")
    rain.delete!("<td align=\"right\">")
    rain.delete!("</td>")
    rain.delete!("</tr>")
    rain1 = rain.scan(/\d\d-\d\d/)
    rain2 = rain.scan(/.?.?.%/)
    rain_resurt = "#{rain1[0]}　#{rain2[0]}\n#{rain1[1]}　#{rain2[1]}\n#{rain1[2]}　#{rain2[2]}\n#{rain1[3]}　#{rain2[3]}\n"
    return rain_resurt
  end

  def get_comment(day) #概況を取得する
    case day
      when "today" then
        tds = @doc.xpath("//td[@class='info']")
      when "tomorrow" then
        tds = @doc.xpath("//tr[3]/td[@class='info']")
      when "day_after_tomorrow"
        tds = @doc.xpath("//tr[4]/td[@class='info']")
    end
    com = tds[0].to_s
    com.slice!(/<td class="info">/)
    com.slice!(/<\/td>/)
    com.slice!(/<br>波.+/)
    com.gsub!(/<br>/,"\n")
    com.gsub!(/[\s　]/,"\s")
    return com
  end

  def get_master(day) #天気のまとめを取得する
    region = self.get_region
    date = self.get_date(day)
    weather = self.get_weather(day)
    rain = self.get_rain(day)
    com = self.get_comment(day)
    if self.get_min_temperature(day) != "not"
      min_temp = "最低気温は#{self.get_min_temperature(day)}\n"
    else
      min_temp = ""
    end
    if self.get_max_temperature(day) != "not"
      max_temp = "最高気温は#{self.get_max_temperature(day)}\n"
    else
      max_temp = ""
    end
    content = "#{region}の#{date}の天気は、#{weather}\n" + min_temp + max_temp + "\n降水確率は\n#{rain}\n#{com}"
    contents = content.scan(/.{1,140}/m)
    return contents[0]
  end

  def get_weather_name(day, name) #天気を含んだ垢名を取得する
    case day
      when "today" then
        date = ""
      when "tomorrow" then
        date = "明日:"
      when "day_after_tomorrow"
        date = "明後日:"
    end
    weather_title = self.get_weather(day)
    weather_title.gsub!(/晴れ/,"☀")
    weather_title.gsub!(/曇り/,"☁")
    weather_title.gsub!(/雨/,"☔")
    weather_title.gsub!(/雪/,"⛄")
    weather_title.gsub!(/止む/,"🌂")
    weather_title.gsub!(/後/,"/")
    weather_title.gsub!(/時々/,"|")
    weather_title.gsub!(/\/\|/,"/時々")
    username = "#{name} (#{date}" + weather_title + ")"
    return username
  end
end
