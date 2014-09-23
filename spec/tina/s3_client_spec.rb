module Tina
  describe S3Client do
    let :s3 do
      double('s3', list_objects: object_list)
    end

    let :object_list do
      double('object list', contents: [double('object', key: 'first', size: 123)], is_truncated: false)
    end

    subject do
      described_class.new(s3)
    end

    describe '#list_bucket_prefixes' do
      it 'raises a client error when one of the input URIs does not have the correct scheme' do
        expect { subject.list_bucket_prefixes(%w(http://foo)) }.to raise_error(described_class::ClientError, /Invalid S3 URI/)
      end

      it 'retrieves s3 objects' do
        allow(object_list).to receive(:contents).and_return([double('object', key: 'foo', size: 123)])
        expect(subject.list_bucket_prefixes(['s3://bucket/prefix'])).to eq [S3Object.new('bucket', 'foo', 123)]
        expect(s3).to have_received(:list_objects).with(hash_including(bucket: 'bucket', prefix: 'prefix'))
      end

      context 'for truncated response listings' do
        let :object_list2 do
          double('object list 2', contents: [double('object', key: 'second', size: 123)], is_truncated: false)
        end

        before do
          allow(object_list).to receive(:is_truncated).and_return(true)
          allow(s3).to receive(:list_objects).and_return(object_list, object_list2)
        end

        it 'specifies the last key of the first request as the marker for the next request when truncated' do
          markers = []
          first = true
          allow(s3).to receive(:list_objects) do |options|
            markers << options[:marker]
            ret = first ? object_list : object_list2
            first = false
            ret
          end
          subject.list_bucket_prefixes(['s3://bucket/prefix'])
          expect(markers).to eq [nil, "first"]
        end

        it 'returns the complete list of objects' do
          actual_objects = subject.list_bucket_prefixes(['s3://bucket/prefix'])
          expected_objects = object_list.contents + object_list2.contents
          expect(actual_objects.map(&:key)).to eq(expected_objects.map(&:key))
        end
      end
    end
  end
end
