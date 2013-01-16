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
      power =  ((f.real**2 + f.imaginary**2)**0.5).round(2)
      power_in_log = 10 * Math.log10(power)
      power_in_log = 0.0 if power_in_log.infinite?
      power_in_log.round(2).abs
    end
    # self::count += 1
  end
  
  def self.sampling
    file = "./adc.csv"
    Storage::sampled = CSV.readlines(file)[0].map {|v| v.to_f.round(2)}
  end
  
  def self.siggen
    fs = 195312.5 # 160 kbps sampling
    f1 = 20000 # 20 khz
    a1 = 1
    f2 = 40000 # 40 khz
    a2 = 1
    f3 = 60000 # 60 khz
    a3 = 1
    f4 = 80000 # 80 khz
    a4 = 1
    noise = false
    
    CSV.open("./adc.csv", "wb") do |csv|
      # puts "***#{a1} : #{f1} : #{fs}"
      data = (0...Storage::FFT_SIZE).map do |n|
        unless noise
          a1 * Math.sin(2*Math::PI*f1*(n/fs.to_f)).round(2) + 
          a2 * Math.sin(2*Math::PI*f2*(n/fs.to_f)).round(2) +
          a3 * Math.sin(2*Math::PI*f3*(n/fs.to_f)).round(2) +
          a4 * Math.sin(2*Math::PI*f4*(n/fs.to_f)).round(2) 
        else
          a1 * Math.sin(2*Math::PI*f1*(n/fs.to_f)).round(2) + 
          a2 * Math.sin(2*Math::PI*f2*(n/fs.to_f)).round(2) +
          rand(10)*0.01
        end
      end
      csv << data
    end
  end
  
end