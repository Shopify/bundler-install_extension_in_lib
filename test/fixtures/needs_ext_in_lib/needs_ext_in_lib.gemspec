# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name = "needs_ext_in_lib"
  s.version = "0.1.0"
  s.summary = "Test gem that expects compiled extension in lib/"
  s.authors = ["Test"]
  s.extensions = ["ext/needs_ext_in_lib/extconf.rb"]
  s.files = [
    "lib/needs_ext_in_lib.rb",
    "ext/needs_ext_in_lib/extconf.rb",
    "ext/needs_ext_in_lib/needs_ext_in_lib_ext.c",
  ]
  s.require_paths = ["lib"]
end
