
class MainApp < Sinatra::Base
	register Sinatra::Async

  get "/" do
    erb :index
  end
	
	get "/test" do
	  erb :test
	end

  get "/application.js" do
    content_type "text/javascript"
    coffee :coffee
  end

  get "/start/:interval/:type.json" do
    Storage.fft    
    data = { 
      :previous => Storage::previous, :current  => Storage::current, 
      :interval => params[:interval], :type => params[:type]
    }
    content_type :json
    data.to_json
  end


  # get "/coffee_test.js" do
  #   content_type "text/javascript"
  #   coffee :coffee_test
  # end
  # 
  # get "/json_test.json" do
  #   content_type :json
  #   { :key => 'value', :key2 => 'value2' }.to_json
  # end

  # q = EM::Queue.new
  # 
  # work = lambda do |item|
  #   puts item
  #   EM.next_tick { q.pop(&work) }
  #   [1, 2]
  # end

  # aget "/" do
  #   body "Eventmachin with Sinatra\n"
  #   end
  # 
  # aget "/delay/:n" do |n|
  #   puts "Starts..."
  #   EM.add_timer(n.to_i) do
  #     q.push(n)
  #     body "delayed #{n} seconds.\n"
  #   end
  # end
  # 
  #   EM.next_tick do
  #   op = Proc.new do
  #       sleep(2) 
  #       [1, 2]
  #       # q.pop(&work)
  #   end
  # 
  #     cb = Proc.new do |first, second| 
  #     puts "CALLBACK #{first} #{second}"
  #       q.pop do
  #         EM.defer(op, cb) 
  #       end
  #   end
  # 
  #   EM.defer(op, cb) 
  # end
  # 
  #   # q.pop(&work)
end
