require 'thor'
require 'aws-sdk-core'

module Tina
  class CLI < Thor
    desc "restore TOTAL_STORAGE DURATION PREFIX_FILE KEEP_DAYS", "Restore files from Glacier into S3"
    def restore(total_storage, duration, prefix_file, keep_days)
      duration_in_seconds = parse_duration(duration)
      keep_days = keep_days.to_i

      prefixes = File.readlines(prefix_file).map(&:chomp)
      objects = RestorePlan::ObjectCollection.new(s3_client.list_bucket_prefixes(prefixes))
      restore_plan = RestorePlan.new(total_storage.to_i, objects)
      price = restore_plan.price(duration_in_seconds)
      chunks = objects.chunk(duration_in_seconds)
      say
      say "Restores will be performed in the following chunks:"
      say "-" * 60
      chunks.each_with_index do |chunk, index|
        chunk_size = chunk.map(&:size).reduce(&:+)
        say "#{index+1}) #{chunk.size} objects of total size %.2f GB / %.2f TB" % [chunk_size / 1024 ** 3, chunk_size.to_f / 1024 ** 4]
      end
      say "-" * 60
      say "Actual restore time: %i days, %i hours" % [(4 * chunks.size) / 24, (4 * chunks.size) % 24]
      say "Number of objects to restore: #{objects.size}"
      say "Total restore size: %.2f MB / %.2f GB / %.2f TB" % [objects.total_size.to_f / 1024 ** 2, objects.total_size.to_f / 1024 ** 3, objects.total_size.to_f / 1024 ** 4]
      say "Estimated cost: $#{price}"
      say "Days to keep objects on S3: #{keep_days} days"
      say "-" * 60
      say "* Please beware that these costs are not included in estimated cost:"
      say "*   - Cost for %i restore requests" % [objects.size]
      say "*   - Storage on S3 of %.2f GB during %i days" % [objects.total_size.to_f / 1024 ** 3, keep_days]
      say "-" * 60
      return unless yes?("Do you feel rich? [y/n]", :yellow)
      restore_chunks(chunks, keep_days)
    end

    private

    UNIT_FACTORS = { 'd' => 24 * 3600, 'h' => 1 * 3600 }
    CHUNK_INTERVAL = 4 * 3600

    def parse_duration(duration)
      duration.match(/^(\d+)(h|d)$/)
      raise "DURATION not in required format, [0-9]+(h|d)" unless (count = $1.to_i rescue nil) && (unit = $2)
      count * UNIT_FACTORS[unit]
    end

    def restore_chunks(chunks, keep_days)
      chunks.each_with_index do |chunk, index|
        start = Time.now
        say "Restoring #{chunk.size} objects, chunk #{index+1} of #{chunks.size}"

        chunk.each do |object|
          begin
            s3_client.restore_object(object, keep_days)
          rescue Aws::S3::Errors::RestoreAlreadyInProgress, Aws::S3::Errors::InvalidObjectState => e
            say "Error restoring #{object.bucket} / #{object.key} was ignored: #{e}"
          else
            say "Restore issued for #{object.bucket} / #{object.key}"
          end
        end

        say "Restore for all objects in chunk %i requested. Took %.1f seconds." % [index+1, Time.now - start]

        if index + 1 < chunks.size
          next_start = start + CHUNK_INTERVAL
          sleep_time = (next_start - Time.now)
          if sleep_time < 0
            say "Warning! Issuing restores took more than 4 hours, so the end time will be delayed. Proceeding immediately with next chunk."
          else
            say "Sleeping for %.1f seconds, until #{next_start}" % sleep_time
            sleep sleep_time
          end
        end
      end
    end

    def s3_client
      @s3_client ||= begin
        s3 = Aws::S3::Client.new(region: 'eu-west-1')
        s3_client = S3Client.new(s3, shell)
      end
    end
  end
end
