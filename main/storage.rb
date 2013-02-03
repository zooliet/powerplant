require 'csv'
require 'fileutils'

class Storage
  FFT_SIZE = 1024
  
  class << self
    attr_accessor :current, :average, :summation, :accumulated, :sampled,
                  :summation_count, :accumulated_count  
  end
  
  def self.reset
    Storage::current            = Storage::FFT_SIZE.times.map { -30 }    
    Storage::average            = Storage::FFT_SIZE.times.map { 0 }    

    Storage::summation          = Storage::FFT_SIZE.times.map { 0 }     
    Storage::summation_count    = 0

    Storage::accumulated        = Storage::FFT_SIZE.times.map { 0 } 
    Storage::accumulated_count  = 0

    Storage::sampled            = Storage::FFT_SIZE.times.map { 0 } 
    
    file = File.join(File.expand_path("..", __FILE__), "history.csv")
    FileUtils.rm(file) if File.exist?(file)    
  end
  
  def self.average_reset
    Storage::average            = Storage::current   

    Storage::summation          = Storage::FFT_SIZE.times.map { 0 }     
    Storage::summation_count    = 0    
  end
  
  def self.store!
    file = File.join(File.expand_path("..", __FILE__), "history.csv") 
    CSV.open(file, 'ab+') do |csv|
      csv << self::current
    end
  end
  
  def self.store_reset
    file = File.join(File.expand_path("..", __FILE__), "history.csv")
    FileUtils.rm(file) if File.exist?(file)        
  end
  
  def self.fft    
    Storage::current = (0...Storage::FFT_SIZE).map do |i|
      Storage::accumulated[i] / Storage::accumulated_count                                
    end
    
    Storage::summation_count += 1
    Storage::summation = [Storage::summation, Storage::current].transpose.map {|x| x.reduce(:+)}
        
    Storage::average = Storage::summation.map {|x| x / Storage::summation_count}
    
    Storage::accumulated  = Storage::FFT_SIZE.times.map { 0 } 
    Storage::accumulated_count = 0    
    self.store!    
    
    if Storage::summation_count > 100  # maybe 300 sec or so...
      Storage.average_reset
      Storage.store_reset
    end
  end
  
  def self.sampling
    self.siggen(rand(90000))
    file = File.join(File.expand_path("..", __FILE__), "adc.csv")  
    Storage::sampled = CSV.readlines(file)[0].map {|v| v.to_f.round(2)}
  end
    
  def self.siggen(freq = 80000)
    fs = 195312.5 # 160 kbps sampling
    a0 = 32768    # for DC
    f1 = 20000    # 20 khz
    a1 = 300
    f2 = 30000    # 30 khz
    a2 = 30000
    f3 = 40000    # 40 khz
    a3 = 30
    f4 = freq
    a4 = rand(30000)
    
    file = File.join(File.expand_path("..", __FILE__), "adc.csv")  
    CSV.open(file, "wb") do |csv|
      data = (0...Storage::FFT_SIZE).map do |n|
        a0 +
        a1 * Math.sin(2*Math::PI*f1*(n/fs.to_f)).round(4) + 
        a2 * Math.sin(2*Math::PI*f2*(n/fs.to_f)).round(4) +
        a3 * Math.sin(2*Math::PI*f3*(n/fs.to_f)).round(4) +
        a4 * Math.sin(2*Math::PI*f4*(n/fs.to_f)).round(4) 
      end
      csv << data
    end
  end
end