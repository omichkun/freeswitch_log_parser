require 'time'


case ARGV.length
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
	# print "  #{(i.to_f/count.to_f * 100).round(2)}\t #{time.round}s\r"
	call = {}
	if /New Channel/.match(line)
		call[:uuid] = line[0..35]
		uuids << call[:uuid]
		call[:abonent_a] = /(?<=\/)(.+)(?=\[)/.match(line).to_s.split("/")[1].split("@")[0].strip
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
				calls[uuid][:abonent_b] = /(?<=\-\>)(.+)(?=\s)/.match(line).to_s.split(" ")[0].strip
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
# print "\n"

calls.each do |call|
	calls.delete(call[0]) if call[1][:abonent_b] == nil
end

calls.each_value  do |call|	
	if abonent_a && abonent_b
		if call[:abonent_a].include?(abonent_a) && call[:abonent_b].include?(abonent_b)
			puts  "#{call[:line_start]} #{call[:uuid]}: #{call[:abonent_a]} -> #{call[:abonent_b]} #{call[:call_length]}s"
		end
	elsif abonent_a 
		if call[:abonent_a].include?(abonent_a)
			puts  "#{call[:line_start]} #{call[:uuid]}: #{call[:abonent_a]} -> #{call[:abonent_b]} #{call[:call_length]}s"
		end
	else
		puts  "#{call[:line_start]} #{call[:uuid]}: #{call[:abonent_a]} -> #{call[:abonent_b]} #{call[:call_length]}s"
	end
end


# p ARGV
 # calls["fd5458e2-3ff7-4f92-b4be-d32d6fda021a"][:actions].each {|a| p a}
