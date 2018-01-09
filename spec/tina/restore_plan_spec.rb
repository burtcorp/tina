require 'spec_helper'

module Tina
  describe RestorePlan do
    let :total_storage_size do
      75 * (1024 ** 4)
    end

    let :total_restore_size do
      140 * (1024 ** 3)
    end

    let :object_collection do
      SpecHelpers::ObjectCollection.new(total_restore_size)
    end

    let :options do
      {
        price_per_gb_per_hour: 0.01
      }
    end

    describe '#price' do
      context 'with perfectly aligned chunks' do
        # http://aws.amazon.com/glacier/faqs/
        context 'with the examples given on the Amazon Glacier pricing FAQ' do
          it 'matches the the price for a restore with everything at once' do
            expect(described_class.new(total_storage_size, object_collection, 4 * 3600, options).price).to be_within(0.05).of(21.6)
          end

          it 'matches the the price for a restore over 8 hours' do
            expect(described_class.new(total_storage_size, object_collection, 8 * 3600, options).price).to be_within(0.05).of(10.8)
          end

          it 'matches the the price for a restore over 28 hours' do
            expect(described_class.new(total_storage_size, object_collection, 28 * 3600, options).price).to eq 0
          end
        end

        # http://calculator.s3.amazonaws.com/index.html
        context 'with arbitrary examples taken from the Amazon calculator' do
          let :options do
            {
              price_per_gb_per_hour: 0.011
            }
          end

          let :total_storage_size do
            227 * 1024 ** 4
          end

          let :total_restore_size do
            12_000 * 1024 ** 3
          end

          it 'matches the price for a restore over a month' do
            expect(described_class.new(total_storage_size, object_collection, 30 * 24 * 3600, options).price).to be_within(0.05).of(4.16)
          end

          it 'matches the price for a restore over a week' do
            expect(described_class.new(total_storage_size, object_collection, 7 * 24 * 3600, options).price).to be_within(0.05).of(437.87)
          end

          it 'matches the price for a restore over a day' do
            expect(described_class.new(total_storage_size, object_collection, 1 * 24 * 3600, options).price).to be_within(0.05).of(3832.16)
          end

          it 'matches the price for a restore over a 4 hour period' do
            expect(described_class.new(total_storage_size, object_collection, 4 * 3600, options).price).to be_within(0.05).of(22992.93)
          end
        end

        context 'with the examples Amazon supplied in an e-mail' do
          let :total_storage_size do
            227 * 1024 ** 4
          end

          let :total_restore_size do
            12_000 * 1024 ** 3
          end

          it 'matches the price for a restore over 4 days' do
            expect(described_class.new(total_storage_size, object_collection, 4 * 24 * 3600, options).price).to be_within(20).of(768)
          end
        end
      end
    end
  end

  describe RestorePlan::ObjectCollection do
    describe '#chunk' do
      let :object_collection do
        described_class.new(objects)
      end

      let :objects do
        [
          double(:fake_object1, size: 3),
          double(:fake_object2, size: 3),
          double(:fake_object3, size: 3),
        ]
      end

      it 'chunks objects into chunks of the maximum size given' do
        expect(object_collection.chunk(6)).to eq([objects[0..1], objects[2..2]])
      end

      it 'places objects larger than the given maximum size into their own chunks' do
        objects[1] = double(:large_object, size: 42)
        expect(object_collection.chunk(6)).to eq([objects[0..0], objects[1..1], objects[2..2]])
      end
    end
  end
end

module SpecHelpers
  class ObjectCollection
    attr_reader :total_size

    def initialize(total_restore_size)
      @total_size = total_restore_size
    end

    def chunk(max_chunk_size)
      [[Tina::S3Object.new('bucket', 'key', max_chunk_size)]] * (total_size / max_chunk_size)
    end
  end
end
