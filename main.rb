require "twitter"
require "dotenv"
require "prime"
require "./lib/time.rb"
require "./lib/cheesecake.rb"
require "./lib/weather.rb"
require "./lib/region.rb"
require "./lib/weather_image.rb"
require "./lib/sukiya.rb"
require "./lib/weather_week.rb"
require "./lib/gsic_calender.rb"

Dotenv.load

client = Twitter::REST::Client.new do |config|
  config.consumer_key        = ENV["MY_CONSUMER_KEY"]
  config.consumer_secret     = ENV["MY_CONSUMER_SECRET"]
  config.access_token        = ENV["MY_ACCESS_TOKEN"]
  config.access_token_secret = ENV["MY_ACCESS_TOKEN_SECRET"]
end

begin
  old = 0
  File.open('./tmp/old_id.txt',"r") do |file|
    file.each_line do |old_id|
      old = old_id.to_i
    end
  end
rescue SystemCallError => e
  puts %Q(class=[#{e.class}] message=[#{e.message}])
rescue IOError => e
  puts %Q(class=[#{e.class}] message=[#{e.message}])
end

is_first = true

client.mentions_timeline(count: 10).each do |tweet|
  if (is_first)
    begin
      File.open("./tmp/old_id.txt", "w") do |f| 
        f.puts(tweet.id.to_s)
      end
    rescue SystemCallError => e
      puts %Q(class=[#{e.class}] message=[#{e.message}])
    rescue IOError => e
      puts %Q(class=[#{e.class}] message=[#{e.message}])
    end
    is_first = false
  end

  po = tweet.id.to_i
  break if po == old

  unless /RT/ === tweet.text
    if /@_nagatea|[Oo][Kk]ながてぃー|ね[えぇ]ながてぃー/ === tweet.text && tweet.user.screen_name != "_nagatea"
      if /天気/ === tweet.text || /てんき/ === tweet.text
        if /週間/ === tweet.text
          if /..[都道府県]/ === tweet.text
            po = tweet.text.match(/(..)[都道府県]/)
            url = Region.new("week").get_url(po[1])
            weather_week = WeatherWeek.new(url)
          else
            weather_week = WeatherWeek.new()
          end
          content = "@#{tweet.user.screen_name}\n#{weather_week.get_master}"
          contents = content.scan(/.{1,140}/m)
          client.update(contents[0], options = {:in_reply_to_status_id => tweet.id})
        else
          if /..[都道府県]/ === tweet.text
            po = tweet.text.match(/(..)[都道府県]/)
            url = Region.new("yoho").get_url(po[1])
            weather = Weather.new(url)
            url = Region.new("jikei").get_url(po[1])
            weather_image = WeatherImage.new(url)
          else
            weather = Weather.new()
            weather_image = WeatherImage.new()
            url = Region.new("jikei").get_url("東京")
          end
          if /明後日/ === tweet.text || /あさって/ === tweet.text
            content = "@#{tweet.user.screen_name} #{weather.get_master("day_after_tomorrow")}"
            contents = content.scan(/.{1,140}/m)
            client.update(contents[0], options = {:in_reply_to_status_id => tweet.id})
          elsif /明日/ === tweet.text || /あ(した|す)/ === tweet.text
            content = "@#{tweet.user.screen_name} #{weather.get_master("tomorrow")}"
            contents = content.scan(/.{1,140}/m)
            client.update(contents[0], options = {:in_reply_to_status_id => tweet.id}) 
          else
            content = "@#{tweet.user.screen_name} #{weather.get_master("today")}"
            contents = content.scan(/.{1,140}/m)
            weather_image.get_image
            client.update_with_media("@#{tweet.user.screen_name}\n#{contents[0]}\n\n画像は気象庁ホームページ(#{url})より", File.open("./tmp/po.png"), options = {:in_reply_to_status_id => tweet.id})
          end
        end
      elsif /図書館|地図/ === tweet.text || /チー?ズケー?キ?/ === tweet.text|| /[おぽ]うち/ === tweet.text || /としょかん/ === tweet.text
        cheese = Cheesecake.new
        if /明日/ === tweet.text
          content = cheese.get_cheesecake(cheese.get_next_month,cheese.get_next_day)
          contents = content.scan(/.{1,140}/m)
          client.update("@#{tweet.user.screen_name} #{contents[0]}", options = {:in_reply_to_status_id => tweet.id}) 
        elsif /\d?\d日/ === tweet.text
          if /\d?\d月\d?\d日/ === tweet.text
            mon = tweet.text.match(/(\d?\d)月/)
            date = tweet.text.match(/(\d?\d)日/)
            content = cheese.get_cheesecake(mon[1],date[1])
          else
            date = tweet.text.match(/(\d?\d)日/)
            content = cheese.get_cheesecake(cheese.get_month,date[1]) 
          end
          contents = content.scan(/.{1,140}/m)
          client.update("@#{tweet.user.screen_name} #{contents[0]}", options = {:in_reply_to_status_id => tweet.id}) 
        elsif /\d?\d\/\d?\d/ === tweet.text
          mon = tweet.text.match(/(\d?\d)\/\d?\d/)
          date = tweet.text.match(/\d?\d\/(\d?\d)/)
          content = cheese.get_cheesecake(mon[1],date[1])
          contents = content.scan(/.{1,140}/m)
          client.update("@#{tweet.user.screen_name} #{contents[0]}", options = {:in_reply_to_status_id => tweet.id}) 
        else
          content = cheese.get_cheesecake(cheese.get_month,cheese.get_day)
          contents = content.scan(/.{1,140}/m)
          client.update("@#{tweet.user.screen_name} #{contents[0]}", options = {:in_reply_to_status_id => tweet.id}) 
        end
      elsif /(から|に)[1１一]番近い/ === tweet.text
        point = tweet.text.match(/(.+)(?:から|に)[1１一]番近い/)
        destination = tweet.text.match(/(?:から|に)[1１一]番近い(.+)/)
        if point == nil || destination == nil
          num = Random.rand(6..10)
          key = ((0..9).to_a + ("a".."z").to_a + ("A".."Z").to_a).sample(num).join
          content = "FLAG{#{key}}"
          client.update("@#{tweet.user.screen_name} #{content}", options = {:in_reply_to_status_id => tweet.id})
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
            client.update_with_media("@#{tweet.user.screen_name}\n#{content}", File.open("./tmp/po.png"), options = {:in_reply_to_status_id => tweet.id})
          else
            client.update("@#{tweet.user.screen_name} #{content}", options = {:in_reply_to_status_id => tweet.id})
          end
        end
      elsif /演習室/ === tweet.text || /計算機室/ === tweet.text || /GSIC/ === tweet.text || /gsic/ === tweet.text
        gsic = GSICCalender.new
        if /明日/ === tweet.text
          tomorrow = Time.now + (33*60*60)
          content = "@#{tweet.user.screen_name} \n#{gsic.get_schedule(tomorrow.month, tomorrow.day)}"
          contents = content.byteslice(0, 279).scrub("")
          client.update(contents, options = {:in_reply_to_status_id => tweet.id}) 
        elsif /\d?\d日/ === tweet.text
          if /\d?\d月\d?\d日/ === tweet.text
            mon = tweet.text.match(/(\d?\d)月/)
            day = tweet.text.match(/(\d?\d)日/)
            content = gsic.get_schedule(mon[1], day[1])
          else
            today = JSTTime.time
            day = tweet.text.match(/(\d?\d)日/)
            content = gsic.get_schedule(today.month, day[1])
          end
          content = "@#{tweet.user.screen_name} \n#{content}"
          contents = content.byteslice(0, 279).scrub("")
          client.update(contents, options = {:in_reply_to_status_id => tweet.id}) 
        elsif /\d?\d\/\d?\d/ === tweet.text
          mon = tweet.text.match(/(\d?\d)\/\d?\d/)
          day = tweet.text.match(/\d?\d\/(\d?\d)/)
          content = "@#{tweet.user.screen_name} \n#{gsic.get_schedule(mon[1],day[1])}"
          contents = content.byteslice(0, 279).scrub("")
          client.update(contents, options = {:in_reply_to_status_id => tweet.id}) 
        else
          content = "@#{tweet.user.screen_name} \n#{gsic.get_schedule()}"
          contents = content.byteslice(0, 279).scrub("")
          client.update(contents, options = {:in_reply_to_status_id => tweet.id}) 
        end
      elsif /\d+$/ === tweet.text
        num = tweet.text.match(/(\d+)$/)
        po = Prime.prime_division(num[1])
        content = ""
        po.each do |popo|
          content << "#{popo[0]}^#{popo[1]} * "
        end
        contents = content[0..-3]
        client.update(contents, options = {:in_reply_to_status_id => tweet.id})
      else
        if (JSTTime.time.sec.to_i % 10) == 0
          client.favorite(tweet.id)
        else
          client.update("@#{tweet.user.screen_name} ふぇぇ、わからないよぅ><", options = {:in_reply_to_status_id => tweet.id})
        end
      end
    end
  end
end
