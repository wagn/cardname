module Sort64

  # Similar to Base64 encoding, but codes are in ascii sort order so encoded values sort numerically
  # Also use % and - rather than / and + because of other uses of these characters in names.  Didn't
  # want characters that would be encoded in urls or html either.  Can't have name/key characters
  # like _, +, * nor the alternate joint /. 
  PAIR_MAP = {
    '00' => '%', '01' => '-', '02' => '0', '03' => '1', '04' => '2', '05' => '3', '06' => '4', '07' => '5',
    '10' => '6', '11' => '7', '12' => '8', '13' => '9', '14' => 'A', '15' => 'B', '16' => 'C', '17' => 'D',
    '20' => 'E', '21' => 'F', '22' => 'G', '23' => 'H', '24' => 'I', '25' => 'J', '26' => 'K', '27' => 'L',
    '30' => 'M', '31' => 'N', '32' => 'O', '33' => 'P', '34' => 'Q', '35' => 'R', '36' => 'S', '37' => 'T',
    '40' => 'U', '41' => 'V', '42' => 'W', '43' => 'X', '44' => 'Y', '45' => 'Z', '46' => 'a', '47' => 'b',
    '50' => 'c', '51' => 'd', '52' => 'e', '53' => 'f', '54' => 'g', '55' => 'h', '56' => 'i', '57' => 'j',
    '60' => 'k', '61' => 'l', '62' => 'm', '63' => 'n', '64' => 'o', '65' => 'p', '66' => 'q', '67' => 'r',
    '70' => 's', '71' => 't', '72' => 'u', '73' => 'v', '74' => 'w', '75' => 'x', '76' => 'y', '77' => 'z'
  }

  DECODE_MAP = PAIR_MAP.invert

  class << self
    def encode_from_octal oct_str
      oct_str.scan(/../).map{|pair| PAIR_MAP[pair]} * ''
    end

    def encode64 int
      encode_from_octal sprintf('%022o', int)
    end

    def encode32 int
      encode_from_octal sprintf('%012o', int)
    end

    def decode str
      (str.each_char.map{|c| DECODE_MAP[c]} * '').to_i(8)
    end
  end
end
