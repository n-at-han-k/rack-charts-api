Gem::Specification.new do |s|
  s.name        = 'rack-charts-api'
  s.version     = '0.1.0'
  s.authors     = ['Nathan']
  s.summary     = 'Rack middleware that serves PNG and HTML charts from query params or JSON body'
  s.description = 'A mountable Rack app that accepts chartkick-compatible data via URL params ' \
                  'or JSON request body and returns either a server-rendered PNG (via Gruff) ' \
                  'or an HTML page with a Chart.js chart suitable for iframe embedding.'
  s.license     = 'MIT'

  s.required_ruby_version = '>= 3.0'

  s.files = Dir['lib/**/*']

  s.add_dependency 'gruff', '>= 0.23'
  s.add_dependency 'rack', '>= 2.0'

  s.add_development_dependency 'minitest', '~> 5.0'
  s.add_development_dependency 'rack-test', '~> 2.0'
  s.add_development_dependency 'rake'
end
