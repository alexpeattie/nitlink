module Nitlink
  class HashWithIndifferentAccess < ::Hash
    def initialize(hash = {})
      super()
      hash.each do |key, value|
        self[convert_key(key)] = value
      end
    end

    def [](key)
      super(convert_key(key))
    end

    def []=(key, value)
      super(convert_key(key), value)
    end

    def delete(key)
      super(convert_key(key))
    end

    def fetch(key, *args)
      super(convert_key(key), *args)
    end

    def key?(key)
      super(convert_key(key))
    end

    def values_at(*indices)
      indices.map { |key| self[convert_key(key)] }
    end

    def merge(other)
      dup.merge!(other)
    end

    def merge!(other)
      other.each do |key, value|
        self[convert_key(key)] = value
      end
      self
    end

    def reverse_merge(other)
      self.class.new(other).merge(self)
    end

    def reverse_merge!(other_hash)
      replace(reverse_merge(other_hash))
    end

    def replace(other_hash)
      super(other_hash)
    end

    # Convert to a Hash with String keys.
    def to_hash
      Hash.new(default).merge!(self)
    end

    protected

    def convert_key(key)
      key.is_a?(Symbol) ? key.to_s : key
    end
  end
end