require 'freeswitch_log_parser' 
require 'pry'

describe FreeswitchLogParser do 
	 context '#run' do
   		it 'should raise an error with invalid data' do 
   			expect { FreeswitchLogParser.run('') }.to raise_error("No such file. Check if it exists or if you have rights to read it.")
   		end

      it "should puts all results with valid data" do 
      	expect { FreeswitchLogParser.run(['log.log']) }.to output("11 6fc9c52a-6bd2-411d-ba42-232159cdf310: 10010 -> 00970597101399 0.040039s\n321 dd8aeda2-0cb2-4081-8023-709fc7aa154e: 100 -> +106900970597773739 0.060547s\n1801 79cbebf0-b06f-4152-b4b9-1c8d857ca7e4: 79608649424 -> 800IP_10344117_line002 1.980468s\n2165 d8e7aed7-42a7-4d2f-9714-fbd988e9feaa: 7071388 -> 7071201 23.720703s\n2438 ed6a0f59-3c43-4d0d-ae4f-0c06c18547a5: sip:7071201 -> att_xfer_call 23.680664s\n2902 0fc0fc53-783c-4b8d-adbb-3f8536e31f2e: 9001 -> 008810972568472716 0.039062s\n3666 0060a914-105e-4317-8476-b531fc8c72b2: 7071388 -> 7009999 0.060547s\n4115 cefa057c-90fa-4906-8edd-659841b2bdbc: 79172853794 -> 800IP_10344117_line002 s\n4678 46e15b8c-a5fe-4f21-a03b-3fba4f7f5985: 10007 -> 00970597101399 0.040039s\n7017 17a888e5-d9ca-4b90-8578-1d61aeb411dd: 10010 -> 900970597101399 0.04004s\n7365 abd3d03f-9457-4db2-be31-fb1eda9511cf: 7071388 -> 7009999 0.05957s\n8620 2d1595c0-e514-4cd4-918a-6c1efb26cf91: 7061113 -> 989172790635 s\n9429 24d62bf2-f30c-4ce0-8b0e-63e26e985456: 79196000705 -> 800IP_10344117_line002 s\n").to_stdout
      end 
   end 

  context '#create_call' do 
  	it 'should create new call (Struct) object' do 
  		line = 'dd8aeda2-0cb2-4081-8023-709fc7aa154e 2018-02-21 17:07:16.247070 [3480] [NOTICE] switch_channel.c:1034 New Channel sofia/internal/100@188.93.213.101 [dd8aeda2-0cb2-4081-8023-709fc7aa154e]'
  		line_number = 1
  		expect(FreeswitchLogParser.create_call(line, line_number)).to be_an_instance_of(FreeswitchLogParser::Call)
  		expect(FreeswitchLogParser.create_call(line, line_number).uuid).to eq('dd8aeda2-0cb2-4081-8023-709fc7aa154e')
  		expect(FreeswitchLogParser.create_call(line, line_number).abonent_a).to eq('100')
  		expect(FreeswitchLogParser.create_call(line, line_number).time_start).to eq(Time.parse('2018-02-21 17:07:16.247070'))
  		expect(FreeswitchLogParser.create_call(line, line_number).line_start).to eq(1)
  		expect(FreeswitchLogParser.create_call(line, line_number).lines).to be_an_instance_of(Array)
  		expect(FreeswitchLogParser.create_call(line, line_number).lines.size).to eq(0)
  		expect(FreeswitchLogParser.create_call(line, line_number).routes_pass_lines).to be_an_instance_of(Array)
  		expect(FreeswitchLogParser.create_call(line, line_number).routes_pass_lines.size).to eq(0)
  		expect(FreeswitchLogParser.create_call(line, line_number).routes_pass_names).to be_an_instance_of(Array)
  		expect(FreeswitchLogParser.create_call(line, line_number).routes_pass_names.size).to eq(0)
  		expect(FreeswitchLogParser.create_call(line, line_number).actions).to be_an_instance_of(Array)
  		expect(FreeswitchLogParser.create_call(line, line_number).actions.size).to eq(0)
  	end
  end 

  context '#find_uuids' do 
  	it 'should find uuid in string' do 
  		line = 'dd8aeda2-0cb2-4081-8023-709fc7aa154e 2018-02-21 17:07:16.247070 [3480] [NOTICE] switch_channel.c:1034 New Channel sofia/internal/100@188.93.213.101 [dd8aeda2-0cb2-4081-8023-709fc7aa154e]'
  		expect(FreeswitchLogParser.find_uuids(line)).to eq(['dd8aeda2-0cb2-4081-8023-709fc7aa154e','dd8aeda2-0cb2-4081-8023-709fc7aa154e'])
  		expect(FreeswitchLogParser.find_uuids(line)).to be_an_instance_of(Array)

  	end
  end 

  context '#parse_line' do 
  	string1 = 'dd8aeda2-0cb2-4081-8023-709fc7aa154e 2018-02-21 17:07:15.006835 [5600] [INFO] mod_dialplan_xml.c:558 Processing 10010 <10010>->00970597101399 in context external'
  	string3 = 'dd8aeda2-0cb2-4081-8023-709fc7aa154e Dialplan: sofia/internal/100@188.93.213.101 Regex (PASS) [all_calls_transfer_enable] destination_number(+106900970597773739) =~ /.*/ break=on-false'
  	string4 = 'dd8aeda2-0cb2-4081-8023-709fc7aa154e Dialplan: sofia/external/79608649424@sip.beeline.ru Action set(continue_on_fail=true)'
 		call = FreeswitchLogParser::Call.new()
 		call.time_start = Time.parse('2018-02-21 17:07:10.027343')
 		call.routes_pass_lines = []
 		call.routes_pass_names = []
 		call.actions = []
  	line_number = 10


  	context 'if line have "DESTROY going to sleep"' do 
  	  string = 'dd8aeda2-0cb2-4081-8023-709fc7aa154e 2018-02-21 17:07:15.027343 [5600] [DEBUG] switch_core_state_machine.c:588 (sofia/external/10010@188.93.213.101) State DESTROY going to sleep '

	  	it 'should change length of call' do
				FreeswitchLogParser.parse_line(string, call, line_number)
	  		expect(call.time_end).to eq(Time.parse('2018-02-21 17:07:15.027343'))
	  		expect(call.call_length).to eq(5)
	  	end
  	end
  end






















end