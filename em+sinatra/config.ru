require 'bundler'
Bundler.require

require './em_sinatra_app'

use Rack::Reloader

class WebSocketApp < Rack::WebSocket::Application
	def on_open(env)
	  puts "client connected"
	  # EM.add_timer(5) do
	  #   send_data "This message should show-up 5 secs later"
	  # end
	  # 
	  # EM.add_timer(15) do
	  #   send_data "This message should show-up 15 secs later"
	  # end
	end

	def on_message(env, msg)
	  puts "message received: " + msg
	  send_data "Message: #{msg}"
	end

  def on_close(env)
    puts "client disconnected"
  end
end

map '/ws' do
  run WebSocketApp.new
end


map '/' do
	run EmSinatraApp
end
