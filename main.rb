require_relative 'parser'

begin

puts "Enter URL to process."
# chomp for "\n" symbols deleting
url = gets.chomp
puts "Enter file name."
name = gets.chomp

myparser = Parser.new(url, name)
myparser.parse_category

rescue ArgumentError => err
  puts err.message
  puts "Going back to start."
  retry

end