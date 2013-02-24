require 'bundler'
Bundler.require
require 'socket'

require 'coffee-script'
require 'json'
# require 'active_support/all'

require 'arm_fftw'
require 'pv_adc'

require './storage.rb'

EventMachine.run do    
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
      fm = (ARM::FFTW.fft(data)/(Storage::FFT_SIZE/2)).to_a
      Storage::current = Storage::FFT_SIZE.times.map do |i|
        # if i > 2 and i < Storage::FFT_SIZE - 3  # This is for blackman window
        #   f = (0.04 * fm[i-2]) + (0.25 * fm[i-1]) + (0.42 * fm[i]) + 
        #       (0.25 * fm[(i+1)%Storage::FFT_SIZE]) + (0.04 * fm[(i+2)%Storage::FFT_SIZE])
        if i > 1 and i < Storage::FFT_SIZE - 2    # For Hanning window
          f = 2 * fm[i] - fm[i-1] - fm[i+1]
        else
          f = fm[i]
        end
          
        power = 10 * Math.log10(Math.sqrt(f.real**2 + f.imaginary**2))
        if power.infinite?
          power = -80.0  # ???
        else
          power.round(2)
        end
      end

      Storage::average = Storage::current
      # Storage.store(fm)      
      data = {             
        :average  => Storage::average, 
        :current  => Storage::current 
      }
      # puts("#{data.inspect}")
      $ws.send(data.to_json)
    end
       
    Storage.reset 
    fft_only = lambda do |data|
      fm = (ARM::FFTW.fft(data)/(Storage::FFT_SIZE/2)).to_a
      Storage::accumulated = 
        [Storage::accumulated, Storage::current = Storage::FFT_SIZE.times.map do |i|
          if i > 1 and i < Storage::FFT_SIZE - 2    # For Hanning window
            f = 2 * fm[i] - fm[i-1] - fm[i+1]
          else
            f = fm[i]
          end
          
          power = 10 * Math.log10(Math.sqrt(f.real**2 + f.imaginary**2))
          if power.infinite?
            power = -80.0  # ???
          else
            power.round(2)
          end
        end
        ].transpose.map {|x| x.reduce(:+)}
      Storage::accumulated_count += 1
    end

    EM.add_periodic_timer(0.5) do 
      # EM.defer(storage_sampling, fft_only) 
      EM.defer(adc_sampling, fft_only)
    end

    get "/" do
      @host_ip = local_ip 
      if @host_ip == '127.0.0.1'
        @host_ip = '10.10.0.1'
      end
      puts "****IP: #{@host_ip}"
      erb :index
    end

  	aget "/start.js" do
      if $timer
        puts "Skip timer"
      else
        Storage.reset
        $timer = EM.add_periodic_timer(2) do # $timer = EM.add_timer(5) do 
          puts Time.now          
          # EM.defer(storage_sampling, fft) 
          # EM.defer(adc_sampling, fft)
          Storage.fft
          data = {             
            :average  => Storage::average, 
            :current  => Storage::current 
          }
          $ws.send(data.to_json)
          
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
      fm = (ARM::FFTW.fft(Storage::sampled)/(Storage::FFT_SIZE/2)).to_a
      Storage::current = Storage::FFT_SIZE.times.map do |i|
        if i > 1 and i < Storage::FFT_SIZE - 2    # For Hanning window
          f = 2 * fm[i] - fm[i-1] - fm[i+1]
        else
          f = fm[i]
        end
          
        power = 10 * Math.log10(Math.sqrt(f.real**2 + f.imaginary**2))
        if power.infinite?
          power = -80.0  # ???
        else
          power.round(2)
        end
      end

      Storage::average = Storage::current
      data = {             
        :average  => Storage::average, 
        :current  => Storage::current 
      }
      # puts("#{data.inspect}")
      $ws.send(data.to_json)
            
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
      file = File.join(File.expand_path("..", __FILE__), "history.csv") 
      # [[1,2,3,4],[5,6,7,8]].to_json
      # [['1','2','3','4'],['5','6','7','8']].to_json
      # { :key => 'value', :key2 => 'value2' }.to_json    
      if File.exist?(file)
        CSV.readlines(file).to_json 
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