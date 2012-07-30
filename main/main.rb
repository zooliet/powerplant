require 'bundler'
Bundler.require
require 'socket'

require 'coffee-script'
require 'json'

require './storage.rb'

EventMachine.run do     # <-- Changed EM to EventMachine
  class MainApp < Sinatra::Base
  	register Sinatra::Async
  	
  	configure :production do
      puts "Production configuration goes here..."
    end

    sampling = lambda { puts "Get sampled data" }
    fft      = lambda { |data| puts "Perform FFT" }
    
    get "/" do
      @host_ip = IPSocket.getaddress(Socket.gethostname)      
      erb :index
    end

  	aget "/start.js" do
      # if $timer
      #   puts "Skip timer"
      # else
      $timer = EM.add_timer(5) do 
        puts Time.now
        EM.defer(sampling, fft)
        data = { :previous => Storage::previous, :current  => Storage::current }
        $ws.send(data.to_json)

        content_type "text/javascript"
        body "console.log('test.js')"
      end
      puts "Timer stared: #{$timer}"                
      # end
    end

  	aget "/stop.js" do
  	  EM.cancel_timer($timer)
      puts "Timer stoped: #{$timer}"
  	  $timer = nil
  	end

    get "/application.js" do
      content_type "text/javascript"
      coffee :coffee
    end

    get "/test/:interval/:type.json" do
      Storage.fft    
      data = { 
        :previous => Storage::previous, :current  => Storage::current, 
        :interval => params[:interval], :type => params[:type]
      }
      content_type :json
      data.to_json
    end  	
  end
  
  EventMachine::WebSocket.start(:host => '0.0.0.0', :port => 8080) do |ws| # <-- Added |ws|
    ws.onopen do
      puts "Connection created"
      $ws = ws
      # ws.send "connected!!!!"
      # @@timer = EM.add_periodic_timer(5) do
      #   puts "5 secs"
      #   ws.send "Send from websocket timer : #{Time.now}"
      # end
    end

    ws.onmessage do |msg|
      puts "got message #{msg}"
    end

    ws.onclose do
      ws.send "WebSocket closed"
    end

  end
  

  
  MainApp.run!({:port => 3001})
end