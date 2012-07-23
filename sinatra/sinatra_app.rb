
class SinatraApp < Sinatra::Base
	get "/" do
		erb :test
	end
	
	get "/test" do
	  erb :test
	end
	
	get "/application.js" do
	  coffee :coffee
  end

	get "/coffee_test.js" do
	  content_type "text/javascript"
	  coffee :coffee_test
  end

	get "/json_test.json" do
	  content_type :json
    { :key => 'value', :key2 => 'value2' }.to_json
  end
end
