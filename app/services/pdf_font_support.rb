# Shared Prawn font setup for PDF-generating services.
#
# Prawn's default Helvetica only supports Windows-1252; user-typed text from
# iOS (smart quotes, emoji, accented names) breaks PDF generation. Noto Sans
# is a UTF-8 TTF covering all common Latin/Greek/Cyrillic input. If a glyph
# is outside even Noto Sans (an emoji, a supplementary-plane char), the
# fallback rebuilds the document with ASCII-coerced text rather than failing
# the whole report.
module PdfFontSupport
  FONT_DIR = Rails.root.join("app/assets/fonts").freeze

  private

  def apply_noto_sans(pdf)
    pdf.font_families.update("NotoSans" => {
      normal: FONT_DIR.join("NotoSans-Regular.ttf").to_s,
      bold: FONT_DIR.join("NotoSans-Bold.ttf").to_s,
      italic: FONT_DIR.join("NotoSans-Italic.ttf").to_s,
      bold_italic: FONT_DIR.join("NotoSans-BoldItalic.ttf").to_s
    })
    pdf.font "NotoSans"
  end

  def with_glyph_fallback
    yield
  rescue Prawn::Errors::IncompatibleStringEncoding, Prawn::Errors::CannotRender => e
    Rails.logger.warn("[#{self.class.name}] glyph not in font, retrying with sanitized text: #{e.message}")
    @sanitize_text = true
    yield
  end

  # Coerce to ASCII when the first PDF build raised a glyph error. Smart quotes,
  # em dashes, and accents are preserved by Noto Sans on the normal path — only
  # the fallback path strips chars the font can't render.
  def t(str)
    return str unless @sanitize_text
    return str if str.nil?
    str.to_s.encode("US-ASCII", invalid: :replace, undef: :replace, replace: "?")
  end
end
