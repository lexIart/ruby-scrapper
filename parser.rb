require 'csv'
require 'nokogiri'
require 'curb'

class Parser

  def initialize(name, url)
    @url = url
    @name = name
    @pcount = 1
    @item_hash = {}
    @items_list = []
  end

  # validate file name (Forbidden symbols and .csv extension)
  # if user doesn't enter .csv - it will automaticly appears
  def validate_file_name!
    if @name[/[\/\\]/]
      # catching forbidden linux symbol by regexp using
      # raising error for loop enter cycle
      raise ArgumentError, "Forbidden symbol detected. Try again."
    else
      if @name[/\.csv/]
        puts "Created [#{@name}] file."
      else
        @name = "#{@name}.csv"
        puts "Notice the lack of an extension. Created [#{@name}] file."
      end
    end
  end

  # 2-step validatinon system. first step - checking with rexegp using
  # second step - checking by searching for correct content (product list)
  def validate_url
    if @url.match(/^https:\/\/www.petsonic.com\/[-\w]+\/$/)
      # donwloading page with nokogiri if first step is OK
      @product_page = get_category_page
      # checking for content?
      if @product_page.xpath('//ul[@id="product_list"]/li').empty?
        raise ArgumentError, "Invalid category page. Please, enter correct URL."
      else
        puts "|#{@product_page.xpath("//span[@class='cat-name']").text}| category page correct."
      end
    else
      # raising for loop enter cycle (like in file validating method)
      raise ArgumentError, "Invalid URL syntax. Try again."
    end
  end

  # logic for donwloading pages by nokogiri lib. also using in page counting
  def get_category_page
    if @pcount == 1
      category_page = Curl.get(@url)
      Nokogiri::HTML(category_page.body_str)
    else
      # here is logic for working with few pages in category. string formating..
      # with counting variable using
      category_page = Curl.get("#{@url}?p=#{@pcount}")
      Nokogiri::HTML(category_page.body_str)
    end
  end

  # this method will send boolean if there no other pages in category by..
  # checking page content ("NEXT" button on category page)
  def have_next_page?
    !@category_page.xpath('//*[@id="pagination_next_bottom"]/a').empty?
  end

  # main mechanism of products processing. procces of taking each product..
  # described in get_product_page method
  def processing_category
    loop do
      @category_page = get_category_page
      puts "Processing #{@pcount} page."
      # here we iterating each product in category
      @category_page.xpath('//ul[@id="product_list"]/li').each do |item|
        # taking product URL
        @product_page = get_product_page(item)
        puts "-Category product loaded.-\nProcessing |#{@product_page.xpath('//h1[@class="product_main_name"]').text} | product."
        parse_subItem
      end
      @pcount += 1
      break unless have_next_page?
    end
  end

  # method allow getting a URL of each product in category by one iteration..
  # so first step is downloading category page. second step - taking URL of..
  # each product by one iteration
  def get_product_page(item)
    product_page = Curl.get(item.xpath('.//div[contains(@class, "product-desc")]/a/@href').text)
    Nokogiri::HTML(product_page.body_str)
  end

  # here is name/price+weight+picUrl variations. one iteration - one product
  # attributes variation that takings by xpath elements
  def parse_subItem
    @product_page.xpath("//div[@id='attributes']//li").each do |subitem|
      # saving in hash by key/value clear notation
      @item_hash = {
        "n/w" => get_name(subitem),
        "price" => subitem.xpath('./label/span[@class="price_comb"]').text,
        "img" => subitem.xpath('//span/img/@src').text
      }
      push_info_to_array
      puts "Data variation taked successfully."
    end
  end

  # method that combine name and weight strings in single string
  def get_name(subitem)
    # fix name duplicate Acana acana
    pdp_name = @product_page.xpath('//h1[@class="product_main_name"]').text
    extd_part = subitem.xpath('./label/span[@class="radio_label"]').text
    
    [pdp_name, extd_part].join(' ')
  end

  # we need array of hashes for creating CSV file by one step, instead of..
  # opening the stream every time that we getting product attributes variation
  def push_info_to_array
    @items_list << @item_hash
  end

  # writing massive to csv file by single stream opening with iteration using
  def write_to_csv
    CSV.open(@name, "a+") do |csv|
      @items_list.each do |product|
        csv << [product["n/w"], product["price"], product["img"]]
      end
    end
    puts "Data writed to #{@name} file."
  end

  # main method that combine all parser logic
  def parse_category
    validate_url
    validate_file_name!
    processing_category
    write_to_csv
  end

end
