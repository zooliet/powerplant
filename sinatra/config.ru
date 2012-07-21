require 'bundler'
Bundler.require
require './sinatra_app'

use Rack::Reloader

run SinatraApp


