# bundler-install_extension_in_lib

A Bundler plugin that copies compiled native extensions (`.so`/`.bundle`/`.dll`) into a gem's `lib/` directory after installation. This is useful for old or unmaintained gems that expect their compiled extensions to live in `lib/` rather than in Bundler's extension directory.

## Installation

```
gem install bundler-install_extension_in_lib
```

## Usage

Add the following to your `Gemfile`:

```ruby
plugin "bundler-install_extension_in_lib"
source "https://rubygems.org"

gem "sassc", install_extension_in_lib: true
```

The `install_extension_in_lib: true` option on a `gem` declaration tells the plugin to copy that gem's compiled extensions into its `lib/` directory after installation.

You must run `bundle install` before any other Bundler command (`bundle exec`, `bundle check`, etc.) so Bundler can install and register the plugin. Once installed, the plugin uses Bundler's `before-eval` hook to load before the Gemfile's `gem` declarations are evaluated.

## How it works

The plugin hooks into `Bundler::Plugin::Events::GEM_BEFORE_EVAL` to install the small Gemfile DSL extension that accepts `install_extension_in_lib:`. It also hooks into `Bundler::Plugin::Events::GEM_AFTER_INSTALL`; when a gem marked with `install_extension_in_lib: true` is freshly installed, the plugin copies all compiled extension files from the gem's extension directory into its `lib/` directory.

Files that are skipped: `gem.build_complete`, `mkmf.log`.

## License

MIT
