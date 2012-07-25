require 'bundler'
Bundler.require
require 'coffee-script'

require './storage.rb'
require './main_app'

use Rack::Reloader

run MainApp