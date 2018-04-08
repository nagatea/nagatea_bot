require "twitter"
require "./lib/time.rb"
require "./lib/cheesecake.rb"
require "./lib/weather.rb"
require "./lib/region.rb"
require "./lib/weather_image.rb"
require "./lib/sukiya.rb"
require "./lib/weather_week.rb"
require "./lib/gsic_calender.rb"

#↓ながてちーず↓
stream_client = Twitter::Streaming::Client.new do |config|
  config.consumer_key        = ENV["MY_CONSUMER_KEY"]
  config.consumer_secret     = ENV["MY_CONSUMER_SECRET"]
  config.access_token        = ENV["MY_ACCESS_TOKEN"]
  config.access_token_secret = ENV["MY_ACCESS_TOKEN_SECRET"]
end

client = Twitter::REST::Client.new do |config|
  config.consumer_key        = ENV["MY_CONSUMER_KEY"]
  config.consumer_secret     = ENV["MY_CONSUMER_SECRET"]
  config.access_token        = ENV["MY_ACCESS_TOKEN"]
  config.access_token_secret = ENV["MY_ACCESS_TOKEN_SECRET"]
end

#↓ながてぃー↓
stream_client2 = Twitter::Streaming::Client.new do |config|
  config.consumer_key        = ENV["MY_CONSUMER_KEY2"]
  config.consumer_secret     = ENV["MY_CONSUMER_SECRET2"]
  config.access_token        = ENV["MY_ACCESS_TOKEN2"]
  config.access_token_secret = ENV["MY_ACCESS_TOKEN_SECRET2"]
end

client2 = Twitter::REST::Client.new do |config|
  config.consumer_key        = ENV["MY_CONSUMER_KEY2"]
  config.consumer_secret     = ENV["MY_CONSUMER_SECRET2"]
  config.access_token        = ENV["MY_ACCESS_TOKEN2"]
  config.access_token_secret = ENV["MY_ACCESS_TOKEN_SECRET2"]
end

fav_retry ||= 0

#ながてぃーbot用処理
kusoripu = ""
ripu = []
client2.mentions_timeline(count: 200).each do |tweet|
  poyo = tweet.user.status.text.to_s
  if /\A@_nagatea / === poyo
    len = poyo.length.to_i
    po = poyo[10, len-1]
      if /@/ === po || /#/ === po || /twi/ === po || /http/ === po || /天気/ === po || /てんき/ === po || /チズケ/ === po || /図書館|地図/ === po || /[おぽ]うち/ === po || /としょかん/ === po || /近い/ === po || /gsic|GSIC|演習室/ === po || tweet.user.status.user.screen_name == "_nagatea"
      else
        #po = poyo.delete("@_nagatea ")
        contents = po.scan(/.{1,120}/m)
        ripu.push(contents[0])
      end
  end
end
ripu.shuffle!
cheese = Cheesecake.new
gsic = GSICCalender.new
#ながてぃーbot用処理おわり

if JSTTime.time.hour == 6
  client.update("おはよーございます\nauto_favotterを起動しました。\n#{JSTTime.timecode}")
  #content = "#{Weather.new.get_master("today")}"
  #contents = content.scan(/.{1,140}/m)
  #client.update(contents[0]) 
  #username = Weather.new.get_weather_name("tomorrow", "ながてちーず🍰")
  #client.update_profile(name: username)
else
  client.update("auto_favotterおよびながてぃーbotを再起動しました。\n#{JSTTime.timecode}")
end

fav = Thread.start {
  begin
    stream_client.user do |status|
      if status.is_a?(Twitter::Tweet)
        unless /RT/ === status.text
          client.favorite(status.id)
        end
      end
    end
    
  rescue => exception
    fav_retry += 1
    if fav_retry < 7
      #client.update("エラー発生(リトライ回数#{fav_retry}回目)\n#{exception.message}\n#{JSTTime.timecode}")
      puts("エラー発生(リトライ回数#{fav_retry}回目)\n#{exception.message}\n#{JSTTime.timecode}")
      retry if fav_retry < 7
    else
      client.update("@syobon_titech\nエラー発生\nリトライ回数が規定回数を超えたのでauto_favotterを強制終了します。\n#{exception.message}\n#{JSTTime.timecode}")
    end
  end
}

nagatea = Thread.start {
  begin
    stream_client2.user do |status2|
      if status2.is_a?(Twitter::Tweet)
        unless /RT/ === status2.text
          if /@_nagatea|[Oo][Kk]ながてぃー|ね[えぇ]ながてぃー/ === status2.text && status2.user.screen_name != "_nagatea"
            if /天気/ === status2.text || /てんき/ === status2.text
              if /週間/ === status2.text
                if /..[都道府県]/ === status2.text
                  po = status2.text.match(/(..)[都道府県]/)
                  url = Region.new("week").get_url(po[1])
                  weather_week = WeatherWeek.new(url)
                else
                  weather_week = WeatherWeek.new()
                end
                content = "@#{status2.user.screen_name}\n#{weather_week.get_master}"
                contents = content.scan(/.{1,140}/m)
                client2.update(contents[0], options = {:in_reply_to_status_id => status2.id})
              else
                if /..[都道府県]/ === status2.text
                  po = status2.text.match(/(..)[都道府県]/)
                  url = Region.new("yoho").get_url(po[1])
                  weather = Weather.new(url)
                  url = Region.new("jikei").get_url(po[1])
                  weather_image = WeatherImage.new(url)
                else
                  weather = Weather.new()
                  weather_image = WeatherImage.new()
                  url = Region.new("jikei").get_url("東京")
                end
                if /明後日/ === status2.text || /あさって/ === status2.text
                  content = "@#{status2.user.screen_name} #{weather.get_master("day_after_tomorrow")}"
                  contents = content.scan(/.{1,140}/m)
                  client2.update(contents[0], options = {:in_reply_to_status_id => status2.id})
                elsif /明日/ === status2.text || /あ(した|す)/ === status2.text
                  content = "@#{status2.user.screen_name} #{weather.get_master("tomorrow")}"
                  contents = content.scan(/.{1,140}/m)
                  client2.update(contents[0], options = {:in_reply_to_status_id => status2.id}) 
                else
                  content = "@#{status2.user.screen_name} #{weather.get_master("today")}"
                  contents = content.scan(/.{1,140}/m)
                  weather_image.get_image
                  client2.update_with_media("@#{status2.user.screen_name}\n#{contents[0]}\n\n画像は気象庁ホームページ(#{url})より", File.open("./tmp/po.png"), options = {:in_reply_to_status_id => status2.id})
                end
              end
            elsif /図書館|地図/ === status2.text || /チー?ズケー?キ?/ === status2.text|| /[おぽ]うち/ === status2.text || /としょかん/ === status2.text
              if /明日/ === status2.text
                content = cheese.get_cheesecake(cheese.get_next_month,cheese.get_next_day)
                contents = content.scan(/.{1,140}/m)
                client2.update("@#{status2.user.screen_name} #{contents[0]}", options = {:in_reply_to_status_id => status2.id}) 
              elsif /\d?\d日/ === status2.text
                if /\d?\d月\d?\d日/ === status2.text
                  mon = status2.text.match(/(\d?\d)月/)
                  date = status2.text.match(/(\d?\d)日/)
                  content = cheese.get_cheesecake(mon[1],date[1])
                else
                  date = status2.text.match(/(\d?\d)日/)
                  content = cheese.get_cheesecake(cheese.get_month,date[1]) 
                end
                contents = content.scan(/.{1,140}/m)
                client2.update("@#{status2.user.screen_name} #{contents[0]}", options = {:in_reply_to_status_id => status2.id}) 
              elsif /\d?\d\/\d?\d/ === status2.text
                mon = status2.text.match(/(\d?\d)\/\d?\d/)
                date = status2.text.match(/\d?\d\/(\d?\d)/)
                content = cheese.get_cheesecake(mon[1],date[1])
                contents = content.scan(/.{1,140}/m)
                client2.update("@#{status2.user.screen_name} #{contents[0]}", options = {:in_reply_to_status_id => status2.id}) 
              else
                content = cheese.get_cheesecake(cheese.get_month,cheese.get_day)
                contents = content.scan(/.{1,140}/m)
                client2.update("@#{status2.user.screen_name} #{contents[0]}", options = {:in_reply_to_status_id => status2.id}) 
              end
            elsif /(から|に)[1１一]番近い/ === status2.text
              point = status2.text.match(/(.+)(?:から|に)[1１一]番近い/)
              destination = status2.text.match(/(?:から|に)[1１一]番近い(.+)/)
              if point == nil || destination == nil
                num = Random.rand(6..10)
                key = ((0..9).to_a + ("a".."z").to_a + ("A".."Z").to_a).sample(num).join
                content = "FLAG{#{key}}"
                client2.update("@#{status2.user.screen_name} #{content}", options = {:in_reply_to_status_id => status2.id})
              else
                point[1].slice!(/.*@_nagatea\s?\n?/)
                destination[1].slice!(/\s?@_nagatea.*/)
                if point[1] == "おおお" || point[1] == "おおお駅" || point[1] == "大岡山"
                  tmp = "大岡山駅"
                else
                  tmp = point[1]
                end
                sukiya = Sukiya.new(tmp, destination[1])
                content = sukiya.run
                content2 = sukiya.debug
                if sukiya.get_image == true 
                  client2.update_with_media("@#{status2.user.screen_name}\n#{content}", File.open("./tmp/po.png"), options = {:in_reply_to_status_id => status2.id})
                else
                  client2.update("@#{status2.user.screen_name} #{content}", options = {:in_reply_to_status_id => status2.id})
                end
              end
            elsif /演習室/ === status2.text || /計算機室/ === status2.text || /GSIC/ === status2.text || /gsic/ === status2.text
              if /明日/ === status2.text
                tomorrow = Time.now + (33*60*60)
                content = "@#{status2.user.screen_name} \n#{gsic.get_schedule(tomorrow.month, tomorrow.day)}"
                contents = content.byteslice(0, 279).scrub("")
                client2.update(contents, options = {:in_reply_to_status_id => status2.id}) 
              elsif /\d?\d日/ === status2.text
                if /\d?\d月\d?\d日/ === status2.text
                  mon = status2.text.match(/(\d?\d)月/)
                  day = status2.text.match(/(\d?\d)日/)
                  content = gsic.get_schedule(mon[1], day[1])
                else
                  today = JSTTime.time
                  day = status2.text.match(/(\d?\d)日/)
                  content = gsic.get_schedule(today.month, day[1])
                end
                content = "@#{status2.user.screen_name} \n#{content}"
                contents = content.byteslice(0, 279).scrub("")
                client2.update(contents, options = {:in_reply_to_status_id => status2.id}) 
              elsif /\d?\d\/\d?\d/ === status2.text
                mon = status2.text.match(/(\d?\d)\/\d?\d/)
                day = status2.text.match(/\d?\d\/(\d?\d)/)
                content = "@#{status2.user.screen_name} \n#{gsic.get_schedule(mon[1],day[1])}"
                contents = content.byteslice(0, 279).scrub("")
                client2.update(contents, options = {:in_reply_to_status_id => status2.id}) 
              else
                content = "@#{status2.user.screen_name} \n#{gsic.get_schedule()}"
                contents = content.byteslice(0, 279).scrub("")
                client2.update(contents, options = {:in_reply_to_status_id => status2.id}) 
              end
            else
              if (JSTTime.time.sec.to_i % 10) == 0
                client2.favorite(status2.id)
              else
                kusoripu = ripu.pop
                client2.update("@#{status2.user.screen_name} #{kusoripu}", options = {:in_reply_to_status_id => status2.id})
              end
            end
          end
        end
      end
    end
    
  rescue => exception
    fav_retry += 1
    if fav_retry < 7
      #client2.update("エラー発生(リトライ回数#{fav_retry}回目)\n#{exception.message}\n#{JSTTime.timecode}")
      puts("エラー発生(リトライ回数#{fav_retry}回目)\n#{exception.message}\n#{exception.backtrace}\n#{JSTTime.timecode}")
      retry if fav_retry < 7
    else
      client.update("@syobon_titech\nエラー発生\nリトライ回数が規定回数を超えたので@_nagatea のクソリプを強制終了します。\n#{exception.message}\n#{JSTTime.timecode}")
    end
  end
}

if JSTTime.time.hour < 8
  while JSTTime.time.hour != 8
    sleep(60)
  end
end

if JSTTime.time.hour == 8
  content = "#{Weather.new.get_master("today")}"
  contents = content.scan(/.{1,140}/m)
  client.update(contents[0])
  username = Weather.new.get_weather_name("tomorrow", "ながてちーず🍰")
  client.update_profile(name: username)
end

if JSTTime.time.hour < 21
  while JSTTime.time.hour != 21
    sleep(60)
  end
end
if JSTTime.time.hour == 21
  content = "#{Weather.new.get_master("tomorrow")}"
  contents = content.scan(/.{1,140}/m)
  client.update(contents[0])
  username = Weather.new.get_weather_name("day_after_tomorrow", "ながてちーず🍰")
  client.update_profile(name: username)
end

while JSTTime.time.hour != 5
  sleep(60)
end
Thread.kill(fav)
Thread.kill(nagatea)
client.update("auto_favotterを停止しました。\nおやすみなさい( ˘ω˘)\n#{JSTTime.timecode}")
