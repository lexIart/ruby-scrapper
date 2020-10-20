require 'curb'
require 'nokogiri'
require 'open-uri'
require 'csv'

class Scrapper

  pcount = 1
  puts 'Enter URL to process'
  # url = gets
  # http = Curl.get("#{url.delete!("\n")}")
  url = 'https://www.petsonic.com/acana/'

  suburl = ''
  subhttp = ''
  subclist = ''

  http = Curl.get(url)
  puts 'Document loaded. Starting processing the page.'
  clist = Nokogiri::HTML(http.body_str)

  while true
    # cycle that processing each element on category page
    clist.xpath('//ul[@id="product_list"]/li').each do |item|
      # taking element url for him processing
      subhttp = Curl.get(item.xpath('.//div[contains(@class, "product-desc")]/a/@href').text)
      subclist = Nokogiri::HTML(subhttp.body_str)
      # taking price list of single element
      subclist.xpath('//div/fieldset/div/ul/li').each do |subitem|
        # taking name of product
        puts subitem.xpath('//p[@class="product_main_name"]').text
        # taking weight variation
        puts subitem.xpath('./label/span[@class="radio_label"]').text
        # taking price of weight variation
        puts subitem.xpath('./label/span[@class="price_comb"]').text
        # taking picture URL
        puts subclist.xpath('//span/img/@src').text
        CSV.open('db.csv', 'a+') do |csv|
          csv << [
          subitem.xpath('//p[@class="product_main_name"]').text,
          subitem.xpath('./label/span[@class="radio_label"]').text,
          subitem.xpath('./label/span[@class="price_comb"]').text,
          subclist.xpath('//span/img/@src').text
          ]
        end
        puts "ya sdelal iteraciy"
      end
    end
    # next page access logic
    if clist.xpath('//div[@class="content_sortPagiBar"]//li[3]/a/@href').empty?
      break
    else
      pcount = pcount + 1
      http = Curl.get("#{url.delete("\n")}?p=#{pcount}")
      clist = Nokogiri::HTML(http.body_str)
    end
  end
end
