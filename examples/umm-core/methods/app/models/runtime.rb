  def minutes
    self.seconds / 60.0
  end
  
  def minutes=(min)
    self.seconds = (min * 60).to_i
  end

