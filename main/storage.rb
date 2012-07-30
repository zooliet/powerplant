require 'csv'

class Storage
  FFT_SIZE = 1024
  # @previous = Array.new(FFT_SIZE)
  # @current  = Array.new(FFT_SIZE)
  # @max      = Array.new(FFT_SIZE)
  # @min      = Array.new(FFT_SIZE)
  # @average  = Array.new(FFT_SIZE)
  # @diff     = Array.new(FFT_SIZE)
  # @count    = 1
  
  class << self
    attr_accessor :previous, :current, :max, :min, :average, :diff, :count
  end
  
  def self.reset
    Storage::previous = Storage::FFT_SIZE.times.map { 0 }    
    Storage::current  = Storage::FFT_SIZE.times.map { 0 }    
    Storage::max      = Storage::FFT_SIZE.times.map { 0 }    
    Storage::min      = Storage::FFT_SIZE.times.map { 100 }    
    Storage::average  = Storage::FFT_SIZE.times.map { 0 }    
    Storage::diff     = Storage::FFT_SIZE.times.map { 0 }    
    Storage::count    = 1
  end
  
  def self.fft
    # file = "#{Rails.root}/log/adc.csv"
    # current = CSV.readlines(file)[0].map {|v| v.to_f.round(2)}
    # previous = CSV.readlines(file)[1].map {|v| v.to_f.round(2)}

    #  do some work here with those sampling data
    # Storage::previous = Storage::FFT_SIZE.times.map { 30 + rand(30) }
    self::current  = Storage::FFT_SIZE.times.map { 20 + rand(50) }    
    # self::average  = Storage::FFT_SIZE.times.map { 20 + rand(50) }    
    # self::max  = Storage::FFT_SIZE.times.map { 20 + rand(50) }    
    # self::min  = Storage::FFT_SIZE.times.map { 20 + rand(50) }    
    Storage::FFT_SIZE.times.each do |i|
      self::max[i]      = self::current[i] if self::current[i] >= self::max[i]
      self::min[i]      = self::current[i] if self::current[i] <= self::min[i]
      # self::average[i]  = (self::current[i] + self::average[i]) / self::count
      # self::diff[i]     = self::current[i] - self::average[i]
      self::average[i] = 45
      # self::min[i] = 20
    end
    self::count += 1
  end
  
  def self.sampling
    
  end
end