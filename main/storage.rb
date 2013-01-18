require 'csv'

class Storage
  FFT_SIZE = 1024
  
  class << self
    attr_accessor :current, :average, :count, :sampled, :per_min_average
  end
  
  def self.reset
    Storage::current  = Storage::FFT_SIZE.times.map { 0 }    
    Storage::average  = Storage::FFT_SIZE.times.map { 0 }    
    Storage::sampled  = Storage::FFT_SIZE.times.map { 0 } 
    Storage::count    = 1
    File.delete('./history.csv') if File.exist?('.history.txt')
    
    Storage::per_min_average  = Storage::FFT_SIZE.times.map { 0 }    
    Storage::sec_5_count      = 0    
  end
  
  def self.store(result)
    self::current  = result    
    Storage::FFT_SIZE.times.each do |i|
      self::average[i] = ((self::current[i] + (self::average[i] * self::count))/(self::count + 1).to_f).round.to_i
    end
    self::count += 1

    Storage::per_min_average += self::average
    Storage::sec_5_count += 1
    if Storage::sec_5_count == 20
      Storage::per_min_average = Storage::per_min_average / Storage::sec_5_count
      Storage::sec_5_count = 0
      CSV.open('./history.csv', 'ab+') do |csv|
        csv <<   self::average
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
    # self.siggen(70000+rand(20000))
    file = "./adc.csv"
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