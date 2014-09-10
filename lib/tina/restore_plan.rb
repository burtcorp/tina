module Tina
  class RestorePlan

    DAILY_FREE_TIER_ALLOWANCE_FACTOR = 0.05
    DAYS_PER_MONTH = 30
    PRICE_PER_GB_PER_HOUR = 0.011

    def initialize(monthly_storage_size, restore_size, options = {})
      @monthly_storage_size = monthly_storage_size
      @restore_size = restore_size
      @price_per_gb_per_hour = options[:price_per_gb_per_hour] || PRICE_PER_GB_PER_HOUR

      @daily_allowance = @monthly_storage_size * DAILY_FREE_TIER_ALLOWANCE_FACTOR / DAYS_PER_MONTH
    end

    def price(total_time)
      quadhours = ([total_time, 1].max.to_f / (4 * 3600)).ceil
      quadhourly_allowance = @daily_allowance / ( [(24 / 4), quadhours].min * 4)

      peak_retrieval_rate = @restore_size / quadhours / 4
      peak_billable_retrieval_rate = [0, peak_retrieval_rate - quadhourly_allowance].max

      peak_billable_retrieval_rate * (@price_per_gb_per_hour / 1024 ** 3) * 720
    end
  end
end
