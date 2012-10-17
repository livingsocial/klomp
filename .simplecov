# -*- ruby -*-

SimpleCov.start do
  add_filter '/vendor/'

  add_group "Klomp", "lib"
  add_group "Specs", "spec"
end
