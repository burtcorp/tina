# encoding: utf-8

$: << File.expand_path('../lib', __FILE__)

require 'tina/version'

Gem::Specification.new do |s|
  s.name          = 'tina'
  s.version       = Tina::VERSION.dup
  s.authors       = ['Björn Ramberg']
  s.email         = ['bjorn@burtcorp.com']
  s.homepage      = 'http://github.com/burtcorp/tina'
  s.summary       = %q{CLI tool for restoring objects from Amazon Glacier}
  s.description   = %q{CLI tool for restoring objects from Amazon Glacier over time in order to control costs}
  s.license       = 'BSD-3-Clause'

  s.files         = Dir['bin/tina', 'lib/**/*.rb', 'README.md']
  s.test_files    = Dir['spec/**/*.rb']
  s.executables  = %w[tina]
  s.require_paths = %w(lib)

  s.add_runtime_dependency 'thor', '>= 0.19.1'
  s.add_runtime_dependency 'aws-sdk-core', '>= 2.0.0.rc15'

  s.platform = Gem::Platform::RUBY
end
