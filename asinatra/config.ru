require 'bundler'
Bundler.require
require './asinatra_app'

use Rack::Reloader

run AsinatraApp
