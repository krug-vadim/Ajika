#!/usr/bin/ruby

require 'haml'
require 'fileutils'
require 'redcarpet'

require_relative 'lib/Ajika'

category 'blog' do
	if_from    ['from@you.to']
	if_to      ['post@post.io']
	if_subject //
	#if_key     'key'

	action 'db' do |mail, text|
		path_suffix = mail[:date].strftime("%Y-%m/%d%H%M%S")
		db_path = "#{__dir__}/#{path_suffix}"
		attachments_path = "#{__dir__}/#{path_suffix}"

		puts db_path
		puts attachments_path

		begin
			FileUtils.mkpath(db_path)
			FileUtils.mkpath(attachments_path)
			File.open("#{db_path}/post", "w+b", 0644) {|f| f.write text}
		rescue => e
			puts "Unable to save data for #{attachments_path} because #{e.message}"
		end
	end

	action 'page' do |mail, text|
		path_suffix = mail[:date].strftime("%Y-%m/%d%H%M%S")
		render_path = "#{__dir__}/#{path_suffix}"

		puts render_path

		text = Haml::Engine.new(File.read('template.haml', :encoding => 'UTF-8')).render do
			Redcarpet::Markdown.new(Redcarpet::Render::HTML.new).render(text)
		end

		puts text
	end
end

category 'blog_reply' do
	if_subject /^(RE|re)(\[\S+\])?\:(.+)$/
end
