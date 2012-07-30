require 'csv'

class Storage
  FFT_SIZE = 1024
  @previous = Array.new(FFT_SIZE)
  @current  = Array.new(FFT_SIZE)
  @max      = Array.new(FFT_SIZE)
  @min      = Array.new(FFT_SIZE)
  @average  = Array.new(FFT_SIZE)
  @diff     = Array.new(FFT_SIZE)
  
  class << self
    attr_accessor :previous, :current, :max, :min, :average, :diff
  end
  
  def self.fft
    # file = "#{Rails.root}/log/adc.csv"
    # current = CSV.readlines(file)[0].map {|v| v.to_f.round(2)}
    # previous = CSV.readlines(file)[1].map {|v| v.to_f.round(2)}

    #  do some work here with those sampling data
    Storage::previous = Storage::FFT_SIZE.times.map { 30 + rand(30) }
    Storage::current  = Storage::FFT_SIZE.times.map { 35 + rand(30) }    
  end
  
  def self.sampling
    
  end
end