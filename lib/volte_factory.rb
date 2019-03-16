require 'open-uri'
require 'mechanize'

class VolteFactory
  def initialize
    @agent = Mechanize.new
    @agent.max_history = 1
    @agent.open_timeout = 30
    @agent.read_timeout = 60
  end

  def get_shop_url(keyword="") # 何故か日によって店舗idが違うので検索からurlをとってくる
    return "https://p.eagate.573.jp" if keyword.empty?
    pref_list = [13, 14] # 13は東京都, 14は神奈川県
    shop_url = ""
    pref_list.each do |pref|
      url = "https://p.eagate.573.jp/game/sdvx/v/p/search/list.html?pref=#{pref}&search_word=#{URI.encode(keyword.encode('Shift_JIS'))}&pcb_cnt=0"
      page = @agent.get(url)
      page.encoding = 'Shift_JIS'
      xpath = '//*[@id="main_center_cnt"]/div[1]/div[5]/table/tr/td[3]/a'
      shop = page.search(xpath).attribute('href')
      shop_url = shop.value unless shop.nil?
      break unless shop_url.empty?
    end
    "https://p.eagate.573.jp" + shop_url
  end
  
  def get_zaiko(keyword)
    url = self.get_shop_url(keyword)
    return "店舗が見つかりませんでした" if url == "https://p.eagate.573.jp"
    page = @agent.get(url)
    page.encoding = 'Shift_JIS'
    xpath = '//*[@id="shopinfo_vp_shopname"]'
    shop_name = page.search(xpath).inner_text
    xpath = "//*[@id='vp_goods_info']"
    search = page.search(xpath).to_s.split("</div>")
    xpath = '//*[@id="chusen_goods_info"]'
    search = search + page.search(xpath).to_s.split("</div>")
    search.each do |tmp|
      tmp.gsub!(/<div.+l">/,"")
      tmp.encode!("UTF-8", "Shift_JIS")
      tmp.gsub!(/<.+\//,"")
      tmp.gsub!(/\..+>/,"")
      tmp.gsub!(/\s/, "")
      tmp.gsub!(/VIVIDWAVEオリジナルe-amusementpass/, "")
    end

    res = Array.new(4, "")

    for i in 0..2 do
      res[i] = "【残り#{search[i*7+5]}】#{search[i*7+1]}"
    end
    res[3] = "【残り#{search[3*7+3]}】#{search[3*7+1]}(抽選)"

    time = Time.now.strftime("%m/%d %H:%M")
    res.insert(0, "#{time}現在の#{shop_name}の在庫状況")

    res.join("\n")
  end
end

