require 'freeswitch_log_parser' 

describe FreeswitchLogParser do 
	 context '#run' do
   		it 'should raise an error' do 
   			expect { FreeswitchLogParser.run }.to raise_error("No such file. Check if it exists or if you have rights to read it.")
   		end
   end

   context "#run" do 
      it "should puts all results" do 
      	expect { FreeswitchLogParser.run('log.log') }.to output(/.+/).to_stdout
      end 
   end 

  context '#create_call' do 
  	it 'should create new call' do 
  		line = 'dd8aeda2-0cb2-4081-8023-709fc7aa154e 2018-02-21 17:07:16.247070 [3480] [NOTICE] switch_channel.c:1034 New Channel sofia/internal/100@188.93.213.101 [dd8aeda2-0cb2-4081-8023-709fc7aa154e]'
  		line_number = 1
  		expect(FreeswitchLogParser.create_call(line, line_number)).to be_an_instance_of(Hash)
  		expect(FreeswitchLogParser.create_call(line, line_number)[:uuid]).to eq('dd8aeda2-0cb2-4081-8023-709fc7aa154e')
  		expect(FreeswitchLogParser.create_call(line, line_number)[:abonent_a]).to eq('100')
  		expect(FreeswitchLogParser.create_call(line, line_number)[:time_start]).to eq(Time.parse('2018-02-21 17:07:16.247070'))
  		expect(FreeswitchLogParser.create_call(line, line_number)[:line_start]).to eq(1)
  		expect(FreeswitchLogParser.create_call(line, line_number)[:lines]).to be_an_instance_of(Array)
  		expect(FreeswitchLogParser.create_call(line, line_number)[:lines].size).to eq(0)
  		expect(FreeswitchLogParser.create_call(line, line_number)[:routes_pass_lines]).to be_an_instance_of(Array)
  		expect(FreeswitchLogParser.create_call(line, line_number)[:routes_pass_lines].size).to eq(0)
  		expect(FreeswitchLogParser.create_call(line, line_number)[:routes_pass_names]).to be_an_instance_of(Array)
  		expect(FreeswitchLogParser.create_call(line, line_number)[:routes_pass_names].size).to eq(0)
  		expect(FreeswitchLogParser.create_call(line, line_number)[:actions]).to be_an_instance_of(Array)
  		expect(FreeswitchLogParser.create_call(line, line_number)[:actions].size).to eq(0)
  	end
  end 

  context '#is_valid_uuid?' do 
  	it 'should check if given uuid is valid' do 
  		line_true = 'dd8aeda2-0cb2-4081-8023-709fc7aa154e'
  		line_false = 'xy8aeda2-0cb2-4081-8023-709fc7aa154e'
  		expect(FreeswitchLogParser.is_valid_uuid?(line_true)).to eq(true)
  		expect(FreeswitchLogParser.is_valid_uuid?(line_false)).to eq(false)
  	end
  end 

  context '#find_uuids' do 
  	it 'should find uuid in string' do 
  		line = 'dd8aeda2-0cb2-4081-8023-709fc7aa154e 2018-02-21 17:07:16.247070 [3480] [NOTICE] switch_channel.c:1034 New Channel sofia/internal/100@188.93.213.101 [dd8aeda2-0cb2-4081-8023-709fc7aa154e]'
  		expect(FreeswitchLogParser.find_uuids(line)).to eq(Array['dd8aeda2-0cb2-4081-8023-709fc7aa154e','dd8aeda2-0cb2-4081-8023-709fc7aa154e'])
  		expect(FreeswitchLogParser.find_uuids(line)).to be_an_instance_of(Array)
  	end
  end 


end