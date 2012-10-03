# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "klomp"
  s.version = "0.0.1.20121001122316"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Nick Sieger"]
  s.date = "2012-10-01"
  s.description = "Klomp is a simple [STOMP] messaging client that keeps your sanity intact.\n\nThe [Stomp Dance] is described as a \"drunken,\" \"crazy,\" or \"inspirited\" dance in\nthe native Creek Indian language. Not unlike what one finds when one looks for\nRuby STOMP clients.\n\nThe purpose of Klomp is to be the simplest possible Stomp client. No\nin-memory buffering of outgoing messages, no fanout subscriptions in-process, no\ntransactions, no complicated messaging patterns. No crazy dances.\n\n[Stomp]: http://stomp.github.com/\n[Stomp Dance]: http://en.wikipedia.org/wiki/Stomp_dance"
  s.email = ["nick.sieger@livingsocial.com"]
  s.extra_rdoc_files = ["Manifest.txt"]
  s.files = [".rspec", ".rvmrc", ".simplecov", "CHANGELOG.md", "Gemfile", "Gemfile.lock", "Manifest.txt", "README.md", "Rakefile", "lib/klomp.rb", "lib/klomp/connection.rb", "lib/klomp/frames.rb", "klomp.gemspec", "spec/acceptance/acceptance_spec.rb", "spec/frames/auth_error.txt", "spec/frames/connect.txt", "spec/frames/connected.txt", "spec/frames/disconnect.txt", "spec/frames/greeting.txt", "spec/frames/message.txt", "spec/frames/receipt.txt", "spec/frames/subscribe.txt", "spec/frames/unsubscribe.txt", "spec/klomp/connection_spec.rb", "spec/klomp/frames_spec.rb", "spec/klomp_spec.rb", "spec/spec_helper.rb", "spec/support/have_received.rb", ".gemtest"]
  s.homepage = "http://github.com/livingsocial/klomp"
  s.rdoc_options = ["--main", "README.md"]
  s.require_paths = ["lib"]
  s.rubyforge_project = "klomp"
  s.rubygems_version = "1.8.24"
  s.summary = "Klomp is a simple [STOMP] messaging client that keeps your sanity intact"

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
      s.add_development_dependency(%q<simplecov>, ["~> 0.6.0"])
      s.add_development_dependency(%q<hoe>, ["~> 3.0"])
    else
      s.add_dependency(%q<rdoc>, ["~> 3.10"])
      s.add_dependency(%q<hoe-bundler>, ["~> 1.1.0"])
      s.add_dependency(%q<hoe-gemspec>, ["~> 1.0.0"])
      s.add_dependency(%q<hoe-git>, ["~> 1.5.0"])
      s.add_dependency(%q<rspec>, ["~> 2.11.0"])
      s.add_dependency(%q<ZenTest>, ["~> 4.8.0"])
      s.add_dependency(%q<rspec-given>, ["~> 1.0"])
      s.add_dependency(%q<simplecov>, ["~> 0.6.0"])
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
    s.add_dependency(%q<simplecov>, ["~> 0.6.0"])
    s.add_dependency(%q<hoe>, ["~> 3.0"])
  end
end
