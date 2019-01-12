require 'open-uri'
require 'mechanize'

class Cheesecake

  def initialize
    @now = Time.now
  end

  def get_cheesecake(month = @now.month, day = @now.day) #チズケの閉館時間を取得する
    unless Date.valid_date?(@now.year, month.to_i, day.to_i)
      return "#{month}月#{day}日は存在しませんが"
    end

    if month.to_i < 10
      mon = "0" + month.to_s
    else
      mon = month.to_s
    end
    url = "https://www.libra.titech.ac.jp/calendar/#{@now.year}#{mon}"
    
    agent = Mechanize.new
    agent.max_history = 1
    agent.open_timeout = 30
    agent.read_timeout = 60
    page = agent.get(url)

    if page.title == "登録はまだされていません | 東京工業大学附属図書館"
      return "#{month.to_s}月分はまだ登録されていません"
    end
    xpath = "/html/body/div[5]/div/section/div/div/div/div[2]/div[1]/table/tbody/tr[#{day}]/td[3]"
    times = page.search(xpath).inner_text.gsub(" ", "")
    xpath = "/html/body/div[5]/div/section/div/div/div/div[2]/div[1]/table/tbody/tr[#{day}]/td[4]"
    other = page.search(xpath).inner_text.strip
    if other.empty?
      others = ""
    else
      others = "\n備考：#{other}"
    end
    
    "#{month}月#{day}日は#{times}#{others}"
  end
end

