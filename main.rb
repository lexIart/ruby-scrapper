require 'curb'
require 'nokogiri'
require 'csv'
require 'check'

class Scrapper

  puts 'Enter URL to process'

  url = gets
  puts 'Enter CSV-file name.'
  fname = gets
  http = Curl.get("#{url.delete!("\n")}")
  pcount = 1

  suburl = ''
  subhttp = ''
  subclist = ''

  http = Curl.get(url)
  clist = Nokogiri::HTML(http.body_str)
  puts 'Document loaded. Starting processing the page.'

  while true
    puts "Processing #{pcount} page."
    # cycle that processing each element on category page
    clist.xpath('//ul[@id="product_list"]/li').each do |item|
      # taking element url for him processing
      subhttp = Curl.get(item.xpath('.//div[contains(@class, "product-desc")]/a/@href').text)
      subclist = Nokogiri::HTML(subhttp.body_str)
      puts "-Category sub-element loaded-.\nProcessing |#{subclist.xpath('//p[@class="product_main_name"]').text}| element."
      # taking price list of single element
      subclist.xpath('//div/fieldset/div/ul/li').each do |subitem|
        # taking element information and pushing it in csv file
        CSV.open("#{fname}", 'a+') do |csv|
          csv << [
          subitem.xpath('//p[@class="product_main_name"]').text,
          subitem.xpath('./label/span[@class="radio_label"]').text,
          subitem.xpath('./label/span[@class="price_comb"]').text,
          subclist.xpath('//span/img/@src').text
          ]
          puts "Parameters set detected. Writing to file."
        end
      end
    end
    # next page access logic
    if clist.xpath('//div[@class="content_sortPagiBar"]//li[3]/a/@href').empty?
      puts "Proccessing ended successful. "
      break
    else
      pcount = pcount + 1
      http = Curl.get("#{url.delete("\n")}?p=#{pcount}")
      clist = Nokogiri::HTML(http.body_str)
      puts "Detected page ##{pcount}. Entering."
    end
  end
end
