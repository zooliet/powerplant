
class AsinatraApp < Sinatra::Base
	register Sinatra::Async

	aget '/' do
		body { "#{env.inspect.to_yaml}" }
	end

	aget '/delay/:n' do |n|
		puts "Starts..."
		EM.add_timer(n.to_i) { body {"delayed for #{n} seconds\n"} }
  end
end
