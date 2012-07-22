class SinatraApp < Sinatra::Base
	get "/" do
		"Hello, Time is #{Time.now}"
	end
	
	get "/start" do
	  erb :start
	end
	
	get '/coffee.js' do
	  content_type "text/javascript"
	  coffee :coffee
	end
end
