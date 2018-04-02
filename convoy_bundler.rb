class ConvoyBundler
  DAYS = %w[M T W R F].each_with_index.to_h.freeze

  def self.call(filepath)
    puts new.ingest_file(filepath).bundles
  end

  def initialize
    @shipments = {}
  end

  def ingest_file(filepath)
    File.open(filepath) { |f| ingest_io(f) }
    self
  end

  def ingest_str(s)
    require 'stringio'
    StringIO.open(s) { |io| ingest_io(io) }
    self
  end

  def ingest_io(io)
    io.each { |line| ingest(*parse!(line)) }
    self
  end

  def ingest(id, src, dst, day)
    @shipments[id] = Shipment.new(src, dst, day)
    self
  end

  def bundles
    return @bundles if defined? @bundles
    @bundles = @shipments.keys
  end

  private

  Shipment = Struct.new(:src, :dst, :day) do
    def connects?(other)
      other.day == day + 1 && other.src == dst
    end
  end

  def parse!(s)
    s.split(/\s/).tap do |row|
      # validate number of fields
      n = 4
      count = row.length
      unless count == n
        raise "Expected #{n} whitespace-delimited values, got #{count} in #{s}"
      end

      # validate and convert day field
      day = DAYS[row[3]]
      if day
        row[3] = day
      else
        raise "Expected day: <#{DAYS.keys.join(' | ')}>, got #{row[3]} in#{s}"
      end
    end
  end
end
