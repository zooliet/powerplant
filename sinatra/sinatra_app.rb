class SinatraApp < Sinatra::Base
	get "/" do
		"Hello, Time is #{Time.now}"
	end
end
