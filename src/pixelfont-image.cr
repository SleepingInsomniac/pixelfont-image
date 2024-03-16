require "png"
require "pixelfont"

require "option_parser"

class Options
  property path : String? = nil
  property output : String? = nil
  property leading : Int8 = 1
  property tracking : Int8 = 1
  property margin : Int32 = 10
end

VERSION = {{ `shards version`.chomp.stringify }}
USAGE   = "Usage: pixelfont-image -f FONT_PATH -o PNG_PATH [options] 'text'"

options = Options.new

OptionParser.parse do |parser|
  parser.banner = USAGE
  parser.on("-v", "--version", "Show version") do
    puts "Pixelfont-Image version #{VERSION}}\nhttps://github.com/SleepingInsomniac/pixelfont"
    exit(0)
  end
  parser.on("-f PATH", "--font=PATH", "Path to the font file") { |path| options.path = path }
  parser.on("-o PATH", "--output=PATH", "Output image path") { |path| options.output = path }
  parser.on("-h", "--help", "Show this help") do
    puts parser
    exit
  end

  parser.on("-l DIST", "--leading=DIST", "Space between lines") { |dist| options.leading = dist.to_i8 }
  parser.on("-t DIST", "--tracking=DIST", "Space between chars") { |dist| options.tracking = dist.to_i8 }

  parser.on("-m MARGIN", "--margin=MARGIN", "Space from edges") { |margin| options.margin = margin.to_i32 }

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

  header = PNG::Header.new(width, height, bit_depth: 1u8, color_type: PNG::ColorType::Grayscale)
  canvas = PNG::Canvas.new(header)

  offset = options.margin == 0 ? 0 : options.margin // 2

  font.draw(string) do |x, y, on|
    canvas[x + offset, y + offset] = {1u8} if on
  end

  PNG.write(output, canvas)
end
