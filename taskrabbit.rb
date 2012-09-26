require 'rubygems'
require 'nokogiri'
require 'anemone'
require 'time'
require 'spreadsheet'
require './task'

def usage
    puts "Usage: ./scraper sites_filename [output_filename] \n" \
    "- sites_filename \t Name of text file with list of sites \n" \
    "- output_filename \t Name of the output .xls file \n" \
    "Scrapes TaskRabbit websites for tasks (title, time, " \
    "minimum price for task, maximum price for task, average price" \
    "for task) and outputs the data as an excel spreadsheet."
end

# Scrape category from TaskRabbit site
def scrape_category(url)
    begin
        puts url
        doc = Nokogiri::HTML(open(url))
        category = doc.css("div.fabric h2").first.content
    rescue Exception => ex
        puts ex.message
        category = " "
    end
end

# Scrape data for first HTML element found by css query
def scrape_css(doc, css)
    begin
        element = doc.css(css).first.content
    rescue Exception => ex
        puts ex.message
        element = ""
    end
end

# Scrape task details from TaskRabbit /t/ pages
def scrape_task(url)
    # Initialize
    task = Task.new

    # Scrape task data
    begin
        doc = Nokogiri::HTML(open(url))
        task.title = scrape_css(doc, "h1.taskTitle")

        # Scrape time
        task.time = scrape_css(doc, "span.time")
        if !task.time.empty?
            task.time = Time.parse(task.time)
        end

        # Scrape price
        value = scrape_css(doc, "div.taskPriceEstimate div.value")
        if !value.empty?
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

# Writes an array of tasks to a spreadsheet
def write_tasks_to_spreadsheet(tasks, output_filename)
    # Initialize
    book = Spreadsheet::Workbook.new
    sheet = book.create_worksheet
    sheet.row(0).concat %w{Title Category Time Minimum Maximum Average}

    puts tasks

    tasks.each_with_index do |task, i|
        sheet.row(i + 1).push(task.title)
        sheet.row(i + 1).push(task.category)
        sheet.row(i + 1).push(task.time)
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
File.open(ARGV[0]).each_line do |url|
    tasks = []
    begin
        Anemone.crawl(url) do |anemone|
            # Find category name
            category = scrape_category(url)

            # Find all task links with /t/ in the href
            anemone.on_pages_like(%r{/t/}) do |page| 
                task = scrape_task(page.url)
                task.category = category

                # Debug
                puts task
                if task == nil
                    next
                elsif !task.empty?
                    tasks << task
                end
            end
        end
    rescue Exception => ex
        puts ex
    end

    # Write spreadsheet
    output_filename = Time.now.strftime("%Y-%m-%d") + ".xls"
    if ARGV.length >= 2
        output_filename = ARGV[1]
    end
    write_tasks_to_spreadsheet(tasks, output_filename)
    puts "Finished writing #{tasks.length} tasks to #{output_filename}"
end