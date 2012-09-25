require 'rubygems'
require 'nokogiri'
require 'anemone'
require 'time'

# Scrape category from TaskRabbit site
def get_category(url)
    begin
        puts url
        doc = Nokogiri::HTML(open(url))
        category = doc.css("div.fabric h2").first.content
    rescue Exception => ex
        puts ex.message
        category = " "
    end
end

# Scrape task details from TaskRabbit /t/ pages
def get_task(url)
    begin
        doc = Nokogiri::HTML(open(page.url))
        title = doc.css("h1.taskTitle").first.content
        time = Time.parse(doc.css("span.time").first.content).strftime("%Y-%m-%d")

        # Parse price (remove $ chars, split by '-')
        value = doc.css("div.taskPriceEstimate div.value").first.content.tr!("$", "").split(" - ")
        min_price = value.first.to_i
        max_price = value.last.to_i

        avg_price = (min_price + max_price) / 2

        puts "#{title} @ #{time} - #{min_price} to #{max_price} [Average price: #{avg_price}]" 
    rescue Exception => ex
        puts "Not all task information available"
    end
end

# Read links from sites.txt
File.open("sites.txt").each_line do |url|
    Anemone.crawl(url) do |anemone|
        # Find category name
        category = get_category(url)
        puts "Category: #{category}"

        # Find all task links with /t/ in the href
        anemone.on_pages_like(%r{/t/}) do |page|
            task = get_task(page.url)
        end
    end 
end