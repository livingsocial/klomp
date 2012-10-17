# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "klomp"
  s.version = "1.0.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Nick Sieger"]
  s.date = "2012-10-17"
  s.description = "Klomp is a simple [Stomp] messaging client that keeps your sanity intact.\n\nThe purpose of Klomp is to be the simplest possible Stomp client. No in-memory\nbuffering of outgoing messages, no fanout subscriptions in-process, no\ntransactions, no complicated messaging patterns. Code simple enough so that when\nsomething goes wrong, the problem is obvious.\n\n[Stomp]: http://stomp.github.com/"
  s.email = ["nick.sieger@livingsocial.com"]
  s.extra_rdoc_files = ["Manifest.txt"]
  s.files = [".rspec", ".simplecov", "ChangeLog.md", "Gemfile", "Gemfile.lock", "Manifest.txt", "README.md", "Rakefile", "klomp.gemspec", "lib/klomp.rb", "lib/klomp/connection.rb", "lib/klomp/frames.rb", "lib/klomp/sentinel.rb", "spec/acceptance/acceptance_spec.rb", "spec/frames/auth_error.txt", "spec/frames/connect.txt", "spec/frames/connect_vhost.txt", "spec/frames/connected.txt", "spec/frames/disconnect.txt", "spec/frames/error.txt", "spec/frames/greeting.txt", "spec/frames/message.txt", "spec/frames/receipt.txt", "spec/frames/subscribe.txt", "spec/frames/unsubscribe.txt", "spec/klomp/connection_spec.rb", "spec/klomp/frames_spec.rb", "spec/klomp/sentinel_spec.rb", "spec/klomp_spec.rb", "spec/spec_helper.rb", "spec/support/have_received.rb", ".gemtest"]
  s.homepage = "http://github.com/livingsocial/klomp"
  s.rdoc_options = ["--main", "README.md"]
  s.require_paths = ["lib"]
  s.rubyforge_project = "klomp"
  s.rubygems_version = "1.8.24"
  s.summary = "Klomp is a simple [Stomp] messaging client that keeps your sanity intact"

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
      s.add_development_dependency(%q<em-proxy>, ["~> 0.1.0"])
      s.add_development_dependency(%q<ci_reporter>, ["~> 1.7.0"])
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
      s.add_dependency(%q<em-proxy>, ["~> 0.1.0"])
      s.add_dependency(%q<ci_reporter>, ["~> 1.7.0"])
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
    s.add_dependency(%q<em-proxy>, ["~> 0.1.0"])
    s.add_dependency(%q<ci_reporter>, ["~> 1.7.0"])
    s.add_dependency(%q<hoe>, ["~> 3.0"])
  end
end
