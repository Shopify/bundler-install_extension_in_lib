# frozen_string_literal: true

require "fileutils"

module BundlerInstallExtensionInLib
  VERSION = "0.1.0"

  SKIP_FILES = %w[gem.build_complete mkmf.log gem_make.out].freeze

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

    ext_files = Dir.glob(File.join(extension_dir, "**", "*"))
      .select { |f| File.file?(f) }
      .reject { |f| SKIP_FILES.include?(File.basename(f)) }
    return if ext_files.empty?

    copied = ext_files.count do |ext_file|
      relative = ext_file.delete_prefix("#{extension_dir}/")
      dest = File.join(lib_dir, relative)
      next false if File.exist?(dest)

      FileUtils.mkdir_p(File.dirname(dest))
      FileUtils.cp(ext_file, dest, verbose: true)
      true
    end

    Bundler.ui.info "bundler-install_extension_in_lib: Copied #{copied} extension(s) to #{lib_dir}" if copied > 0
  end

  module DSL
    def gem(name, *args, install_extension_in_lib: false, **kwargs)
      ::BundlerInstallExtensionInLib.add(name) if install_extension_in_lib
      super(name, *args, **kwargs)
    end
  end
  Bundler::Dsl.prepend DSL
end

