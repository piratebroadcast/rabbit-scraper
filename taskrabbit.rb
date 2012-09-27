require 'rubygems'
require 'nokogiri'
require 'anemone'
require 'time'
require 'spreadsheet'
require './task'

# Constants
URL_PATTERN = Regexp.union %r(all), %r(page)

def usage
    puts "Usage: ./scraper sites_filename [output_filename] \n" \
    "- sites_filename \t Name of text file with list of sites \n" \
    "- output_filename \t Name of the output .xls file.  Default is YY-mm-dd.xls \n" \
    "Scrapes TaskRabbit websites for tasks (title, time, " \
    "minimum price for task, maximum price for task, average price" \
    "for task) and outputs the data as an excel spreadsheet."
end

# Scrape category from TaskRabbit site
def scrape_category(url)
    begin
        doc = Nokogiri::HTML(open(url))
        category = doc.css("div.fabric h2").first
        return category.content unless category.nil?
    rescue Exception => ex
        puts ex
    end

    return ""
end

# Scrape data for first HTML element found by css query
def scrape_css(elem, css)
    begin
        value = elem.css(css).first
        return value.content unless value.nil?
    rescue Exception => ex
        puts ex
    end

    return ""
end

# Scrape task details from Nokogiri element
def scrape_task(elem)
    # Initialize
    task = Task.new

    # Scrape task data
    begin
        task.title = scrape_css(elem, "h3.eventTitle a")

        # Scrape price
        value = scrape_css(elem, "span.taskPriceEstimate span.value")
        return "" if value.nil?
        unless value.empty?
            value = value.tr!("$", "").split(" - ") # Remove $ chars, Split by '-'
            task.min_price = value.first.to_i
            task.max_price = value.last.to_i
            task.avg_price = (task.min_price + task.max_price) / 2
        end
    rescue Exception => ex
        puts "[ERROR] - #{ex.message}"
    end

    return task
end

# Scrapes tasks from a TaskRabbit /all/ tasks page
def scrape_tasks(url)
    tasks = []
    doc = Nokogiri::HTML(open(url))
    doc.css("li.task_event").each do |node|
        task = scrape_task(node)

        next if task.nil?
        tasks << task unless task.empty?
    end

    return tasks
end

# Writes an array of tasks to a spreadsheet
def write_tasks_to_spreadsheet(tasks, output_filename)
    # Initialize
    book = Spreadsheet::Workbook.new
    sheet = book.create_worksheet
    sheet.row(0).concat %w{Title Category Minimum Maximum Average}

    puts tasks

    tasks.each_with_index do |task, i|
        sheet.row(i + 1).push(task.title)
        sheet.row(i + 1).push(task.category)
        sheet.row(i + 1).push(task.min_price)
        sheet.row(i + 1).push(task.max_price)
        sheet.row(i + 1).push(task.avg_price)
    end

    # Format
    sheet.row(0).height = 14

    format = Spreadsheet::Format.new :color => :blue,
                                   :weight => :bold,
                                   :size => 14
    sheet.row(0).default_format = format

    # Write to file
    book.write output_filename
end

# Check arguments
if ARGV.length != 1
    usage()
    exit(1)
end

# Read links from file parameter
tasks = []
visited_urls = {}
File.open(ARGV[0]).each_line do |url|
    begin
        Anemone.crawl(url) do |anemone|
            # Find all task links with /all/ in the href
            anemone.focus_crawl do |page|
                page.links.keep_if { |link| link.to_s.match(URL_PATTERN) }
            end

            anemone.on_every_page do |page|
                # Check if URL has been visited
                next unless visited_urls[page.url].nil?
                visited_urls[page.url] = true

                puts "Scraping #{page.url}"
                new_tasks = scrape_tasks(page.url)

                # Set task category
                category = scrape_category(url)
                new_tasks.each { |task| task.category = category }

                tasks = new_tasks + tasks
            end
            puts "Finished scraping #{tasks.length} tasks"
        end
    rescue Exception => ex
        puts "[ERROR] #{ex}"
    end
end

# Write spreadsheet
output_filename = Time.now.strftime("%Y-%m-%d") + ".xls"
if ARGV.length >= 2
    output_filename = ARGV[1]
end
write_tasks_to_spreadsheet(tasks, output_filename)
puts "Finished writing #{tasks.length} tasks to #{output_filename}"