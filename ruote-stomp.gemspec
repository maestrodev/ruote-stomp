# encoding: utf-8

Gem::Specification.new do |s|

  s.name = 'ruote-stomp'
  s.version = File.read('lib/ruote-stomp/version.rb').match(/VERSION = '([^']+)'/)[1]
  s.platform = Gem::Platform::RUBY
  s.authors = [ 'Kit Plummer' ]
  s.email = [ 'kplummer@maestrodev.com' ]
  s.homepage = 'http://ruote.rubyforge.org'
  s.rubyforge_project = 'ruote'
  s.summary = 'Stomp participant/listener pair for ruote 2.2'
  s.description = %{
Stomp participant/listener pair for ruote 2.2 - ported from ruote-amqp.
  }

  #s.files = `git ls-files`.split("\n")
  s.files = Dir[
    'Rakefile',
    'lib/**/*.rb', 'spec/**/*.rb', 'test/**/*.rb',
    '*.gemspec', '*.txt', '*.rdoc', '*.md'
  ]

  #s.add_runtime_dependency 'stmop'
  s.add_runtime_dependency 'stomp', '~>1.1.8'
  s.add_runtime_dependency 'ruote', ">= #{s.version}"

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec', ">= 2.6.3"
  s.add_development_dependency 'stompserver', '~> 0.9.9'

  s.require_path = 'lib'
end

