require "png"
require "pixelfont"

require "option_parser"

class Options
  property path : String? = nil
  property output : String? = nil
  property leading : Int8 = 1
  property tracking : Int8 = 1
  property margin : Int32 = 10
  property palette : Bytes = Bytes[0, 0, 0, 255, 255, 255]
  property? transparent = true
end

VERSION = {{ `shards version`.chomp.stringify }}
USAGE   = "Usage: pixelfont-image -f FONT_PATH -o PNG_PATH [options] 'text'"

options = Options.new

def parse_color(color)
  case color
  when /\d{1,3}\D\d{1,3}\D\d{1,3}/
    color.split(/\D/).map(&.to_u8)
  when /\#?[\da-f]{3}/i
    color.gsub('#', "").chars.map { |c| (c.to_s * 2).to_u8(16) }
  when /\#?[\da-f]{6}/i
    color.gsub('#', "").chars.each_slice(2).map(&.join.to_u8(16))
  else raise "Invalid background color"
  end.to_a
end

OptionParser.parse do |parser|
  parser.banner = USAGE
  parser.on("-v", "--version", "Show version") do
    puts "Pixelfont-Image version #{VERSION}}\nhttps://github.com/SleepingInsomniac/pixelfont"
    exit(0)
  end

  parser.on("-f PATH", "--font=PATH", "Path to the font file") { |path| options.path = path }
  parser.on("-o PATH", "--output=PATH", "Output image path") { |path| options.output = path }
  parser.on("-l DIST", "--leading=DIST", "Space between lines") { |dist| options.leading = dist.to_i8 }
  parser.on("-t DIST", "--tracking=DIST", "Space between chars") { |dist| options.tracking = dist.to_i8 }
  parser.on("-m MARGIN", "--margin=MARGIN", "Space from edges") { |margin| options.margin = margin.to_i32 }
  parser.on("--transparent", "Background is transparent") { options.transparent = true }
  parser.on("--not-transparent", "Background is not transparent") { options.transparent = false }

  parser.on("--bg RGB", "Set the background color") do |color|
    values = parse_color(color)
    0.upto(2) { |n| options.palette[n] = values[n] }
  end

  parser.on("--fg RGB", "Set the text color") do |color|
    values = parse_color(color)
    0.upto(2) { |n| options.palette[n + 3] = values[n] }
  end

  parser.on("-h", "--help", "Show this help") do
    puts parser
    exit
  end

  parser.invalid_option do |flag|
    STDERR.puts "ERROR: #{flag} is not a valid option."
    STDERR.puts parser
    exit(1)
  end
end

unless path = options.path
  STDERR.puts "Specify a font path:"
  STDERR.puts USAGE
  exit(1)
end

unless output = options.output
  STDERR.puts "Specify an output path:"
  STDERR.puts USAGE
  exit(1)
end

font = Pixelfont::Font.new(path)
font.leading = options.leading
font.tracking = options.tracking

ARGV.each do |string|
  width = font.width_of(string).to_u32 + options.margin
  height = font.height_of(string).to_u32 + options.margin

  header = PNG::Header.new(width, height, bit_depth: 1u8, color_type: PNG::ColorType::Indexed)
  canvas = PNG::Canvas.new(header: header, palette: options.palette)
  canvas.transparency = Bytes[0] if options.transparent?

  offset = options.margin == 0 ? 0 : options.margin // 2

  font.draw(string) do |x, y, on|
    canvas[x + offset, y + offset] = {1u8} if on
  end

  PNG.write(output, canvas)
end
