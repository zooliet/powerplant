
class EmSinatraApp < Sinatra::Base
	register Sinatra::Async

	q = EM::Queue.new

	work = lambda do |item|
		puts item
		EM.next_tick { q.pop(&work) }
		[1, 2]
	end

  before do 
    puts "Before"
  end
  
  after do
    puts "After"
  end

	aget "/" do
    body "<h2>Eventmachin with Sinatra</h2>"
 	end

	aget "/delay/:n" do |n|
		puts "Starts: #{params[:n]}"
		EM.add_timer(n.to_i) do
			q.push(n)
  		body "<h2>delayed: #{n} seconds</h2>"
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
