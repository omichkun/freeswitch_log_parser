require 'time'

=begin 
TO DO: 
1. get call route
2. get actions which are executed for each call
3. take params from command line to get one call 
4. get reason of end of call 

You can run script with three ways 
1. just run script with% ruby app.rb
It takes file freeswitch.log which should be placed near app.rb and parses it. After it starts you can see on console screen all the calls which are presented in this file. 
2. Run script and set in command line path to parsed file. It works the same way as previous but parses the file you have set instead of default freeswitch.log
3. Run script with parameters. All of them are optional 
	The first parameter should be abonent A, the second - abonent B
	If you run script with the parameters in that case the filename is required parameter and it should go at the end of the command line
=end

case ARGV.length
	when 0
		filename = "freeswitch.log"
	when 1
		filename = ARGV[0]
	when 2
		abonent_a = ARGV[0]
		filename = ARGV[1]
	when 3 
		abonent_a = ARGV[0]
		abonent_b = ARGV[1]
		filename = ARGV[2]
end

begin 
	lines = File.readlines(filename)
rescue
	puts "No such file \"#{filename}\". Check if it exists or if you have rights to access it."
	exit
end

calls = {}
uuids = []

timestart = Time.now
i = 1
count = lines.count
lines.each do |line|
	time = Time.now - timestart
	print "  #{(i.to_f/count.to_f * 100).round(2)}\t #{time.round}s\r"
	call = {}
	if /New Channel/.match(line)
		call[:uuid] = line[0..35]
		uuids << call[:uuid]
		call[:abonent_a] = /(?<=\/)(.+)(?=\[)/.match(line).to_s.strip.split("/")[1].split("@")[0]
		call[:time_start] = Time.parse(/\d{4}\-\d{2}\-\d{2}\s\d{2}\:\d{2}\:\d{2}\.\d{6}/.match(line).to_s)
		call[:line_start] = i
		call[:lines] = []
		call[:routes_pass_lines] = []
		call[:routes_pass_names] = []
		call[:actions] = []
		calls[call[:uuid]] = call
	end

	uuids.each do |uuid|
		# check all lines for depending from some call
		if Regexp.union(uuid).match line
			calls[uuid][:lines] << line
			
			# Define abonent if it exists
			if /(?<=\[)INFO(?=\])/.match(line) && /Processing/.match(line)
				calls[uuid][:abonent_b] = /(?<=\-\>)(.+)(?=\s)/.match(line).to_s.split(" ")[0]
			end

			# Define end of the call
			if /State DESTROY going to sleep/.match(line)
				calls[uuid][:time_end] = Time.parse(/\d{4}\-\d{2}\-\d{2}\s\d{2}\:\d{2}\:\d{2}\.\d{6}/.match(line).to_s)
				calls[uuid][:line_end] = i
				calls[uuid][:call_length] = calls[uuid][:time_end] - calls[uuid][:time_start] 
				uuids.delete(uuid)
			end

			# Get PASS routes 
			if /Regex \(PASS\)/.match(line)
				calls[uuid][:routes_pass_lines] << line
				calls[uuid][:routes_pass_names] << /\[(.*?)\]/.match(line).to_s
			end

			if /Action/.match(line)
				calls[uuid][:actions] << line
				# calls[uuid][:routes_pass_names] << /\[(.*?)\]/.match(line).to_s
			end

		end
	end
	i += 1
end
print "\n"

calls.each do |call|
	calls.delete(call[0]) if call[1][:abonent_b] == nil
end

calls.each_value do |call|
	# p call[:line_start] if call[:abonent_b] == ''
	p "#{call[:line_start]} #{call[:uuid]}: #{call[:abonent_a]} -> #{call[:abonent_b]} #{call[:call_length]}s"
end


p ARGV
 # calls["fd5458e2-3ff7-4f92-b4be-d32d6fda021a"][:actions].each {|a| p a}


=begin
	
{
	"67c10bea-40e4-4cad-9b51-ce0b6efdc448" => {
		:uuid => "67c10bea-40e4-4cad-9b51-ce0b6efdc448",
		:abonent_a => '7102',
		:abonent_b => '1234',
		:lines => 'some lines from log file'
		}

	"953e6f9c-4972-4207-a062-3e4e74791167" => {
		:uuid => "953e6f9c-4972-4207-a062-3e4e74791167",
		:abonent_a => '1234',
		:abonent_b => '7102',
		:lines => 'some lines from log file'
		}
}
	
=end