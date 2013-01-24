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
    
    fft  = lambda do |data|
      fm = ARM::FFTW.fft(data).to_a.map do |f|
        power =  ((f.real**2 + f.imaginary**2)**0.5).round(2)
        power_in_log = 10 * Math.log10(power)
        power_in_log = 0.0 if power_in_log.infinite?
        power_in_log.round(2).abs
      end      
      Storage.store(fm)      
      data = {             
        :average  => Storage::average, 
        :current  => Storage::current 
      }
      # puts("#{data.inspect}")
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
        $timer = EM.add_periodic_timer(5) do # $timer = EM.add_timer(5) do 
          puts Time.now          
          # EM.defer(storage_sampling, fft) 
          EM.defer(adc_sampling, fft)
          content_type "text/javascript"
          body "console.log('test.js')"
        end
        puts "Timer stared: #{$timer}"                
      end
      content_type "text/javascript"
      body "console.log('test.js')"
    end

  	aget "/stop.js" do
  	  if $timer
        puts "Timer stoped: #{$timer}"
  	    ret = EM.cancel_timer($timer)
        $timer = nil
  	  end
      content_type "text/javascript"
      body "console.log('test.js')"
  	end

    get "/calibration.js" do
      if $timer
        puts "Timer stopped: #{$timer}"
        EM.cancel_timer($timer)
        $timer = nil
      end
      # Storage.reset
      Storage.siggen
      Storage.sampling
      result = Storage.fft
      data = {             
        :average  => result, 
        :current  => result 
      }
      $ws.send(data.to_json)
            
      # EM.defer(storage_sampling, fft) 
      content_type "text/javascript"
      body "console.log('test.js')"
    end
        
    get "/application.js" do
      content_type "text/javascript"
      coffee :coffee
    end
    
    get "/spectrogram.json" do
  	  if $timer
        puts "Timer stoped: #{$timer}"
  	    ret = EM.cancel_timer($timer)
        $timer = nil
  	  end
      content_type :json
      file_5_sec = File.join(File.expand_path("..", __FILE__), "history_5_sec.csv") 
      file_1_min = File.join(File.expand_path("..", __FILE__), "history_1_min.csv") 
      file_1_hour = File.join(File.expand_path("..", __FILE__), "history_1_hour.csv") 
      # [[1,2,3,4],[5,6,7,8]].to_json
      # [['1','2','3','4'],['5','6','7','8']].to_json
      # { :key => 'value', :key2 => 'value2' }.to_json    
      if File.exist?(file_1_hour)
        CSV.readlines(file_1_hour).to_json         
      elsif File.exist?(file_1_min) and CSV.readlines(file_1_min).size >= 2
        CSV.readlines(file_1_min).to_json 
      else
        CSV.readlines(file_5_sec).to_json 
        # 0.upto(1).map {0.upto(1023).map {|e| e % 16}}.to_json
      end
    end
    
    get "/audio_start.js" do
      content_type "text/javascript"
      coffee :audio_start      
    end
    
    get "/audio_stop.js" do
      content_type "text/javascript"
      coffee :audio_stop      
    end
       
    get "/coffee_test.js" do
      content_type "text/javascript"
      coffee :coffee_test
    end
    
    get "/json_test.json" do
      content_type :json
      { :key => 'value', :key2 => 'value2' }.to_json
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
    end

    ws.onmessage do |msg|
      puts "got message #{msg}"
    end

    ws.onclose do
      puts "WebSocket is closing..."
      ws.send "WebSocket closed"
    end
  end
  
  MainApp.run!({:port => 3001})
end