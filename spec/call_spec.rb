require 'freeswitch_log_parser/call' 

describe Call do 
   context "With valid input" do 
      it "creates Call object" do 
         call = Call.new 
         expect(call.class).to be Call
      end 
   end 
end