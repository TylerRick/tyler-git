# http://github.com/cldwalker/hirb/blob/master/lib/hirb/util.rb#L61-71
# Returns [width, height] of terminal when detected, nil if not detected.
# Think of this as a simpler version of Highline's Highline::SystemExtensions.terminal_size()
def detect_terminal_size
  if (ENV['COLUMNS'] =~ /^\d+$/) && (ENV['LINES'] =~ /^\d+$/)
    [ENV['COLUMNS'].to_i, ENV['LINES'].to_i]
  elsif (RUBY_PLATFORM =~ /java/ || (!STDIN.tty? && ENV['TERM'])) && command_exists?('tput')
    [`tput cols`.to_i, `tput lines`.to_i]
  elsif STDIN.tty? && command_exists?('stty')
    `stty size`.scan(/\d+/).map { |s| s.to_i }.reverse
  else
    nil
  end
rescue
  nil
end
#puts "detect_terminal_size=#{detect_terminal_size.inspect}"

begin
  gem 'ruby-terminfo'
  require 'terminfo' #http://www.a-k-r.org/ruby-terminfo/
  $screen_width=TermInfo.screen_width
rescue LoadError
  STDERR.puts "Warning: Could not load terminfo"
  $screen_width=130
end
#puts "$screen_width=#{$screen_width.inspect}"

