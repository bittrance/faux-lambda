require File.expand_path('../lib/faux_lambda', __FILE__)

Gem::Specification.new do |spec|
  spec.name        = 'faux-lambda'
  spec.version     = FauxLambda::VERSION
  spec.summary     = 'faux-lambda provides a simple tool to mock AWS Lambda endpoint'
  spec.description = 'faux-lambda is a toolbox to make it easier to develop client that call AWS Lambda functions. A simple CLI lets you mock AWS Lambda and specify replies for specific function as well as simulate AWS Lambda framework failures.'
  spec.authors     = ['Anders Qvist']
  spec.email       = 'quest@lysator.liu.se'
  spec.homepage    = 'https://github.com/bittrance/faux-lambda'
  spec.license     = 'MIT'

  spec.executables = ['faux-lambda']
  spec.files       = `git ls-files -z`.split("\x0").reject { |f| f.match(/^spec/) }

  spec.required_ruby_version = '>= 2.0.0'

  spec.add_runtime_dependency 'rack', '~> 2.0'
end
