require 'eventmachine'

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

end
