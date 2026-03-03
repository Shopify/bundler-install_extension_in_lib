# frozen_string_literal: true

require "rbconfig"

dlext = RbConfig::CONFIG["DLEXT"]
shared_libs = Dir.glob(File.join(__dir__, "**/*.#{dlext}"))
unless shared_libs.empty?
  raise "Compiled extension found in lib/ but should not be there: #{shared_libs.inspect}"
end

require "no_ext_in_lib_ext"
