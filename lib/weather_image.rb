require 'open-uri'
require 'mechanize'

class WeatherImage
  def initialize(url = "http://www.jma.go.jp/jp/jikei/319.html")
    @url = url
    @agent = Mechanize.new
    @agent.max_history = 1
    @agent.open_timeout = 60
    @agent.read_timeout = 180
    @page = @agent.get(@url)
  end

  def get_title
    puts @page.search('title').inner_text
  end

  def get_image
    File.delete("./tmp/po.png") if FileTest.exist?("./tmp/po.png")
    src = @page.search("//img[@id='ASFC_IMAGE']").at('img')['src']
    @agent.get(src).save_as("./tmp/po.png")
  end
end