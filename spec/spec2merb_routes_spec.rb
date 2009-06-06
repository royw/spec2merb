# umm-core_spec.rb
require File.join(File.dirname(__FILE__), 'spec_helper.rb')

require 'spec2merb'
require 'fileutils'

TMPDIR = File.join(File.dirname(__FILE__), '../tmp')
FileUtils::mkdir TMPDIR unless File.exist?(TMPDIR)

# "should" are requirements
# "may" are optional

describe 'Spec2Merb' do
  
  describe "route generation" do
    # note, inflector says singular of 'charlies' is 'charly'
ROUTES_YAML = <<END_ROUTES_YAML
:routes: 
  Alpha: []
  Bravo:
  - alphas
  Charly:
  - bravos
  Delta:
  - alphas
  - bravos
  - charlies
  Echo:
  - alpha
END_ROUTES_YAML

ALPHA_ROUTE = <<END_ALPHA_ROUTE
  resources :alphas
END_ALPHA_ROUTE

BRAVO_ROUTE = <<END_BRAVO_ROUTE
  resources :bravos do
    resources :alphas
  end
END_BRAVO_ROUTE

CHARLIE_ROUTE = <<END_CHARLIE_ROUTE
  resources :charlies do
    resources :bravos do
      resources :alphas
    end
  end
END_CHARLIE_ROUTE

DELTA_ROUTE = <<END_DELTA_ROUTE
  resources :deltum do
    resources :alphas
    resources :bravos do
      resources :alphas
    end
    resources :charlies do
      resources :bravos do
        resources :alphas
      end
    end
  end
END_DELTA_ROUTE

DEPTH_LIMITED_DELTA_ROUTE = <<END_DEPTH_LIMITED_DELTA_ROUTE
  resources :deltum do
    resources :alphas
    resources :bravos
    resources :charlies
  end
END_DEPTH_LIMITED_DELTA_ROUTE

ECHO_ROUTE = <<END_ECHO_ROUTE
  resources :echos do
    resources :alphas
  end
END_ECHO_ROUTE

    ALL_ROUTES = [ALPHA_ROUTE, BRAVO_ROUTE, CHARLIE_ROUTE, DELTA_ROUTE, ECHO_ROUTE].collect{|str| str.rstrip}.join("\n")

    DEPTH_LIMIT = 5
    
    before(:all) do
      @app = Spec2Merb.new('list_test')
      @routes = YAML.load(ROUTES_YAML)[:routes]
    end
    
    it "should fix the names" do
      new_routes = @app.send('routes_fix_names', @routes)
      new_routes.each do |key, values|
        values.each do |val|
          val.should == val.snake_case.camel_case
          val.should == val.singularize
        end
      end
      new_routes['Alpha'].should == []
      new_routes['Bravo'].should == ['Alpha']
      new_routes['Charly'].should == ['Bravo']
      new_routes['Delta'].should == ['Alpha', 'Bravo', 'Charly']
      new_routes['Echo'].should == ['Alpha']
    end
    
    it "should find alpha route" do
      new_routes = @app.send('routes_fix_names', @routes)
      str = @app.find_route(1, 'Alpha', new_routes, DEPTH_LIMIT).join("\n")
      str.should == ALPHA_ROUTE.rstrip
    end
    
    it "should find bravo route" do
      new_routes = @app.send('routes_fix_names', @routes)
      str = @app.find_route(1, 'Bravo', new_routes, DEPTH_LIMIT).join("\n")
      str.should == BRAVO_ROUTE.rstrip
    end
    
    it "should find charlie route" do
      new_routes = @app.send('routes_fix_names', @routes)
      str = @app.find_route(1, 'Charly', new_routes, DEPTH_LIMIT).join("\n")
      str.should == CHARLIE_ROUTE.rstrip
    end
    
    it "should find delta route" do
      new_routes = @app.send('routes_fix_names', @routes)
      str = @app.find_route(1, 'Delta', new_routes, DEPTH_LIMIT).join("\n")
      str.should == DELTA_ROUTE.rstrip
    end
    
    it "should find echo route" do
      new_routes = @app.send('routes_fix_names', @routes)
      str = @app.find_route(1, 'Echo', new_routes, DEPTH_LIMIT).join("\n")
      str.should == ECHO_ROUTE.rstrip
    end
    
    it "should find all routes" do
      new_routes = @app.send('routes_fix_names', @routes)
      buf = []
      new_routes.keys.sort.each do |name|
        buf << @app.find_route(1, name, new_routes, DEPTH_LIMIT).join("\n").rstrip
      end
      str = buf.join("\n")
      str.should == ALL_ROUTES.rstrip
    end
    
    it "should limit depth" do
      new_routes = @app.send('routes_fix_names', @routes)
      str = @app.find_route(1, 'Delta', new_routes, 2).join("\n")
      str.should == DEPTH_LIMITED_DELTA_ROUTE.rstrip
    end
    
  end
end
