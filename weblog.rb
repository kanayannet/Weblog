#!/usr/local/bin/ruby -Ku

#weblog program 2009.06.22
#author Making CGI (HN:kanayan)

require 'weblog_controller.rb'

init = Controller.new('')
view = init.Output

puts "content-type:text/html\n\n"
puts <<"END"
#{view}
END

exit