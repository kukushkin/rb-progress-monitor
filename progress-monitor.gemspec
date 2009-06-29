# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{progress-monitor}
  s.version = "1.0.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Alex Kukushkin"]
  s.date = %q{2009-06-29}
  s.description = %q{A tool to measure progress and estimate completion time of the long tasks.}
  s.email = %q{alex@neq4.com}
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "README.txt"]
  s.files = [".DS_Store", ".gitignore", "History.txt", "Manifest.txt", "README.txt", "Rakefile", "lib/progress-monitor.rb", "progress-monitor.gemspec", "spec/progress-monitor_spec.rb", "spec/spec_helper.rb", "test/test_progress-monitor.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://neq4.com}
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{progress-monitor}
  s.rubygems_version = %q{1.3.2}
  s.summary = %q{A tool to measure progress and estimate completion time of the long tasks}
  s.test_files = ["test/test_progress-monitor.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<bones>, [">= 2.5.0"])
    else
      s.add_dependency(%q<bones>, [">= 2.5.0"])
    end
  else
    s.add_dependency(%q<bones>, [">= 2.5.0"])
  end
end
