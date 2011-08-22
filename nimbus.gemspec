# encoding: utf-8

Gem::Specification.new do |s|
  s.name = 'nimbus'
  s.version = "0.6"
  s.platform = Gem::Platform::RUBY
  s.date = Time.now.strftime('%Y-%m-%d')
  
  s.summary = "Random Forest algorithm for Genomics" 
  s.description = "Nimbus is a Ruby gem to implement Random Forest in a genomic selection context."
  
  s.authors = ['Juanjo Bazán', 'Oscar González Recio']
  s.email = ["jjbazan@gmail.com"]
  s.homepage = 'http://github.com/xuanxu/nimbus'
  
  s.has_rdoc = true
  s.rdoc_options = ['--main', 'README.rdoc', '--charset=UTF-8']
  
  s.files = %w(MIT-LICENSE.txt README.rdoc) + Dir.glob("{spec,lib/**/*}") & `git ls-files -z`.split("\0")
  s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  
  s.add_development_dependency("rspec", ">=2.5.0")
end