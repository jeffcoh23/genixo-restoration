module PhoneFormatting
  def format_phone(number)
    return number unless number.present?
    digits = number.gsub(/\D/, "")
    return "(#{digits[0..2]}) #{digits[3..5]}-#{digits[6..9]}" if digits.length == 10
    number
  end
end
