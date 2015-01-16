require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = [].tap do |a|
    a << '--color'
    a << '--format Fuubar'
    a << '--tag ~slow'
    a << '-b'
  end.join(' ')
end

RSpec::Core::RakeTask.new(:integration) do |t|
  t.rspec_opts = [].tap do |a|
    a.push('--color')
    a.push('--format Fuubar')
  end.join(' ')
end

desc 'Run all tests'
task :test => [:spec]

task :default => [:test]
