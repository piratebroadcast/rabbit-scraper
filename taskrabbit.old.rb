require 'rubygems'
require 'mechanize'

agent = Mechanize.new
page = agent.get('http://www.taskrabbit.com/all/delivery')

# Find all /t/ links
#page.links.each do |link|
page.links_with(:href => %r{/t/}) do |links|
	links.each do |link|
		p link.attributes
	end
end