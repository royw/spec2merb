class RequestSpecEditor < FileEditor
  SPEC_DIRECTIONS = [
    '',
    '# Directions to finish the request spec:',
    '# 1) To authenticate, add a call to login() before request',
    '# 2) Replace the { :id => nil } blocks with appropriate parameters for the model',
    '# 3) Replace the "pending" calls with appropriate checks',
    '# Note, a 401 return code is an authentication failure.',
    ''
    ]
  def add_directions
    insert('require', SPEC_DIRECTIONS)
  end
end

