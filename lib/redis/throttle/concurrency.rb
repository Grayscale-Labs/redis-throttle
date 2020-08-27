# frozen_string_literal: true

class Redis
  class Throttle
    class Concurrency
      # @!attribute [r] bucket
      #   @return [String] Throttling group name
      attr_reader :bucket

      # @!attribute [r] limit
      #   @return [Integer] Max allowed concurrent units
      attr_reader :limit

      # @!attribute [r] ttl
      #   @return [Integer] Time (in seconds) to hold the lock before
      #     releasing it (in case it wasn't released already)
      attr_reader :ttl

      # @param bucket [#to_s] Throttling group name
      # @param limit [#to_i] Max allowed concurrent units
      # @param ttl [#to_i] Time (in seconds) to hold the lock before
      #   releasing it (in case it wasn't released already)
      def initialize(bucket, limit:, ttl:)
        @bucket = -bucket.to_s
        @limit  = limit.to_i
        @ttl    = ttl.to_i
      end

      # @api private
      def key
        "throttle:#{@bucket}:c:#{@limit}:#{@ttl}"
      end

      alias to_s key

      # @api private
      def payload
        ["concurrency", @limit, @ttl]
      end

      # @api private
      #
      # Returns `true` if `other` is a {Concurrency} instance with the same
      # {#bucket}, {#limit}, and {#ttl}.
      #
      # @see https://docs.ruby-lang.org/en/master/Object.html#method-i-eql-3F
      # @param other [Object]
      # @return [Boolean]
      def ==(other)
        equal?(other) || (other.is_a?(self.class) && key == other.key)
      end

      alias eql? ==

      # @api private
      #
      # Compare `self` with `other` strategy:
      #
      # - Returns `nil` if `other` is neither {Concurrency} nor {Threshold}
      # - Returns `1` if `other` is a {Threshold}
      # - Returns `1` if `other` is a {Concurrency} with lower {#limit}
      # - Returns `0` if `other` is a {Concurrency} with the same {#limit}
      # - Returns `-1` if `other` is a {Concurrency} with bigger {#limit}
      #
      # @return [-1, 0, 1, nil]
      def <=>(other)
        complexity <=> other.complexity if other.respond_to? :complexity
      end

      # @api private
      #
      # Generates an Integer hash value for this object.
      #
      # @see https://docs.ruby-lang.org/en/master/Object.html#method-i-hash
      # @return [Integer]
      def hash
        key.hash
      end

      # @api private
      #
      # @return [Array(Integer, Integer)] Strategy complexity pseudo-score
      def complexity
        [1, @limit]
      end
    end
  end
end
