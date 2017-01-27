lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cthulhu/version'
Gem::Specification.new do |s|
  s.name        = 'cthulhu'
  s.version     = ::Cthulhu.version
  s.date        = '2016-12-08'
  s.summary     = "No life matter"
  s.description = "No description. Get over it."
  s.authors     = ["Paulo Arruda", "Patrick Vice", "Anthony Jhones"]
  s.email       = 'devops@fullscript.com'
  s.files       = Dir.glob("{bin,lib,template,template/log,template/tmp}/**/*")
  s.homepage    = 'http://rubygems.org/gems/cthulhu'
  s.license       = 'MIT'
  s.executables << 'cthulhu'
  s.add_dependency "bunny", [">= 2.3.1"]
  s.add_development_dependency "rspec"
end
