Gem::Specification.new do |spec|
  files = []
  dirs = %w{lib samples test bin}
  dirs.each do |dir|
    files += Dir["#{dir}/**/*"]
  end

  spec.name = "logporter"
  spec.version = "0.1.2"
  spec.summary = "logporter - a log server"
  spec.description = "syslog servlet for ruby"
  spec.add_dependency("eventmachine")

  spec.files = files
  spec.require_paths << "lib"

  spec.author = "Jordan Sissel"
  spec.email = "jordan@loggly.com"
  spec.homepage = "https://github.com/loggly/logporter"
end

