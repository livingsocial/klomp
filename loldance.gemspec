# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "loldance"
  s.version = "0.0.1.20120928194737"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Nick Sieger"]
  s.date = "2012-09-28"
  s.description = "The [Stomp Dance] is described as a \"drunken,\" \"crazy,\" or \"inspirited\" dance in\nthe native Creek Indian language. Not unlike what one finds when one looks for\nRuby STOMP clients.\n\nThe purpose of Loldance is to be the simplest possible Stomp client. No\nin-memory buffering of outgoing messages, no fanout subscriptions in-process, no\ntransactions, no complicated messaging patterns.\n\n[Stomp Dance]: http://en.wikipedia.org/wiki/Stomp_dance"
  s.email = ["nick.sieger@livingsocial.com"]
  s.extra_rdoc_files = ["Manifest.txt"]
  s.files = [".rspec", ".rvmrc", "CHANGELOG.md", "Gemfile", "Gemfile.lock", "Manifest.txt", "README.md", "Rakefile", "lib/loldance.rb", "spec/spec_helper.rb", ".gemtest"]
  s.homepage = "http://github.com/livingsocial/loldance"
  s.rdoc_options = ["--main", "README.md"]
  s.require_paths = ["lib"]
  s.rubyforge_project = "loldance"
  s.rubygems_version = "1.8.24"
  s.summary = "The [Stomp Dance] is described as a \"drunken,\" \"crazy,\" or \"inspirited\" dance in the native Creek Indian language"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rdoc>, ["~> 3.10"])
      s.add_development_dependency(%q<hoe-bundler>, ["~> 1.1.0"])
      s.add_development_dependency(%q<hoe-gemspec>, ["~> 1.0.0"])
      s.add_development_dependency(%q<hoe-git>, ["~> 1.5.0"])
      s.add_development_dependency(%q<rspec>, ["~> 2.11.0"])
      s.add_development_dependency(%q<ZenTest>, ["~> 4.8.0"])
      s.add_development_dependency(%q<rspec-given>, ["~> 1.0"])
      s.add_development_dependency(%q<hoe>, ["~> 3.0"])
    else
      s.add_dependency(%q<rdoc>, ["~> 3.10"])
      s.add_dependency(%q<hoe-bundler>, ["~> 1.1.0"])
      s.add_dependency(%q<hoe-gemspec>, ["~> 1.0.0"])
      s.add_dependency(%q<hoe-git>, ["~> 1.5.0"])
      s.add_dependency(%q<rspec>, ["~> 2.11.0"])
      s.add_dependency(%q<ZenTest>, ["~> 4.8.0"])
      s.add_dependency(%q<rspec-given>, ["~> 1.0"])
      s.add_dependency(%q<hoe>, ["~> 3.0"])
    end
  else
    s.add_dependency(%q<rdoc>, ["~> 3.10"])
    s.add_dependency(%q<hoe-bundler>, ["~> 1.1.0"])
    s.add_dependency(%q<hoe-gemspec>, ["~> 1.0.0"])
    s.add_dependency(%q<hoe-git>, ["~> 1.5.0"])
    s.add_dependency(%q<rspec>, ["~> 2.11.0"])
    s.add_dependency(%q<ZenTest>, ["~> 4.8.0"])
    s.add_dependency(%q<rspec-given>, ["~> 1.0"])
    s.add_dependency(%q<hoe>, ["~> 3.0"])
  end
end
