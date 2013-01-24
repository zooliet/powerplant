require 'csv'
require 'fileutils'

class Storage
  FFT_SIZE = 1024
  
  class << self
    attr_accessor :current, :average, :count, :sampled, :per_min_average, :sec_5_count, :min_1_count
  end
  
  def self.reset
    Storage::current  = Storage::FFT_SIZE.times.map { 0 }    
    Storage::average  = Storage::FFT_SIZE.times.map { 0 }    
    Storage::sampled  = Storage::FFT_SIZE.times.map { 0 } 
    Storage::count    = 1
    file = File.join(File.expand_path("..", __FILE__), "history_1_hour.csv")
    FileUtils.rm(file) if File.exist?(file)
    
    Storage::per_min_average  = Storage::FFT_SIZE.times.map { 0 }    
    Storage::sec_5_count      = 0    
    Storage::min_1_count     = 0
  end
  
  def self.store(result)
    self::current  = result    
    Storage::FFT_SIZE.times.each do |i|
      if self::count == 1
        self::average[i] = self::current[i]
      else
        self::average[i] = ((self::current[i] + (self::average[i] * self::count))/(self::count + 1).to_f).round.to_i
      end
    end
    self::count += 1

    file_5_sec = File.join(File.expand_path("..", __FILE__), "history_5_sec.csv") 
    CSV.open(file_5_sec, 'ab+') do |csv|
      csv <<   self::current
    end

    Storage::per_min_average += self::average
    Storage::sec_5_count += 1
    # puts "***#{Storage::sec_5_count}@#{Time.now}"
    if Storage::sec_5_count == 12  # 1 min
      Storage::per_min_average = Storage::per_min_average.map {|e| e / Storage::sec_5_count} 
      Storage::sec_5_count = 0
      # puts "***history_5_sec.csv deleted@#{Time.now}"
      FileUtils.rm(file_5_sec)
      file_1_min = File.join(File.expand_path("..", __FILE__), "history_1_min.csv") 
      CSV.open(file_1_min, 'ab+') do |csv|
        csv <<   self::average
      end
      
      Storage::min_1_count += 1
      if Storage::min_1_count == 60  # 1 hour
        file_1_hour = File.join(File.expand_path("..", __FILE__), "history_1_hour.csv") 
        FileUtils.cp(file_1_min, file_1_hour)
        FileUtils.rm(file_1_min)
        Storage::min_1_count = 0
      end
    end
  end
  
  def self.fft    
    fm = ARM::FFTW.fft(Storage::sampled)
    self::current = fm.to_a.map do |f| 
      power =  ((f.real**2 + f.imaginary**2)**0.5).round(2)
      power_in_log = 10 * Math.log10(power)
      power_in_log = 0.0 if power_in_log.infinite?
      power_in_log.round(2).abs
    end
  end
  
  def self.sampling
    self.siggen(70000+rand(20000))
    file = File.join(File.expand_path("..", __FILE__), "adc.csv")  
    Storage::sampled = CSV.readlines(file)[0].map {|v| v.to_f.round(2)}
  end
  
  
  def self.siggen(freq = 80000)
    fs = 195312.5 # 160 kbps sampling
    f1 = 20000 # 20 khz
    a1 = 1
    f2 = 40000 # 40 khz
    a2 = 1
    f3 = 60000 # 60 khz
    a3 = 1
    f4 = freq
    a4 = 1
    noise = false
    
    file = File.join(File.expand_path("..", __FILE__), "adc.csv")  
    CSV.open(file, "wb") do |csv|
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