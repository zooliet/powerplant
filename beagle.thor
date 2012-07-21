class Beagle < Thor 
	include Thor::Actions

  desc "check THING", "thor test command"
	method_option :flag,
								:type => :boolean, 
								:desc => 'added option', 
								:default => true
  def check(something=nil)
		flag = "--flag" if options[:flag]
    puts "Hello, Beagle::test(#{something}) #{flag}"
		inside "." do
			run "ls -al", {:verbose => false}
    end
  end

	desc "sinatra", "run basic sinatra"
	def sinatra(port=3000)
		inside "sinatra" do
			run "rackup --port #{port}", {:verbose => false}
		end	
	end

	desc "asinatra", "run async sinatra"
	def asinatra(port=3000)
		inside "asinatra" do
			run "rackup --port #{port}", {:verbose => false}
		end	
  end

	desc "em", "run eventmachine task"
	def em
		inside "eventmachine" do
			run "ruby em_app.rb", {:verbose => false}
		end
	end

	desc "em_sinatra", "run sinatra in eventmachin"
	def em_sinatra(port = 3000)
		inside "em+sinatra" do
			run "rackup --port #{port}", {:verbose => false}
		end
	end
end

