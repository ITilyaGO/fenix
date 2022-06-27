require 'securerandom'
require 'openssl'

module Secure
  ALPHANUMERIC = [*'A'..'Z', *'a'..'z', *'0'..'9']
  extend self

  def uuid
    SecureRandom.uuid
  end

  def alpha(num=10)
    alphanumeric(num)
  end

  def bytes(num=64)
    SecureRandom.random_bytes(num)
  end

  def since(step = 30, initial_time = 0)
    (Time.now.to_i - initial_time) % step
  end

  def totp(secret, digits = 6, step = 30, initial_time = 0)
    steps = (Time.now.to_i - initial_time) / step
    hotp(secret, steps, digits)
  end

  def hotp(secret, counter, digits = 6)
    hash = OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha1'), secret, int_to_bytestring(counter))
    "%0#{digits}i" % (truncate(hash) % 10**digits)
  end

  def truncate(string)
    offset = string.bytes.last & 0xf
    partial = string.bytes[offset..offset+3]
    partial.pack("C*").unpack("N").first & 0x7fffffff
  end

  def int_to_bytestring(int, padding = 8)
    result = []
  until int == 0
    result << (int & 0xFF).chr
    int >>= 8
  end
    result.reverse.join.rjust(padding, 0.chr)
  end

  private

  def choose(source, n)
    size = source.size
    m = 1
    limit = size
    while limit * size <= 0x100000000
      limit *= size
      m += 1
    end
    result = ''.dup
    while m <= n
      rs = SecureRandom.random_number(limit)
      is = rs.digits(size)
      (m-is.length).times { is << 0 }
      result << source.values_at(*is).join('')
      n -= m
    end
    if 0 < n
      rs = SecureRandom.random_number(limit)
      is = rs.digits(size)
      if is.length < n
        (n-is.length).times { is << 0 }
      else
        is.pop while n < is.length
      end
      result.concat source.values_at(*is).join('')
    end
    result
  end

  def alphanumeric(n=nil)
    n = 16 if n.nil?
    choose(ALPHANUMERIC, n)
  end

  module Base32
    class Base32Error < RuntimeError; end
    CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567'.each_char.to_a
    SHIFT = 5
    MASK = 31

    extend self

    def decode(str)
      buffer = 0
      idx = 0
      bits_left = 0
      str = str.tr('=', '').upcase
      result = []
      str.split('').each do |char|
        buffer = buffer << SHIFT
        buffer = buffer | (decode_quint(char) & MASK)
        bits_left = bits_left + SHIFT
        if bits_left >= 8
          result[idx] = (buffer >> (bits_left - 8)) & 255
          idx = idx + 1
          bits_left = bits_left - 8
        end
      end
      result.pack('c*')
    end

    def encode(b)
      data = b.unpack('c*')
      out = ''
      buffer = data[0]
      idx = 1
      bits_left = 8
      while bits_left > 0 || idx < data.length
        if bits_left < SHIFT
          if idx < data.length
            buffer = buffer << 8
            buffer = buffer | (data[idx] & 255)
            bits_left = bits_left + 8
            idx = idx + 1
          else
            pad = SHIFT - bits_left
            buffer = buffer << pad
            bits_left = bits_left + pad
          end
        end
        val = MASK & (buffer >> (bits_left - SHIFT))
        bits_left = bits_left - SHIFT
        out.concat(CHARS[val])
      end
      return out
    end

    # Defaults to 160 bit long secret (meaning a 32 character long base32 secret)
    def random(byte_length = 20)
     rand_bytes = SecureRandom.random_bytes(byte_length)
     encode(rand_bytes)
    end

    private

    def decode_quint(q)
      CHARS.index(q) || raise(Base32Error, "Invalid Base32 Character - '#{q}'")
    end
  end
end