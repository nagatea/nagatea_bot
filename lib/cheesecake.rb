require 'open-uri'
require 'mechanize'
require 'date'

class Cheesecake
  def get_day #今日の日付を取り出す
    date = DateTime.now + 0.375
    today = date.day 
    return today
  end

  def get_next_day #明日の日付を取り出す
    date = DateTime.now + 0.375
    tomorrow = date.next_day.day 
    return tomorrow
  end

  def get_month #今月の月を返す
    date = DateTime.now + 0.375
    mon = date.month
    return mon
  end
	
	def get_next_month
    date = DateTime.now + 0.375
    tomorrow = date.next_day.month
    return tomorrow
  end

  def get_cheesecake(mon = self.get_month, date = self.get_day) #チズケの閉館時間を取得する
    if Date.valid_date?(2018, mon.to_i, date.to_i)
      if mon.to_i < 10
        po = "0" + mon.to_s
      else
        po = mon.to_s
      end
      url = "https://www.libra.titech.ac.jp/calendar/2018#{po}"
      agent = Mechanize.new
      agent.max_history = 1
      agent.open_timeout = 30
      agent.read_timeout = 60
      page = agent.get(url)
      if page.title == "登録はまだされていません | 東京工業大学附属図書館"
        content = "#{mon.to_s}月分はまだ登録されていません"
        return content
      end
      xpath = "/html/body/div[5]/div/section/div/div/div/div[2]/div[1]/table/tbody/tr[#{date.to_s}]/td[3]"
      times = page.search(xpath).inner_text
      xpath = "/html/body/div[5]/div/section/div/div/div/div[2]/div[1]/table/tbody/tr[#{date.to_s}]/td[4]"
      other = page.search(xpath).inner_text
      if other == "          "
        others = ""
      else
        others = "\n備考：#{other}"
      end
      content = "#{mon}月#{date}日は#{times}#{others}"
    else
      content = "#{mon}月#{date}日は存在しませんが"
    end
    return content
  end
end

