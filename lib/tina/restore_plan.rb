module Tina
  class RestorePlan

    MONTHLY_FREE_TIER_ALLOWANCE_FACTOR = 0.05
    DAYS_PER_MONTH = 30
    PRICE_PER_GB_PER_HOUR = 0.011

    def initialize(total_storage_size, objects, total_time, options = {})
      @total_storage_size = total_storage_size
      @objects = objects
      @total_time = [total_time, 4 * 3600].max
      @price_per_gb_per_hour = options[:price_per_gb_per_hour] || PRICE_PER_GB_PER_HOUR

      @daily_allowance = @total_storage_size * MONTHLY_FREE_TIER_ALLOWANCE_FACTOR / DAYS_PER_MONTH
    end

    def price
      largest_chunk_object_size = object_chunks.map { |chunk| chunk.map(&:size).reduce(&:+) }.max
      quadhours = object_chunks.size
      quadhourly_allowance = @daily_allowance / ( [(24 / 4), quadhours].min * 4)

      peak_retrieval_rate = largest_chunk_object_size / 4
      peak_billable_retrieval_rate = [0, peak_retrieval_rate - quadhourly_allowance].max

      peak_billable_retrieval_rate * (@price_per_gb_per_hour / 1024 ** 3) * 720
    end

    def object_chunks
      @object_chunks ||= @objects.chunk(quadhourly_restore_rate)
    end

    private

    def quadhourly_restore_rate
      @objects.total_size / (@total_time / (4 * 3600))
    end

    class ObjectCollection
      attr_reader :total_size

      def initialize(objects)
        @objects = objects
        @total_size = objects.map(&:size).reduce(&:+)
      end

      def size
        @objects.size
      end

      def chunk(max_chunk_size)
        sum = 0
        index = 0
        chunks = @objects.chunk do |object|
          sum += object.size
          if sum > max_chunk_size
            sum = object.size
            index += 1
          end
          index
        end
        chunks.map(&:last)
      end
    end
  end
end
