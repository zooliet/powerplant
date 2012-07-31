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
    fft      = lambda do |data| 
      puts "Perform FFT"; 
      Storage.fft       
      data = { 
        :previous => Storage::previous, 
        :current  => Storage::current,
        :average  => Storage::average,
        :max      => Storage::max, 
        :min      => Storage::min         
      }
      $ws.send(data.to_json)      
    end
    
    get "/" do
      @host_ip = local_ip 
      erb :index
    end

  	aget "/start.js" do
      if $timer
        puts "Skip timer"
      else
        Storage.reset
        $timer = EM.add_periodic_timer(5) do 
          puts Time.now
          EM.defer(sampling, fft)
          # data = { :previous => Storage::previous, :current  => Storage::current }
          # $ws.send(data.to_json)

          content_type "text/javascript"
          body "console.log('test.js')"
        end
        puts "Timer stared: #{$timer}"                
      end
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
      Storage.reset
      Storage.fft    
      data = { 
        :previous => Storage::previous, 
        :current  => Storage::current, 
        :average  => Storage::average, 
        :max      => Storage::max, 
        :min      => Storage::min, 
        :interval => params[:interval], 
        :type => params[:type]
      }
      content_type :json
      data.to_json
    end  	
    
    private
    def local_ip
      orig, Socket.do_not_reverse_lookup = Socket.do_not_reverse_lookup, true
      UDPSocket.open do |s|
        s.connect '64.233.187.99', 1
        s.addr.last
      end
    ensure
      Socket.do_not_reverse_lookup = orig
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