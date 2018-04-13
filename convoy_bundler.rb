require 'stringio'

class ConvoyBundler
  def self.call(s)
    puts new(s).bundles.join("\n")
  end

  def initialize(s)
    @bundles_to = BundlesTo.new
    @bundles_from = BundlesFrom.new
    @completes = []

    if s.is_a?(IO)
      add_shipments(s)
    elsif File.file?(s)
      File.open(s) { |f| add_shipments(f) }
    else
      StringIO.open(s) { |io| add_shipments(io) }
    end
  end

  def count
    bundles.count
  end

  def bundles
    ((@bundles_from.all + @bundles_to.all).uniq + @completes).map(&:describe)
  end

  private

  def add_shipments(io)
    io.each { |line| add_shipment(line) }
  end

  def add_shipment(line)
    shipment = Shipment.make(line)

    bundle_before = @bundles_to.pop(shipment.src)
    @bundles_from.delete(bundle_before)

    bundle_after = @bundles_from.pop(shipment.dst)
    @bundles_to.delete(bundle_after)

    bundle = bundle_before&.append(shipment) || Bundle.new(shipment)
    bundle.concat(bundle_after) if bundle_after

    if bundle.complete?
      @completes << bundle
    else
      @bundles_from.push(bundle)
      @bundles_to.push(bundle)
    end
  end

  private

  class Loc # Day-city pair suitable for use as a Hash key
    DAY_NUMS = %w[M T W R F].each_with_index.to_h.freeze
    DAY_STRS = DAY_NUMS.invert.freeze

    def self.day_num(s)
      DAY_NUMS[s]
    end

    def self.day_str(n)
      DAY_STRS[n]
    end

    attr_reader :day, :city

    def initialize(day, city)
      raise ArgumentError unless self.class.day_str(day)
      @day = day
      @city = city
    end

    def connects_from
      self.class.new(day - 1, city) if day > self.class.day_num('M')
    end

    def connects_to
      self.class.new(day + 1, city) if day < self.class.day_num('F')
    end

    def ==(other)
      self.class === other && key == other.key
    end
    alias eql? ==

    def hash
      key.hash
    end

    def key
      [day, city]
    end
  end

  class Shipment
    attr_reader :id, :src, :dst

    def initialize(id, src_city, dst_city, day)
      raise ArgumentError unless id && src_city && dst_city
      @id = id
      @src = Loc.new(day, src_city)
      @dst = Loc.new(day, dst_city)
    end

    def connects_to
      dst.connects_to
    end

    def connects_from
      src.connects_from
    end

    def self.make(line)
      row = line.split(/\s/)

      # validate number of fields
      n = 4
      count = row.length
      unless count == n
        raise "Expected #{n} space-delimited values, got #{count} in #{line}"
      end

      # validate and convert day field
      day = Loc.day_num(row[3])
      if day
        row[3] = day
      else
        expected = "one of: #{Loc::DAYS.keys.join(' | ')}"
        raise "Expected day to be #{expected}, got #{row[3]} in #{line}"
      end

      new(*row)
    end
  end

  class Bundle
    attr_reader :shipments

    def initialize(shipment)
      @shipments = [shipment] # Array<Shipment>
    end

    def append(shipment)
      @shipments.append(shipment)
      self
    end

    def concat(other)
      @shipments += other.shipments
    end

    def connects_from
      @shipments.first.connects_from
    end

    def connects_to
      @shipments.last.connects_to
    end

    def complete?
      connects_from.nil? && connects_to.nil?
    end

    def describe
      @shipments.map(&:id).join(' ')
    end
  end

  class Bundles
    def initialize
      @bundles = {} # key: Location, value: Array<Bundle>
    end

    def push(bundle)
      loc = connection(bundle)
      if (loc)
        @bundles[loc] ||= []
        @bundles[loc].push(bundle)
      end
    end

    def delete(bundle)
      loc = connection(bundle)
      @bundles[loc].delete(bundle) if loc
    end

    def pop(loc)
      @bundles[loc]&.pop
    end

    def all
      @bundles.values.flatten
    end
  end

  class BundlesFrom < Bundles
    def connection(bundle)
      bundle&.connects_from
    end
  end

  class BundlesTo < Bundles
    def connection(bundle)
      bundle&.connects_to
    end
  end
end
