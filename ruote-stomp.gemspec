# encoding: utf-8

Gem::Specification.new do |s|

  s.name = 'ruote-stomp'
  s.version = File.read('lib/ruote-stomp/version.rb').match(/VERSION = '([^']+)'/)[1]
  s.platform = Gem::Platform::RUBY
  s.authors = [ 'Kit Plummer', 'Brian Sam-Bodden' ]
  s.email = [ 'kplummer@maestrodev.com', 'bsbodden@integrallis.com' ]
  s.homepage = 'http://ruote.rubyforge.org'
  s.rubyforge_project = 'ruote'
  s.summary = 'Stomp participant/listener pair for ruote 2.2'
  s.description = 'Stomp participant/listener pair for ruote 2.2'

  s.files = Dir[
    'Rakefile',
    'lib/**/*.rb', 'spec/**/*.rb', 'test/**/*.rb',
    '*.gemspec', '*.txt', '*.rdoc', '*.md'
  ]

  s.add_runtime_dependency 'onstomp', "~> 1.0.4"
  s.add_runtime_dependency 'ruote', "~> 2.2.0"
  s.add_runtime_dependency 'json'
  s.add_runtime_dependency 'parslet'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec', ">= 2.6.0"
  s.add_development_dependency 'stompserver', '~> 0.9.9'

  s.require_path = 'lib'
end

