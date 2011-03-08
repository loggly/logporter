task :default => [:package]
package = "logporter"

task :test do
  system("cd test; ruby alltests.rb")
end

task :package => [:test, :package_real]  do
end

task :package_real do
  system("gem build #{package}.gemspec")
end

task :publish do
  latest_gem = %x{ls -t #{package}*.gem}.split("\n").first
  system("gem push #{latest_gem}")
end
