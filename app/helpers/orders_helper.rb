Fenix::App.helpers do
  def s_btns(sections, parts)
    # @page = page
    # @pages = pages
    # @c = c
    # @m = m
    # @r = route
    partial "orders/progress"
  end
  
  # def order_squares(order, sections)
  #   partial "orders/squares", :locals => { :sections => sections, :order => order }
  # end

  def to_rub(value)
    ("%.2f" % value).gsub('.', ',')
  end

  # humanize

  FIRST_TEN = ['', 'один', 'два', 'три', 'четыре', 'пять', 'шесть', 'семь', 'восемь', 'девять']
  SECOND_TEN = ['десять', 'одиннадцать', 'двенадцать', 'тринадцать', 'четырнадцать', 'пятнадцать', 'шестнадцать', 'семнадцать', 'восемнадцать', 'девятнадцать']
  TENS = ['', '', 'двадцать', 'тридцать', 'сорок', 'пятьдесят', 'шестьдесят', 'семьдесят', 'восемьдесят', 'девяносто']
  HUNDREDS = ['', 'сто', 'двести', 'триста', 'четыреста', 'пятьсот', 'шестьсот', 'семьсот', 'восемьсот', 'девятьсот']
  LOTS = ['', 'тысяча', 'миллион', 'миллиард', 'триллион', 'квадриллион', 'квинтиллион', 'секстиллион', 'септиллион', 'октиллион', 'нониллион']

  def convert(value)
    num = value.to_i rescue 0
    return 'ноль' if num == 0

    o = []
    place = 0

    while !num.zero?
      # Get the rightmost group of three
      first_three_digits = num % 1000

      # Truncate the original number by those three digits
      num /= 1000

      groups = [part_below_thousand(first_three_digits), LOTS[place]]

      o << groups.reject(&:blank?).join(' ')
      place += 1
    end

    o.reverse.reject(&:blank?).join(' ')
  end

  def part_below_thousand(num)
    str = []
    
    return FIRST_TEN[num % 100] if num < 10
    return SECOND_TEN[num % 10 - 10] if num < 20

    # If not in special cases, num must be at least a two digit number
    # Pull the first digit
    first_digit = num % 10
    num /= 10
    str << FIRST_TEN[first_digit]

    # Pull the second digit
    second_digit = num % 10
    num /= 10
    str << TENS[second_digit]

    # If there is a third digit
    if num > 0
      third_digit = num % 10
      str << HUNDREDS[third_digit]
    end

    str.reverse.reject(&:blank?).join(' ')
  end
end