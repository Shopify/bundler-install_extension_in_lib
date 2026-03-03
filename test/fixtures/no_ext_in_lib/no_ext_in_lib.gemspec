# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name = "no_ext_in_lib"
  s.version = "0.1.0"
  s.summary = "Test gem that expects NO compiled extension in lib/"
  s.authors = ["Test"]
  s.extensions = ["ext/no_ext_in_lib/extconf.rb"]
  s.files = [
    "lib/no_ext_in_lib.rb",
    "ext/no_ext_in_lib/extconf.rb",
    "ext/no_ext_in_lib/no_ext_in_lib_ext.c",
  ]
  s.require_paths = ["lib"]
end
