# -*- ruby -*-

SimpleCov.start do
  add_filter '/vendor/'

  add_group "Loldance", "lib"
  add_group "Specs", "spec"
end
