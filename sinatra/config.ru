require 'bundler'
Bundler.require
require 'coffee-script'

require './sinatra_app'

use Rack::Reloader

run SinatraApp


