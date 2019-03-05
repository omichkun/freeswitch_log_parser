require 'time'
require_relative 'freeswitch_log_parser/call'

module FreeswitchLogParser 

	def self.is_valid_uuid?(line)
  	uuid_regex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/
  	uuid_regex.match?(line.to_s.downcase) ? true : false
	end

	def self.find_uuids(line)
  	uuid_regex = /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/
  	line.scan(uuid_regex)
	end

	def self.create_call(line, line_number)
		call = {}
		call[:uuid] = line[0, 36]
		ab_a = /(?<=\/)(.+)(?=\[)/.match(line).to_s
		call[:abonent_a] = ab_a.split("/")[1] ? ab_a.split("/")[1].split("@")[0].strip : ab_a
		call[:time_start] = Time.parse(/\d{4}\-\d{2}\-\d{2}\s\d{2}\:\d{2}\:\d{2}\.\d{6}/.match(line).to_s)
		call[:line_start] = line_number
		call[:lines] = []
		call[:routes_pass_lines] = []
		call[:routes_pass_names] = []
		call[:actions] = []
		call
	end

	def self.run(*params)
		case params.length
			when 1
				filename = params[0]
			when 2
				filename = params[0]
				abonent_a = params[1]
			when 3 
				filename = params[0]
				abonent_a = params[1]
				abonent_b = params[2]
		end

		begin 
			lines = File.readlines(filename)
		rescue
			raise "No such file. Check if it exists or if you have rights to read it."
		end


		calls = {}
		uuids = []

		timestart = Time.now
		line_number = 1
		count = lines.count
		lines.each do |line|
			time = Time.now - timestart
			
			if /New Channel/.match(line)
				call = create_call(line, line_number)
				uuids << call[:uuid]
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
						calls[uuid][:line_end] = line_number
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
					end

				end
			end
			line_number += 1
		end

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
	end
end