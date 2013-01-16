require 'bundler'
Bundler.require
require 'socket'

require 'coffee-script'
require 'json'

require 'arm_fftw'
require 'pv_adc'

require './storage.rb'

EventMachine.run do     # <-- Changed EM to EventMachine
  class MainApp < Sinatra::Base
  	register Sinatra::Async
  	
  	configure :production do
      puts "Production configuration goes here..."
    end

    adc_sampling = lambda do
      PvADC.sampling
    end

    storage_sampling = lambda do 
      Storage.sampling
    end


    # fm = ARM::FFTW.fft(Storage::sampled)
    # # self::current = fm.to_a.map {|f| (10 * Math.log10(((f.real**2 + f.imaginary**2)**0.5).round(2) + 1)).to_i }
    # self::current = fm.to_a.map do |f| 
    #   power =  ((f.real**2 + f.imaginary**2)**0.5).round(2)
    #   power_in_log = 10 * Math.log10(power)
    #   power_in_log = 0.0 if power_in_log.infinite?
    #   power_in_log.round(2).abs
    # end
    
    fft  = lambda do |data|
      fm = ARM::FFTW.fft(data).to_a.map do |f|
        power =  ((f.real**2 + f.imaginary**2)**0.5).round(2)
        power_in_log = 10 * Math.log10(power)
        power_in_log = 0.0 if power_in_log.infinite?
        power_in_log.round(2).abs
      end
      data = {
        :current => fm
      }
      # puts "#{fm.inspect}"
      # data = { 
      #   # :previous => Storage::previous, 
      #   :current  => Storage::current,
      #   # :average  => Storage::average,
      #   # :max      => Storage::max, 
      #   # :min      => Storage::min         
      # }
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
        # Storage.reset
        $timer = EM.add_periodic_timer(5) do 
        # $timer = EM.add_timer(5) do 
          puts Time.now
          EM.defer(adc_sampling, fft)
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


    aget "/calibration.js" do
      if $timer
        EM.cancale_timer($timer)
        puts "Timer stopped: #{$timer}"
        $timer = nil
      end
      
      Storage.siggen
      data = {
        :current  => Storage::current
        # :interval => params[:interval], 
        # :type => params[:type]
      }
      EM.defer(storage_sampling, fft)
      content_type "text/javascript"
      # content_type :json
      # data.to_json
    end

    get "/test/:interval/:type.json" do
      # Storage.reset
      # Storage.fft    
      data = { 
        # :previous => Storage::previous, 
        :current  => Storage::current, 
        # :average  => Storage::average, 
        # :max      => Storage::max, 
        # :min      => Storage::min, 
        :interval => params[:interval], 
        :type => params[:type]
      }
      content_type :json
      data.to_json
    end  	
    
    aget "/siggen/:type.js" do
      # puts "***#{params[:type]}"
      Storage.siggen(params[:type])
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