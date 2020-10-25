require_relative 'parser'

begin

puts "Enter URL to process."
# chomp for "\n" symbols deleting
url = gets.chomp
puts "Enter file name."
name = gets.chomp

myparser = Parser.new
myparser.parse_category(url, name)

rescue ArgumentError => err
  puts err.message
  puts "Going back to start."
  retry

end
