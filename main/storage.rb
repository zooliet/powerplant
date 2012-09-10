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
    attr_accessor :previous, :current, :max, :min, :average, :diff, :count, :sampled
  end
  
  def self.reset
    Storage::sampled  = Storage::FFT_SIZE.times.map { 0 } 
    Storage::previous = Storage::FFT_SIZE.times.map { 0 }    
    Storage::current  = Storage::FFT_SIZE.times.map { 0 }    
    Storage::max      = Storage::FFT_SIZE.times.map { 0 }    
    Storage::min      = Storage::FFT_SIZE.times.map { 100 }    
    Storage::average  = Storage::FFT_SIZE.times.map { 0 }    
    Storage::diff     = Storage::FFT_SIZE.times.map { 0 }    
    Storage::count    = 1
  end
  
  def self.fft

    #  below is the dummy FFT data just for testing
    # self::previous = Storage::FFT_SIZE.times.map { 20 + rand(50) }  
    # self::current  = Storage::FFT_SIZE.times.map { 20 + rand(50) }    
    # Storage::FFT_SIZE.times.each do |i|
    #   self::max[i]      = self::current[i] if self::current[i] >= self::max[i]
    #   self::min[i]      = self::current[i] if self::current[i] <= self::min[i]
    #   self::average[i] = ((self::current[i] + (self::average[i] * self::count))/(self::count + 1).to_f).round.to_i
    # end
    
    fm = ARM::FFTW.fft(Storage::sampled)
    # self::current = fm.to_a.map {|f| (10 * Math.log10(((f.real**2 + f.imaginary**2)**0.5).round(2) + 1)).to_i }
    self::current = fm.to_a.map do |f| 
      abs =  ((f.real**2 + f.imaginary**2)**0.5).to_i
      abs = 1 if abs == 0
      power = 10 * Math.log10(abs).to_i
      power = 1 if power == 0
      power      
    end
    # self::count += 1
  end
  
  def self.sampling
    file = "./adc.csv"
    Storage::sampled = CSV.readlines(file)[0].map {|v| v.to_f.round(2)}
  end
  
  def self.siggen(type)
    fs = 32000 # 32 kbps sampling
    f1 = 1000 # 1 khz
    a1 = 1
    f2 = 0
    a2 = 0 
    
    if type == '1'
      f1 = 1000   # 1 khz
    elsif type == '2'
      f1 = 2000   # 2 khz
    elsif type == '3'
      f1 = 10000  # 10 KHz
    elsif type == '4'
      f1 = 2000   # 2 KHz
      f2 = 10000  # 10 KHz
      a2 = 1
    elsif type == '5'
      f1 = 2000   # 2 KHz
      f2 = 10000  # 10 KHz
      a1 = 10
      a2 = 1
    else
      f1 = 1000   # 1 khz
    end
    
    CSV.open("./adc.csv", "wb") do |csv|
      # puts "***#{a1} : #{f1} : #{fs}"
      data = (0...Storage::FFT_SIZE).map do |n|
        a1 * Math.sin(2*Math::PI*f1*(n/fs.to_f)).round(2) + 
        a2 * Math.sin(2*Math::PI*f2*(n/fs.to_f)).round(2) 
      end
      csv << data
    end
  end
  
end