# frozen_string_literal: true

require_relative "lib/fat_fin/version"

Gem::Specification.new do |spec|
  spec.name = "fat_fin"
  spec.version = FatFin::VERSION
  spec.authors = ["Daniel E. Doherty"]
  spec.email = ["ded@ddoherty.net"]

  spec.summary = "Library for some financial calculations."
  spec.description = "Some financial classes and methods, including aperiodic IRR from arbitrary cash flows."
  spec.homepage = "https://github.com/ddoherty03/fat_fin/wiki"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = "https://github.com/ddoherty03/fat_fin/wiki"
  spec.metadata["source_code_uri"] = "https://github.con/ddoherty03/fat_fin"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "fat_core"
  spec.add_dependency "fat_period"

  spec.add_development_dependency "debug"
  spec.add_development_dependency "rspec"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
