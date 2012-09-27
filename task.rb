require 'time'

SECONDS_IN_DAY = 86400

# TS: general note - plz always use 2 spaces instead of tabs for
# indentation in ruby
class Task
	attr_accessor :title, :time, :category, :min_price, :max_price, :avg_price

  # TS: this isn't a great pattern because you have to pass a long chain of arguments, and it's easy to
  # get them in the wrong order. Rather, you should take in a hash and instantiate your instance
  # variables by hash key
	def initialize(title = "", time = nil, category = "", min_price = 0, max_price = 0, avg_price = 0)
		@title = title
		@time = time
		@category = category
		@min_price = min_price
		@max_price = 0
		@avg_price = 0
	end

	def empty?
		@title.empty? && @time.empty? && @category.empty? && @min_price == 0 && @max_price == 0 && @avg_price = 0
	end

	def time=(time)
          # TS: this is confusing - what type is the "time" parameter? Is it a ruby Time or a string?
          # it seems like from this method it could be both. You should probably instead make a decision,
          # otherwise you could use the time property later (e.g. when you call strftime below) and
          # mess it up
          
		@time = time

		# Check for special 'X days ago' case
		begin
			split_time = time.split
			if split_time.length == 3 && split_time[1] == "days" && split_time[2] = "ago"
				offset_in_seconds = split_time[0].to_i * SECONDS_IN_DAY
				@time = Time.now - offset_in_seconds
			end
		rescue
		end
	end

	def to_s
          # TS: what do you think this statement does?
		time = time

          # TS: this is a bad pattern - if you expect this to fail because it is not a ruby Time,
          # you should write it like this instead:
          # time = @time.respond_to?(:strftime) ? @time.strftime("%Y-%m-%d") : @time.to_s
          
		begin
			time = @time.strftime("%Y-%m-%d")
		rescue
		end

		"[#{@category}] #{@title} @ #{time} // $#{@min_price} - $#{@max_price} [Average price: $#{avg_price}]"
	end
end
