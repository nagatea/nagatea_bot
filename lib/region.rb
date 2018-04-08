class Region
  def initialize(ver = "yoho")
    @ver = ver
    @region = Hash.new
    @region["北海"] = 306 #北海道
    @region["青森"] = 308
    @region["秋田"] = 309
    @region["岩手"] = 310
    @region["山形"] = 311
    @region["宮城"] = 312
    @region["福島"] = 313
    @region["茨城"] = 314
    @region["群馬"] = 315
    @region["栃木"] = 316
    @region["埼玉"] = 317
    @region["千葉"] = 318
    @region["東京"] = 319
    @region["奈川"] = 320 #神奈川
    @region["山梨"] = 321
    @region["長野"] = 322
    @region["新潟"] = 323
    @region["富山"] = 324
    @region["石川"] = 325
    @region["福井"] = 326
    @region["静岡"] = 327
    @region["岐阜"] = 328
    @region["愛知"] = 329
    @region["三重"] = 330
    @region["大阪"] = 331
    @region["兵庫"] = 332
    @region["京都"] = 333
    @region["滋賀"] = 334
    @region["奈良"] = 335
    @region["歌山"] = 336 #和歌山
    @region["島根"] = 337
    @region["広島"] = 338
    @region["鳥取"] = 339
    @region["岡山"] = 340
    @region["香川"] = 341
    @region["愛媛"] = 342
    @region["徳島"] = 343
    @region["高知"] = 344
    @region["山口"] = 345
    @region["福岡"] = 346
    @region["佐賀"] = 347
    @region["長崎"] = 348
    @region["熊本"] = 349
    @region["大分"] = 350
    @region["宮崎"] = 351
    @region["児島"] = 352 #鹿児島
    @region["沖縄"] = 353
  end
  
  def get_url(key)
    if @region.key?(key)
      number = @region.fetch(key)
    else
      number = 319
    end
    url = "http://www.jma.go.jp/jp/#{@ver}/#{number}.html"
    return url
  end
end