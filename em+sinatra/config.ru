require 'bundler'
Bundler.require

require './em_sinatra_app'

use Rack::Reloader

run EmSinatraApp
