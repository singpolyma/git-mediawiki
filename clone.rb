#!/usr/bin/ruby

require 'json'
require 'open-uri'
require 'cgi'
require 'time'

def an(v)
	v || Class.new{def method_missing(*a);end;}.new
end

def get2commit(wiki,pageid,branch,authors={},rvstartid=nil,limit='max')
	uri = "#{wiki}/w/api.php?action=query&prop=revisions&pageids=#{pageid.to_i}&rvprop=ids%7Cflags%7Ctimestamp%7Cuser%7Ccomment%7Ccontent&format=json&rvlimit=#{limit}&rvdir=newer"
	uri += "&rvstartid=#{rvstartid.to_i}" if rvstartid
	revisions = JSON::parse(open(uri).read)
	an(an(revisions['query'])['pages']).each do |id,page|
		page['revisions'].each do |rev|
			time = Time.parse(rev['timestamp']).utc.to_i
			user = authors[rev['user']] || "#{rev['user']} <>"
			puts "commit #{branch}"
			puts "mark :#{rev['revid']}"
			puts "committer #{user} #{time} +0000"
			puts "data #{rev['comment'] ? rev['comment'].length : 0}"
			puts rev['comment'] if rev['comment'] and rev['comment'].length > 0
			puts "from :#{rev['parentid']}" if rev['parentid']
			puts "M 100644 inline #{page['title']}"
			puts "data #{rev['*'] ? rev['*'].length : 0}"
			puts rev['*'] if rev['*'] and rev['*'].length > 0
		end
	end
	an(an(revisions['query-continue'])['revisions'])['rvstartid']
end

def all2commit(wiki,pageid,branch,authors={},rvstartid=nil)
	while rvstartid = get2commit(wiki,pageid,branch,authors,rvstartid)
		# Nothing
	end
end

def somepages(wiki,apfrom=nil)
	uri = "#{wiki}/w/api.php?action=query&list=allpages&aplimit=max&format=json"
	uri += "&apfrom=#{CGI::escape(apfrom)}" if apfrom
	pages = JSON::parse(open(uri).read)
	(an(an(pages['query'])['allpages']).map{|v| v['pageid']} || []).each{|v| all2commit(wiki, v,'refs/heads/master')}
	an(an(pages['query-continue'])['allpages'])['apfrom']
end

def allpages(wiki)
	apfrom = nil
	while apfrom = somepages(wiki,apfrom)
		# Nothing
	end
end

allpages(ARGV[0])
