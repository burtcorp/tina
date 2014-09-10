module Tina
  class S3Client
    def initialize(s3)
      @s3 = s3
    end

    def list_bucket_prefixes(prefixes)
      prefixes.flat_map do |bucket_prefix|
        bucket, prefix = bucket_prefix.split('/', 2)
        puts "Listing prefix #{bucket_prefix}..."
        objects = []
        marker = nil
        loop do
          listing = @s3.list_objects(bucket: bucket, prefix: prefix, marker: marker)
          listing.contents.each do |object|
            objects << S3Object.new(bucket, object.key, object.size)
            marker = object.key
          end
          break unless listing.is_truncated
        end
        objects
      end
    end

    def restore_object(object, keep_days)
      @s3.restore_object(bucket: object.bucket, key: object.key, restore_request: { days: keep_days })
    end
  end
end
