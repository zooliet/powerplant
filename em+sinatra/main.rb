require 'bundler'
Bundler.require

EventMachine.run do     # <-- Changed EM to EventMachine
  class App < Sinatra::Base
    register Sinatra::Async
    
    get '/' do
      erb :index
    end
    
    aget '/stop' do
      EM.cancel_timer(@@timer)
      body "Timer stops"
    end
    

  end

  EventMachine::WebSocket.start(:host => '0.0.0.0', :port => 8080) do |ws| # <-- Added |ws|
  # Websocket code here
  ws.onopen {
      ws.send "connected!!!!"
      @@timer = EM.add_periodic_timer(5) do
        puts "5 secs"
        ws.send "Send from websocket timer : #{Time.now}"
      end
  }

  ws.onmessage { |msg|
      puts "got message #{msg}"
  }

  ws.onclose   {
      ws.send "WebSocket closed"
  }

  end

  # You could also use Rainbows! instead of Thin.
  # Any EM based Rack handler should do.
  App.run!({:port => 3001})    # <-- Changed this line from Thin.start to App.run!
end