require 'eventmachine'
require 'em-redis'

EM.run do
	puts "Start EM run loop"
	EM.add_periodic_timer(10) do
		puts "Periodic Timer"
	end

#	EM.add_timer(10) do
#		puts "Stop EM run loop"
#		EM.stop
#	end

	op = Proc.new { puts "OPERATION"; [1, 2] }
  cb = Proc.new { |first, second| puts "CALLBACK #{first} #{second}"}

  EM.defer(op, cb)
  
  redis = EM::Protocols::Redis.connect

  redis.errback do |code|
    puts "Error code: #{code}"
  end

  redis.set "a", "foo" do |response|
    redis.get "a" do |response|
      puts response
    end
  end

  # We get pipelining for free
  redis.set("b", "bar")
  redis.get("a") do |response|
    puts response # will be foo
  end
end
