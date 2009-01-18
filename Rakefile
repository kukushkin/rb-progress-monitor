# Look in the tasks/setup.rb file for the various options that can be
# configured in this Rakefile. The .rake files in the tasks directory
# are where the options are used.

begin
  require 'bones'
  Bones.setup
rescue LoadError
  begin
    load 'tasks/setup.rb'
  rescue LoadError
    raise RuntimeError, '### please install the "bones" gem ###'
  end
end

ensure_in_path 'lib'
require 'progress-monitor'

task :default => 'spec:run'

PROJ.name = 'progress-monitor'
PROJ.authors = 'Alex Kukushkin'
PROJ.email = 'alex@neq4.com'
PROJ.url = 'http://neq4.com'
PROJ.version = ProgressMonitor::VERSION
PROJ.rubyforge.name = 'progress-monitor'

PROJ.spec.opts << '--color'

# EOF
