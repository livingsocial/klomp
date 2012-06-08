$:.push File.expand_path(File.join(File.dirname(__FILE__), "lib"))
require 'klomp'

Gem::Specification.new do |gem|
  gem.authors       = ["LivingSocial"]
  gem.email         = ["dev.happiness@livingsocial.com"]
  gem.description   = "A simple wrapper around the OnStomp library with additional features"
  gem.summary       = "A simple wrapper around the OnStomp library with additional features"
  gem.homepage      = "https://github.com/livingsocial/klomp"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "klomp"
  gem.require_paths = ["lib"]
  gem.version       = Klomp::VERSION

  gem.add_dependency("onstomp")
  gem.add_dependency("json")
end
