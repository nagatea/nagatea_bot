module JSTTime
  def self.time    # Notice: the return value is treated as UTC.
    return Time.now.utc + (60*60*9)
  end
  def self.timecode
    return time.strftime("[%Y/%m/%d %H時%M分%S秒]")
  end
end
