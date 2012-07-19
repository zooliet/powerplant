class Beagle < Thor 
	include Thor::Actions
  desc "test THING", "thor test command"
	method_option :flag,
								:type => :boolean, 
								:desc => 'added option', 
								:default => true

  def test(something=nil)
		flag = "--flag" if options[:flag]
    puts "Hello, Beagle::test(#{something}) #{flag}"
		inside "." do
			run "ls -al", {:verbose => false}
    end
  end
end

