#!/usr/bin/env ruby

dir = ARGV.first
ver = ARGV.last

Dir.chdir(dir) do
  lines = File.read('version').lines if File.file? 'version'
  prev = lines.first.chomp
  versions = prev.split('.').map(&:to_i)
  versions << versions.pop.succ
  upver = versions.join('.')
  puts lines
  puts "New version: #{upver}" 
  ver = $stdin.gets.chomp
  ver = upver if ver.empty?

  File.open('version', 'w') do |f|
    f.puts ver
    f.puts Time.new
  end
end