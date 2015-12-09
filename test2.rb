#!/usr/bin/ruby

require 'haml'
require 'fileutils'
require 'redcarpet'

require_relative 'lib/Ajika'

category 'blog' do
	#if_from    ['from@you.to']
	#if_to      ['post@post.io']
	if_subject  //, '', nil
	#if_key     'key'
	if_signed? true

	action 'db' do |mail, text, attachments|
		path_suffix = mail[:date].strftime("%Y-%m/%d%H%M%S")
		db_path = "#{__dir__}/#{path_suffix}"
		attachments_path = "#{__dir__}/#{path_suffix}"

		puts db_path
		puts attachments_path
		#puts attachments.inspect

		begin
			FileUtils.mkpath(db_path)
			FileUtils.mkpath(attachments_path)

			File.open("#{db_path}/post", "w+b", 0644) {|f| f.write text}

			attachments.each do |name, data|
				filename = "#{attachments_path}/#{name}"
				File.open("#{filename}", "w+b", 0644) {|f| f.write data}
			end
		rescue => e
			puts "Unable to save data for #{attachments_path} because #{e.message}"
		end
	end

	action 'page' do |mail, text, attachments|
		path_suffix = mail[:date].strftime("%Y-%m/%d%H%M%S")
		render_path = "#{__dir__}/www/#{path_suffix}"
		attachments_path = render_path
		puts render_path

		html = Haml::Engine.new(File.read('template.haml')).render do
			Redcarpet::Markdown.new(Redcarpet::Render::HTML.new).render(text)
		end

		begin
			FileUtils.mkpath(render_path)
			File.open("#{render_path}/index.html", "w+b", 0644) {|f| f.write html}

			attachments.each do |name, data|
				filename = "#{attachments_path}/#{name}"
				File.open("#{filename}", "w+b", 0644) {|f| f.write data}
			end
		rescue => e
			puts "Unable to save data for #{attachments_path} because #{e.message}"
		end
	end
end

category 'blog_reply' do
	if_subject /^(RE|re)(\[\S+\])?\:(.+)$/
end
