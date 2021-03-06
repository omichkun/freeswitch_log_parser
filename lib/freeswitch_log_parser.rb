require 'time'

module FreeswitchLogParser 
	Call = Struct.new(:uuid, 
										:abonent_a, 
										:abonent_b, 
										:time_start, 
										:time_end, 
										:line_start, 
										:line_end, 
										:call_length, 
										:lines, 
										:routes_pass_lines, 
										:routes_pass_names, 
										:actions)

	def self.find_uuids(line)
  	uuid_regex = /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/
  	line.scan(uuid_regex)
	end

	def self.create_call(line, line_number)
		call = Call.new
		call.uuid = line[0, 36]
		ab_a = /(?<=\/)(.+)(?=\[)/.match(line).to_s
		call.abonent_a = ab_a.split("/")[1] ? ab_a.split("/")[1].split("@")[0].strip : ab_a
		call.time_start = Time.parse(/\d{4}\-\d{2}\-\d{2}\s\d{2}\:\d{2}\:\d{2}\.\d{6}/.match(line).to_s)
		call.line_start = line_number
		call.lines = []
		call.routes_pass_lines = []
		call.routes_pass_names = []
		call.actions = []
		call
	end

	def self.parse_line(line, call, line_number)
		case line 
		when -> (l) { l.match(/(?<=\[)INFO(?=\])/) && l.match(/Processing/)}
			call.abonent_b = /(?<=\-\>)(.+)(?=\s)/.match(line).to_s.split(" ")[0].strip
		when /State DESTROY going to sleep/
			call.time_end = Time.parse(/\d{4}\-\d{2}\-\d{2}\s\d{2}\:\d{2}\:\d{2}\.\d{6}/.match(line).to_s)
			call.line_end = line_number
			call.call_length = call.time_end - call.time_start 
		when /Regex \(PASS\)/
			call.routes_pass_lines << line
			call.routes_pass_names << /\[(.*?)\]/.match(line).to_s
		when /Action/
			call.actions << line
		end
	end

	def self.run(params)
		filename = params[0]

		begin 
			lines = File.readlines(filename)
		rescue
			raise "No such file. Check if it exists or if you have rights to read it."
		end

		calls = []
		line_number = 1
		lines.each do |line|
			
			if /New Channel/.match(line)
				new_call = create_call(line, line_number)
				calls << new_call
			end

			uuid = find_uuids(line).first
			call = calls.select {|c| c.uuid == uuid}.first
			if call
				call.lines << line
				parse_line(line, call, line_number)
			end

			line_number += 1
		end

		calls.delete_if {|call| call.abonent_b == nil}

		calls.each  do |call|	
			puts  "#{call.line_start} #{call.uuid}: #{call.abonent_a} -> #{call.abonent_b} #{call.call_length}s"
		end
	end
end