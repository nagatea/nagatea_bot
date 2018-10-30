require 'google/apis/calendar_v3'
require 'holiday_jp'
require 'dotenv'

Dotenv.load

class GSICCalender
  def initialize
    @now = Time.now + (60*60*9) # 取得される時間はUTC基準なのでJST基準にするために9時間分早めます
    @service = Google::Apis::CalendarV3::CalendarService.new
    @service.key = ENV['GOOGLE_API_KEY']
    @cal_id = [
      "rqkupr0k7lgj12ivlvc5see4eg@group.calendar.google.com",
      "4av6summgq488m1cqp4s1q725c@group.calendar.google.com",
      "o0m2vspdbh9dr76p6f7kh9ijj8@group.calendar.google.com",
      "9b0sqrke1hapu12ic1km7emt30@group.calendar.google.com",
      "abnbg2sl6jfnnv6tu7dl0cckoo@group.calendar.google.com",
      "5f5sjo2k6n8ubgbgnd4tlq2cro@group.calendar.google.com",
      "n35dca8h4debrmcf6rr6s77mlk@group.calendar.google.com",
      "vgatlrhevppp14mob1mih3v0ec@group.calendar.google.com",
      "78tla3kl68g1ntiqjrglqe3fbk@group.calendar.google.com",
      "q4mnorg15jg4p68kgvl1cc21fg@group.calendar.google.com"
    ]
  end

  def get_schedule(mon = @now.month, day = @now.day)
    unless Date.valid_date?(@now.year, mon.to_i, day.to_i) #例外処理
      res = "#{mon}月#{day}日は存在しませんが"
      return res
    end
    time = Time.new(@now.year, mon.to_i, day.to_i, @now.hour, @now.min, @now.sec, nil)
    
    if HolidayJp.holiday?(Date.new(time.year, mon.to_i, day.to_i))
      return "#{mon}月#{day}日は祝日なのでお休みです"
    elsif time.saturday?
      return "#{mon}月#{day}日は土曜日なのでお休みです"
    elsif time.sunday?
      return "#{mon}月#{day}日は日曜日なのでお休みです"
    end
    
    time_min = (time - 60*60*time.hour).iso8601
    time_max = (time + 60*60*(23 - time.hour)).iso8601 #ガバガバ
    options = {order_by: 'startTime', single_events: true, time_min: time_min, time_max: time_max}

    events = []
    @cal_id.each do |cid|
      events.push(@service.list_events(cid, options))
    end

    i = 0
    res = "#{time.month}月#{time.day}日の予定"
    tmp = ""
    events.each do |event|
      i = i + 1
      if i%2 != 0
        tmp = event.items.map {|eve|
          eve.start.date_time.strftime("%H:%M") + "-" + eve.end.date_time.strftime("%H:%M") + "\s講義"
        }.join("\n")
        if tmp == ""
          tmp = "予定なし"
        end
        tmp.gsub!(/09:00-12:15/,"1-4限")
        tmp.gsub!(/13:20-16:35/,"5-8限")
        tmp.gsub!(/09:00-10:30/,"1-2限")
        tmp.gsub!(/10:45-12:15/,"3-4限")
        tmp.gsub!(/13:20-14:50/,"5-6限")
        tmp.gsub!(/15:05-16:35/,"7-8限")
      else
        title = "\n\n#{event.summary}\n"
        po = event.items.map {|eve|
          "\n" + eve.start.date_time.strftime("%H:%M") + "-" + eve.end.date_time.strftime("%H:%M") + "\s#{eve.summary}"
        }.join("\n")
        if po == ""
          res = res + title + tmp
        else
          res = res + title + tmp + po
        end
      end
    end

    return res
  end
end