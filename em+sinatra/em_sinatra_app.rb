
class EmSinatraApp < Sinatra::Base
	register Sinatra::Async

	q = EM::Queue.new

	aget "/" do
		body "Eventmachin with Sinatra\n"
 	end

	aget "/delay/:n" do |n|
		puts "Starts..."
		EM.add_timer(n.to_i) do
			q.push(n)
			body "delayed #{n} seconds.\n"
		end
	end

	op = Proc.new do
	  sleep(2) 
		[1, 2]
	end

  cb = Proc.new do |first, second| 
		puts "CALLBACK #{first} #{second}"
	end

	EM.defer(op, cb) 


	work = lambda do |item|
		puts item
		EM.next_tick { q.pop(&work) }
	end
	
	q.pop(&work)

end
