#!/usr/bin/env ruby
require 'youtube-transcript-rb'
require 'uri'
require 'net/http'
require 'fileutils'

def extract_video_id(url)
  uri = URI.parse(url)
  return nil unless uri.host&.include?('youtube.com') || uri.host&.include?('youtu.be')

  if uri.host.include?('youtu.be')
    uri.path[1..-1]
  else
    uri.query.split('&').find do |p|
      p.start_with?('v=')
    end&.split('=')&.last
  end
end

def get_video_title(url)
  uri = URI.parse(url)
  return 'unknown' unless uri.host

  response = Net::HTTP.get_response(uri)
  return 'unknown' unless response.is_a?(Net::HTTPSuccess)

  response.body[%r{<title>(.+?)</title>}, 1]&.strip&.gsub(/ - YouTube$/, '')&.gsub(/[^\w\s-]/,
                                                                                   '')&.squeeze(' ') || 'unknown'
rescue StandardError
  'unknown'
end

url = ARGV[0]
abort 'Usage: yttx <youtube_url>' if url.nil? || url.empty?

video_id = extract_video_id(url)
abort 'Invalid YouTube URL' unless video_id

puts "Fetching transcript for video: #{video_id}"

transcript = YoutubeRb::Transcript.fetch(video_id, languages: ['en'])
abort 'No transcript found for this video' if transcript.nil? || transcript.length.zero?

title = get_video_title(url)
sanitized_title = title.downcase.gsub(/\s+/, '_')
filepath = File.join(ENV['HOME'], 'Downloads', 'yttx', "#{sanitized_title}.srt")

FileUtils.mkdir_p(File.dirname(filepath))

formatter = YoutubeRb::Formatters::SRTFormatter.new
File.write(filepath, formatter.format_transcript(transcript))

puts "Transcript saved to: #{filepath}"
puts "Total snippets: #{transcript.length}"
