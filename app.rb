filename = "freeswitch.log"

lines = File.readlines(filename)

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
		call[:abonent_a] = /(?<=\/)(.+)(?=\[)/.match(line).to_s.strip.split("/")[1]
		call[:time_start] = /\d{4}\-\d{2}\-\d{2}\s\d{2}\:\d{2}\:\d{2}\.\d{6}/.match(line).to_s
		call[:line_start] = i
		call[:lines] = []
		calls[call[:uuid]] = call
	end

	uuids.each do |uuid|
		# check all lines for depending from some call
		if Regexp.union(uuid).match line
			calls[uuid][:lines] << line
			if /(?<=\[)INFO(?=\])/.match(line) && /Processing/.match(line)
				calls[uuid][:abonent_b] = /(?<=\>)(.+)(?=\s)/.match(line).to_s
			end
			if /State DESTROY going to sleep/.match(line)
				calls[uuid][:time_end] = /\d{4}\-\d{2}\-\d{2}\s\d{2}\:\d{2}\:\d{2}\.\d{6}/.match(line).to_s
				uuids.delete(uuid)
			end
		end
	end
	i += 1
end
print "\n"


calls.each_value do |call|
	# p call[:line_start] if call[:abonent_b] == ''
	p "#{call[:line_start]}: #{call[:abonent_a]} -> #{call[:abonent_b]}"
end





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