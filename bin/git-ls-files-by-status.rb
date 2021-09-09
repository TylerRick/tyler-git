#!/usr/bin/env ruby
# Note: obsoleted by my git-ls-files-by-status (sh) and git ls-untracked alias?

# Examples:
# If you want to ignore all the files that are presently untracked, you could do this:
# git-ls-files-by-status --untracked | xargs git-ignore-for-me

require 'rubygems'
require 'facets/kernel/blank'
$:.unshift "/home/tyler/installed/ruby-git/lib"
require 'git'      # requires my local changes

@repo_root = `git base-dir`.chomp
@cdup = `git rev-parse --show-cdup`.chomp
def relative_to_wd(path)
  @cdup.blank? ? path : File.join(@cdup, path)
end
@git = Git.open(@repo_root)

#puts @git.status.untracked.map{|filename, o| filename}[0..10]

if ARGV.grep('-h').any? || ARGV.grep('--help').any?
  puts "Usage: git ls-files-by-status [-1|--one-line] (--new|--modified|--deleted|--untracked)* | (-N|-M|-D|-U)*"
  exit
end

if ARGV.grep('-1').any? || ARGV.grep('--one-line').any?
  @one_line = true
end

files = []
if ARGV.grep('-N').any? || ARGV.grep('--new').any?
  files.concat @git.status.new
end
if ARGV.grep('-M').any? || ARGV.grep('--modified').any?
  files.concat @git.status.modified
end
if ARGV.grep('-D').any? || ARGV.grep('--deleted').any?
  files.concat @git.status.deleted
end
if ARGV.grep('-U').any? || ARGV.grep('--untracked').any?
  files.concat @git.status.untracked
end
# ??
if ARGV.grep('-UM').any? || ARGV.grep('--unmerged').any?
  files.concat @git.status.unmerged
end

files.map! do |path|
  relative_to_wd(path)
end

if @one_line
  puts files.join(' ')
else
  puts files.join("\n")
end
