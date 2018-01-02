/* SIMPLEDO.CMD */
parse arg name .
if name = '' then do
     say 'Please enter your name'
     parse pull name .
end
say 'Hello' name
