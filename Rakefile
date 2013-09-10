require 'bundler/setup'
require 'hoe'

Hoe.plugin :bundler, :git, :gemspec, :gemcutter, :travis

Hoe.spec 'klomp' do
  developer 'Nick Sieger', 'nick.sieger@livingsocial.com'

  ### Use markdown for changelog and readme
  self.history_file = 'CHANGELOG.md'
  self.readme_file  = 'README.md'

  self.clean_globs << 'spec/reports'

  license 'MIT'

  ### dependencies!
  self.extra_dev_deps << [ 'hoe-bundler',   '~> 1.2.0'  ]
  self.extra_dev_deps << [ 'hoe-gemspec',   '~> 1.0.0'  ]
  self.extra_dev_deps << [ 'hoe-git',       '~> 1.5.0'  ]
  self.extra_dev_deps << [ 'hoe-travis',    '= 1.2'     ]
  self.extra_dev_deps << [ 'rspec',         '~> 2.11.0' ]
  self.extra_dev_deps << [ 'autotest-standalone', '~> 4.5.0'  ]
  self.extra_dev_deps << [ 'rspec-given',   '~> 1.5.0'  ]
  self.extra_dev_deps << [ 'simplecov',     '~> 0.6.0'  ]
  self.extra_dev_deps << [ 'em-proxy',      '~> 0.1.0'  ]
  self.extra_dev_deps << [ 'ci_reporter',   '~> 1.7.0'  ]
end

module Hoe::Bundler
  alias_method :orig_hoe_bundler_contents, :hoe_bundler_contents

  GEMFILE_APPENDIX = %{
    gem 'activesupport', ['>= 2.3.0', '< 4.0.0'], :group => [:development, :test], :platforms => :ruby_18
  }

  def hoe_bundler_contents
    contents = orig_hoe_bundler_contents
    contents.sub(/^(# vim: syntax=ruby)/, "#{GEMFILE_APPENDIX.strip}\n\\1")
  end
end

require 'ci/reporter/rake/rspec'

task :travis => :spec
