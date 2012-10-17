require 'bundler/setup'
require 'hoe'

Hoe.plugin :bundler, :git, :gemspec, :gemcutter

Hoe.spec 'klomp' do
  developer 'Nick Sieger', 'nick.sieger@livingsocial.com'

  ### Use markdown for changelog and readme
  self.history_file = 'CHANGELOG.md'
  self.readme_file  = 'README.md'

  self.clean_globs << 'spec/reports'

  ### dependencies!
  self.extra_dev_deps << [ 'hoe-bundler',  '~> 1.1.0'  ]
  self.extra_dev_deps << [ 'hoe-gemspec',  '~> 1.0.0'  ]
  self.extra_dev_deps << [ 'hoe-git',      '~> 1.5.0'  ]
  self.extra_dev_deps << [ 'rspec',        '~> 2.11.0' ]
  self.extra_dev_deps << [ 'ZenTest',      '~> 4.8.0'  ]
  self.extra_dev_deps << [ 'rspec-given',  '~> 1.0'    ]
  self.extra_dev_deps << [ 'simplecov',    '~> 0.6.0'  ]
  self.extra_dev_deps << [ 'em-proxy',     '~> 0.1.0'  ]
  self.extra_dev_deps << [ 'ci_reporter',  '~> 1.7.0'  ]
end

require 'ci/reporter/rake/rspec'
