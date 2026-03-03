# frozen_string_literal: true

require "fileutils"

module BundlerInstallExtensionInLib
  VERSION = "0.1.0"

  SKIP_FILES = %w[. .. gem.build_complete mkmf.log].freeze

  @gem_names = []

  def self.add(name)
    @gem_names << name.to_s
  end

  def self.registered?(name)
    @gem_names.include?(name.to_s)
  end

  def self.handle_after_install(spec_install)
    return unless spec_install.state == :installed
    return unless registered?(spec_install.name)

    spec = spec_install.spec
    return if spec.extensions.empty?

    extension_dir = spec.extension_dir
    return unless File.directory?(extension_dir)

    lib_dir = File.join(spec.full_gem_path, spec.raw_require_paths.first)

    entries = Dir.entries(extension_dir) - SKIP_FILES
    return if entries.empty?

    FileUtils.mkdir_p(lib_dir)

    entries.each do |entry|
      src = File.join(extension_dir, entry)
      FileUtils.cp_r(src, lib_dir, remove_destination: true, verbose: true)
    end

    Bundler.ui.info "bundler-install_extension_in_lib: Copied extensions to #{lib_dir}"
  end

  module DSL
    def gem(name, *args, install_extension_in_lib: false, **kwargs)
      ::BundlerInstallExtensionInLib.add(name) if install_extension_in_lib
      super(name, *args, **kwargs)
    end
  end
  Bundler::Dsl.prepend DSL
end

