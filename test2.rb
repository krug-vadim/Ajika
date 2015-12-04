#!/usr/bin/ruby

require_relative 'lib/Ajika'

category 'blog' do
	if_from 'from@me.com'
	if_to   'you@name.com'
	if_subj ''
	if_key  'key'

	# db_to 'path'
	# render_to 'path'
end

# reply '' do
# 	subj /^(RE|re)(\[\S+\])?\:(.+)$/

# 	db_to path
# 	render_to path
# end

puts self.class