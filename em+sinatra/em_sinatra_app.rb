
class EmSinatraApp < Sinatra::Base
	register Sinatra::Async

	q = EM::Queue.new

	work = lambda do |item|
		puts item
		EM.next_tick { q.pop(&work) }
		[1, 2]
	end

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

  EM.next_tick do
	  op = Proc.new do
      sleep(2) 
      [1, 2]
      # q.pop(&work)
	  end

    cb = Proc.new do |first, second| 
		  puts "CALLBACK #{first} #{second}"
      q.pop do
  	    EM.defer(op, cb) 
  	  end
	  end

	  EM.defer(op, cb) 
	end


	
  # q.pop(&work)

end
