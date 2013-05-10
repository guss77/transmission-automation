$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
	s.name        = "transmission-remote"
	s.version     = "1.0.0"
	
	s.platform    = Gem::Platform::RUBY
	s.authors     = ["Oded Arbel"]
	s.email       = ["oded@heptagon.co.il"]
	s.homepage    = "http://heptagon.co.il"
	s.summary     = "Transmission server remote control library for automation"
	s.description = s.summary
	
	s.add_dependency "net/http"
	s.add_dependency "uri"
	s.add_dependency "json"
	
	s.files         = Dir['lib/**/*.rb'] + Dir['*.gemspec'] + Dir['samples/*']
	#s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
	s.require_paths = ["lib","samples"]
end
