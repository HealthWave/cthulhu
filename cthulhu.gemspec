Gem::Specification.new do |s|
  s.name        = 'cthulhu'
  s.version     = '0.2.1'
  s.date        = '2016-05-20'
  s.summary     = "No life matter"
  s.description = "No description. Get over it."
  s.authors     = ["Paulo Arruda", "Anthony Jhones"]
  s.email       = 'paulo@fullscript.com'
  s.files       = Dir.glob("{bin,lib,template,template/logs,template/tmp}/**/*")
  s.homepage    = 'http://rubygems.org/gems/cthulhu'
  s.license       = 'MIT'
  s.executables << 'cthulhu'
  s.add_dependency "bunny", [">= 2.3.1"]
  s.add_development_dependency "rspec"
end
