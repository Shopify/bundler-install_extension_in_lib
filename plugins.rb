# frozen_string_literal: true

require "bundler-install_extension_in_lib"

Bundler::Plugin::API.hook(Bundler::Plugin::Events::GEM_AFTER_INSTALL) do |spec_install|
  BundlerInstallExtensionInLib.handle_after_install(spec_install)
end
