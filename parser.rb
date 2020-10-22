require 'csv'
require 'nokogiri'
require 'curb'

class Parser

  def validate_file_name!
    if @name.match(/[\/\\]/)
      raise ArgumentError, "Forbidden symbol detected. Try again."
    else
      if @name['.csv']
        puts "Created [#{@name}] file."
      else
        name = "#{@name}.csv"
        puts "Notice the lack of an extension. Created [#{@name}] file."
      end
    end
  end

  def validate_url
    if @url.match(/^https:\/\/www.petsonic.com\/[-\w]+\/$/)
      @product_page = get_category_page
      if @product_page.xpath('//ul[@id="product_list"]/li').empty?
        raise ArgumentError, "Invalid category page. Please, enter correct URL."
      else
        puts "|#{@product_page.xpath("//span[@class='cat-name']").text}| category page correct."
      end
    else
      raise ArgumentError, "Invalid URL syntax. Try again."
    end
  end

  def get_category_page
    if @pcount == 1
      category_page = Curl.get(@url)
      Nokogiri::HTML(category_page.body_str)
    else
      category_page = Curl.get("#{@url}?p=#{@pcount}")
      Nokogiri::HTML(category_page.body_str)
    end
  end

  def have_next_page?
    !@category_page.xpath('//div[@class="content_sortPagiBar"]//li[3]/a/@href').empty?
  end

  def processing_category
    loop do
      @category_page = get_category_page
      puts "Processing #{@pcount}number page."
      @category_page.xpath('//ul[@id="product_list"]/li').each do |item|
        @product_page = get_product_page(item)
        puts "-Category sub-element loaded-.\nProcessing |#{@product_page.xpath('//p[@class="product_main_name"]').text} | element."
        parse_subItem
      end
      @pcount += 1
      break unless have_next_page?
    end
  end

  def get_product_page(item)
    product_page = Curl.get(item.xpath('.//div[contains(@class, "product-desc")]/a/@href').text)
    Nokogiri::HTML(product_page.body_str)
  end

  def parse_subItem
    @product_page.xpath("//div[@id='attributes']//li").each do |subitem|
      @item_hash = {
        "n/w" => get_name(subitem),
        "price" => subitem.xpath('./label/span[@class="price_comb"]').text,
        "img" => subitem.xpath('//span/img/@src').text
      }
      push_info_to_array
      puts "Data variation taked successfully."
    end
  end

  def get_name(subitem)
    # fix name duplicate Acana acana
    @product_page.xpath('//p[@class="product_main_name"]').text + " " + subitem.xpath('./label/span[@class="radio_label"]').text
  end

  def push_info_to_array
    @items_list << @item_hash
  end

  def write_to_csv
    CSV.open(@name, "a+") do |csv|
      @items_list.each do |product|
        csv << [product["n/w"], product["price"], product["img"]]
      end
    end
    puts "Data writed to #{@name} file."
  end

  def parse_category(url, name)
    @url = url
    @name = name
    @pcount = 1
    @item_hash = {}
    @items_list = []
    validate_url
    validate_file_name!
    processing_category
    write_to_csv
  end

end
