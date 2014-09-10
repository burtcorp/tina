require 'thor'
require 'aws-sdk-core'

module Tina
  class CLI < Thor
    desc "restore MONTHLY_STORAGE DURATION PREFIX_FILE", "Restore files from Glacier into S3"
    def restore(monthly_storage, duration, prefix_file)
      duration_in_seconds = parse_duration(duration)

      s3 = Aws::S3::Client.new(region: 'eu-west-1')
      prefixes = File.readlines(prefix_file).map(&:chomp)
      objects = prefixes.flat_map do |bucket_prefix|
        bucket, prefix = bucket_prefix.split('/', 2)
        puts "Listing prefix #{bucket_prefix}..."
        s3.list_objects(bucket: bucket, prefix: prefix).contents.map do |object|
          { key: object.key, size: object.size }
        end
      end

      total_size = objects.reduce(0) { |memo, obj| memo + obj[:size] }

      restore_plan = RestorePlan.new(monthly_storage.to_i, total_size)
      price = restore_plan.price(duration_in_seconds)
      puts "Number of objects to restore: #{objects.size}"
      puts "Total restore size: #{total_size} B (or #{total_size / 1024 ** 2} MB, or #{total_size / 1024 ** 3} GB, or #{total_size / 1024 ** 4} TB)"
      puts "Restore duration: #{duration}"
      puts "Cost: $#{price}"
      return unless yes?("Are you this rich? [y/n]")
    end

    private

    UNIT_FACTORS = { 'd' => 24 * 3600, 'h' => 1 * 3600 }

    def parse_duration(duration)
      duration.match(/^(\d+)(h|d)$/)
      raise "DURATION not in required format, [0-9]+(h|d)" unless (count = $1.to_i rescue nil) && (unit = $2)
      count * UNIT_FACTORS[unit]
    end
  end
end
