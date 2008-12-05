class String
  # Makes the first character bold and underlined. Makes the whole string of the given color.
  def menu_item(color = :white, letter = self[0..0], which_occurence = 0)
    index = index_all(/#{Regexp.escape(letter)}/)[which_occurence]
    raise "Could not find a #{which_occurence}th occurence of '#{letter}' in string '#{self}'" if index.nil?
    before = self[0..index-1].send(color) unless index == 0
    middle = self[index..index].send(color).bold.underline
    after  = self[index+1..-1].send(color)
    before.to_s + middle + after
  end

  def highlight_occurences(search_pattern, color = :red)
    self.gsub(search_pattern) { $&.send(color).bold }
  end
end

def confirm(question, options = ['Yes', 'No'])
  print question + " " +
    "Yes".menu_item(:red) + ", " +
    "No".menu_item(:green) + 
    " > "
  response = ''
  # Currently allow user to press Enter to accept the default.
  response = $stdin.getch.downcase while !['y', 'n', "\n"].include?(begin response.downcase!; response end)
  response
end
