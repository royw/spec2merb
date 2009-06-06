describe "Run a background Scan command" do
  describe "a successful POST" do
    before(:all) do
      Command.all.destroy!
      @response = request(resource(:commands), :method => "POST", 
        :params => { :command => { :name => 'testing', :parameter => 'Movies', :command => 'Scan' }})
    end
    
    it "should finish" do
      cmd = Command.first(:name => 'testing')
      1..10.step(1) do
        break unless cmd.finished_at.nil?
        sleep 1
      end
      cmd.finished_at.should_not be_nil
    end
    
    it "redirects to resource(:commands)" do
      @response.should redirect_to(resource(Command.first), :message => {:notice => "command was successfully created"})
    end
    
  end
end
