filename = "freeswitch.log"

lines = File.readlines(filename)

calls = []

lines.each do |line|
	call = {}
	if /New Channel/.match(line)
		call[:number] = /(?<=\/)((\w|\d)+)(?=\@)/.match(line)
		call[:uuid] = line[0..35]
		calls << call
	end
end

p calls


