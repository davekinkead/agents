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
  elsif uri.path&.start_with?('/shorts/')
    uri.path.split('/').last
  else
    uri.query&.split('&')&.find do |p|
      p.start_with?('v=')
    end&.split('=')&.last
  end
end

def get_video_title(url)
  uri = URI.parse(url)
  return 'unknown' unless uri.host

  response = Net::HTTP.get_response(uri)
  return 'unknown' unless response.is_a?(Net::HTTPSuccess)

  # Try JSON-LD structured data first (modern YouTube)
  # Match JSON-LD "name" key, handling escaped quotes
  name_match = response.body.match(/\\?"name\\?":\s*:\s*"(.+?)"/i)
  return name_match&.[](1)&.strip if name_match

  # Fallback to old <title> tag
  title_match = response.body.match(%r{<title>(.+?)</title>})
  title_match&.[](1)&.strip if title_match
rescue StandardError
  'unknown'
end

url = ARGV[0]
abort 'Usage: yttx <youtube_url>' if url.nil? || url.empty?

video_id = extract_video_id(url)
abort 'Invalid YouTube URL' unless video_id

puts "Fetching transcript for video: #{video_id}"

begin
  transcript = YoutubeRb::Transcript.fetch(video_id, languages: ['en'])
rescue YoutubeRb::Transcript::NoTranscriptFound
  puts 'No English transcript found, trying French with translation...'
  transcript = YoutubeRb::Transcript.fetch(video_id, languages: ['en'], translation_language: 'en')
end
abort 'No transcript found for this video' if transcript.nil? || transcript.length.zero?

title = get_video_title(url)
sanitized_title = title.downcase.gsub(/[^a-z0-9]/, '-').gsub(/-+/, '-')
filepath = File.join(ENV['HOME'], 'Downloads', 'yttx', "#{sanitized_title}.srt")

FileUtils.mkdir_p(File.dirname(filepath))

formatter = YoutubeRb::Formatters::SRTFormatter.new
File.write(filepath, formatter.format_transcript(transcript))

puts "Transcript saved to: #{filepath}"
puts "Total snippets: #{transcript.length}"
