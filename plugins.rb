# frozen_string_literal: true

require "bundler-install_extension_in_lib"

if Bundler::Plugin::Events.const_defined?(:GEM_BEFORE_EVAL)
  Bundler::Plugin::API.hook(Bundler::Plugin::Events::GEM_BEFORE_EVAL) do |_gemfile, _lockfile|
    BundlerInstallExtensionInLib.reset
    BundlerInstallExtensionInLib.install_dsl
  end
end

Bundler::Plugin::API.hook(Bundler::Plugin::Events::GEM_AFTER_INSTALL) do |spec_install|
  BundlerInstallExtensionInLib.handle_after_install(spec_install)
end
