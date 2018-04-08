require 'open-uri'
require 'json'

Encoding.default_external = 'utf-8'

#ENV['SSL_CERT_FILE'] = File.expand_path('./../cacert.pem')

YAHOO_ID = ENV['YAHOO']

class Sukiya
  def initialize(point, destination)
    @point = point
    @destination = destination
  end

  def get_point_hash #return->Array [lon,lat]
    search = @point
    tmp = "https://map.yahooapis.jp/search/local/V1/localSearch?appid=#{YAHOO_ID}&query=#{search}&sort=match&results=1&output=json"
    url = URI.encode(tmp)
    json = OpenURI.open_uri(url).read
    @point_hash = JSON.parse(json)
    return @point_hash
  end

  def get_point_name
    name = @point_hash["Feature"][0]["Name"]
    return name
  end

  def get_point_geometry #->Array[lon,lat]
    geo = @point_hash["Feature"][0]["Geometry"]["Coordinates"]
    res = geo.split(",")
    return res
  end

  def get_destination_hash
    search = @destination
    array = self.get_point_geometry
    lon = array[0]
    lat = array[1]
    tmp = "https://map.yahooapis.jp/search/local/V1/localSearch?appid=#{YAHOO_ID}&query=#{search}&lat=#{lat}&lon=#{lon}&dist=20&sort=dist&results=1&output=json"
    url = URI.encode(tmp)
    json = OpenURI.open_uri(url).read
    @destination_hash = JSON.parse(json)
    return @destination_hash
  end

  def get_destination_name
    name = @destination_hash["Feature"][0]["Name"]
    return name
  end

  def get_destination_geometry #->Array[lon,lat]
    geo = @destination_hash["Feature"][0]["Geometry"]["Coordinates"]
    res = geo.split(",")
    return res
  end

  def get_distance
    point = self.get_point_geometry
    destination = self.get_destination_geometry
    tmp = "https://map.yahooapis.jp/dist/V1/distance?appid=#{YAHOO_ID}&coordinates=#{point[0]},#{point[1]}\s#{destination[0]},#{destination[1]}&output=json"
    url = URI.encode(tmp)
    json = OpenURI.open_uri(url).read
    hash = JSON.parse(json)
    distance = hash["Feature"][0]["Geometry"]["Distance"].to_f * 1000
    return distance
  end

  def get_image
    begin
      point = self.get_point_geometry
      destination = self.get_destination_geometry
      tmp = "https://map.yahooapis.jp/course/V1/routeMap?appid=#{YAHOO_ID}&route=#{point[1]},#{point[0]},#{destination[1]},#{destination[0]}&width=800&height=450"
      open(tmp) do |file|
        open("./tmp/po.png", "w+b") do |out|
          out.write(file.read)
        end
      end
      return true
    rescue => exception
      return false
    end
  end

  def run
    begin
      self.get_point_hash
      self.get_destination_hash
      name = self.get_destination_name
      distance = self.get_distance.to_i
      res = "#{@point}から一番近い#{@destination}は、#{name}で、直線距離にして#{distance}mです。"
      return res
    rescue => exception
      return "そんなの知らない"
    end
  end

  def debug
    p_name = self.get_point_name rescue "エラー"
    p_geo = self.get_point_geometry rescue "エラー"
    d_name = self.get_destination_name rescue "エラー"
    d_geo = self.get_destination_geometry rescue "エラー"
    res = "p_name = #{p_name}\np_geo = #{p_geo}\nd_name = #{d_name}\nd_geo = #{d_geo}"
    return res
  end
end

