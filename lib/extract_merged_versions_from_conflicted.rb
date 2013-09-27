
# Old version:
#def remove_section(s, section)
#  puts "removing #{section.inspect}"
#  if section == :top
#    s[/<<<<<<<.*=======/m] = ''
#    s[/>>>>>>>.*$/] = ''
#  else
#    s[/<<<<<<<.*$/] = ''
#    s[/=======.*>>>>>>>[^\n]*$/m] = ''
#  end
#  s
#end

class SourceFileWithMergeConflicts
  def initialize(conflicted)
    @conflicted = conflicted
  end

  # Returns the specified (mostly-merged) version, extracted from the SourceFileWithMergeConflicts
  def [](section)
    raise ArgumentError, "section must be one of :top or :bottom" unless [:top, :bottom].include?(section)
    output = ''
    state = :normal

    # TODO: Use different markers depending on output of git config merge.conflictstyle
    # Never mind, might not be necessary. Just had to add the case for :begin_original so it could
    # handle diff3 style. Should also handle the other style that omits the middle section.

    require 'byebug'
    @conflicted.lines.each do |line|
      if line =~ /^<<<<<<< \S+/
        state = :begin_top
      elsif line =~ /^\|\|\|\|\|\|\| \S+/
        state = :begin_original
      # Note: Can't just match lines *starting* with this string or it may mistakenly match heading
      # markers in a markdown file, for example.  Note that it is still *possible* that a file may
      # have a line that looks exactly the same as the conflict marker that git adds.  I don't
      # suppose there's anything we can do about that though.
      elsif line =~ /^=======$/ # Unlike the other markers, the ======= marker apparently *never* has a space or extra text after it.
        state = :begin_bottom
      elsif line =~ /^>>>>>>> \S+/
        state = :end_bottom
      else
        case state
        when :begin_top
          state = :in_top
        when :begin_original
          state = :in_original
        when :begin_bottom
          state = :in_bottom
        when :end_bottom
          state = :normal
        end
      end

      case state
      when :normal
        output << line
      when :in_top
        if section == :top
          output << line
        end
      when :in_bottom
        if section == :bottom
          output << line
        end
      end
    end

    output
  end
end


#  _____         _
# |_   _|__  ___| |_
#   | |/ _ \/ __| __|
#   | |  __/\__ \ |_
#   |_|\___||___/\__|
#
=begin test
require 'spec/autorun'

describe SourceFileWithMergeConflicts do
  def do_test
    SourceFileWithMergeConflicts.new(@conflicted)[:top].should    == @top_version
    SourceFileWithMergeConflicts.new(@conflicted)[:bottom].should == @bottom_version
  end

  it 'simple, 1 conflict' do
    @conflicted =
%(<<<<<<< HEAD
t1
=======
b1
>>>>>>> b1
)

    @top_version =
%(t1
)

    @bottom_version =
%(b1
)
    do_test
  end

  it 'simple, 2 conflicts' do
    @conflicted =
%(n1
<<<<<<< HEAD
t1
=======
b1
>>>>>>> b1
n2
<<<<<<< HEAD
t2
=======
b2
>>>>>>> b2
n3
)

    @top_version =
%(n1
t1
n2
t2
n3
)

    @bottom_version =
%(n1
b1
n2
b2
n3
)

    do_test
  end


  it 'more realistic' do
    @conflicted =
%(<<<<<<< HEAD
  config.gem 'gem1'
  config.gem 'gem2'
=======
  config.gem 'gem3'
>>>>>>> Added gem3

<<<<<<< HEAD
  config.time_zone = 'Pacific Time (US & Canada)'
=======
  config.cache_store = :mem_cache_store
>>>>>>> Set cache_store
)

    @top_version =
%(  config.gem 'gem1'
  config.gem 'gem2'

  config.time_zone = 'Pacific Time (US & Canada)'
)

    @bottom_version =
%(  config.gem 'gem3'

  config.cache_store = :mem_cache_store
)

    do_test
  end
end
=end

