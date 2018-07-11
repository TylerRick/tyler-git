#---------------------------------------------------------------------------------------------------
require 'facets/string/index_all'
require File.dirname(__FILE__) + '/../lib/getch'

# :todo: Move out to extensions/console/menu_item

#---------------------------------------------------------------------------------------------------

# Copied from Subwrap and modified API
#  puts(
#    'View this changeset'.menu_item(:cyan) + ', ' +
#    'Diff against specific revision'.menu_item(:cyan, :letter => 'D') + ', ' +
#    'Grep the changeset'.menu_item(:cyan, :letter => 'G') + ', ' +
#    'List or '.menu_item(:magenta, :letter => 'L') + '' +
#    'Edit revision properties'.menu_item(:magenta, :letter => 'E') + ', ' +
#    'svn Cat all files'.menu_item(:cyan, :letter => 'C') + ', ' +
#    'grep the cat'.menu_item(:cyan, :letter => 'a') + ', ' + "\n  " +
#    'mark as Reviewed'.menu_item(:green, :letter => 'R') + ', ' +
#    'edit log Message'.menu_item(:yellow, :letter => 'M') + ', ' +
#    'browse using ' + 'Up/Down/Left/Right/Space/Enter'.white.bold + ' keys' + ', ' +
#    'Quit'.menu_item(:magenta)
#  )
class String
  # Makes the first character bold and underlined. Makes the whole string of the given color.
  def menu_item(color = :white, options = {})
    options[:letter] ||= self[0..0]
    options[:which_occurence] ||= 0
    options[:bold] = true if options[:bold].nil?

    index = index_all(/#{options[:letter]}/)[options[:which_occurence]]
    raise "Could not find a #{options[:which_occurence]}th occurence of '#{options[:letter]}' in string '#{self}'" if index.nil?

    before = self[0..index-1].send(color) unless index == 0

    middle = self[index..index].send(color)
    middle = middle.bold if options[:bold]
    middle = middle.underline

    after  = self[index+1..-1].send(color)

    before.to_s + middle + after
  end
  # Extracted so that we can override it for tests. Otherwise it will have a NoMethodError because $? will be nil because it will not have actually executed any commands.
  def add_exit_code_error
    self << "Exited with error!".bold.red if !exit_code.success?
    self
  end
  def relativize_path
    self.gsub(File.expand_path(FileUtils.getwd) + '/', '')   # Simplify the directory by removing the working directory from it, if possible
  end
  def highlight_occurences(search_pattern, color = :red)
    self.gsub(search_pattern) { $&.send(color).bold }
  end
end

#---------------------------------------------------------------------------------------------------

# Copied from Subwrap and modified API
#
#  response = confirm("Are you sure you want to ___?")
#  puts
#  if response == 'y'
#   ...
#  end
#
# use menu()!
def confirm(question, options = {})
  #options[:options] ||= ['Yes', 'No'] # not used
  options[:default] == nil
  #,  :bold => options[:default] == 'Yes'
  print question + " " +
    "Yes".menu_item(:red) + ", " +
    "No".menu_item(:green) +
    (" [#{options[:default]}]" if options[:default]).to_s +
    " > "
  response = ''

  # Allow user to press Enter to accept the default.
  allowed_options = ['y', 'n']
  allowed_options << "\n" if options[:default]

  response = $stdin.getch.downcase while !allowed_options.include?((response.downcase!; response))
  if response == "\n"
    response = options[:default]
  end
  response
end

def menu(question, menu_items, options = {})
  options[:default] == nil
end

