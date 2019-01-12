require 'minitest/autorun'
require "../lib/cheesecake.rb"

class TestCheesecake < Minitest::Test
  def setup
    @cheese = Cheesecake.new
  end

  def test_get_cheesecake
    assert_match /\d?\d月\d?\d日は/, @cheese.get_cheesecake
  end

  def test_get_cheesecake_with_date
    month = Time.now.month
    next_month = month < 12 ? month + 1 : 1
    assert_match "#{month}月1日は", @cheese.get_cheesecake(month, 1)
    assert_match "#{next_month}月1日は", @cheese.get_cheesecake(next_month, 1)
  end

  def test_get_cheesecake_with_not_registered_date
    month = Time.now.month + 6
    month = month <= 12 ? month : month - 12
    assert_match "#{month}月分はまだ登録されていません", @cheese.get_cheesecake(month, 1)
  end

  def test_get_cheesecake_with_invalid_date
    assert_match "8月32日は存在しません", @cheese.get_cheesecake(8, 32)
  end
end