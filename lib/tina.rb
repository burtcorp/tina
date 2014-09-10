module Tina
  S3Object = Struct.new(:bucket, :key, :size)
end
require 'tina/s3_client'
require 'tina/cli'
require 'tina/restore_plan'
