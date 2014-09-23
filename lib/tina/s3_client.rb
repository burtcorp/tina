require 'uri'

module Tina
  class S3Client
    ClientError = Class.new(StandardError)

    def initialize(s3)
      @s3 = s3
    end

    def list_bucket_prefixes(prefix_uris)
      bucket_prefixes = prefix_uris.map do |prefix_uri|
        uri = URI.parse(prefix_uri)
        raise ClientError, "Invalid S3 URI: #{uri}" unless uri.scheme == 's3'
        [uri.host, uri.path.sub(%r[^/], '')]
      end
      bucket_prefixes.flat_map do |(bucket,prefix)|
        puts "Listing prefix #{bucket}/#{prefix}..."
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
