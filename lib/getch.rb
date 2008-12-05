begin
  gem 'termios'
  require 'termios'
  begin
    # Set up termios so that it returns immediately when you press a key.
    # (http://blog.rezra.com/articles/2005/12/05/single-character-input)
    t = Termios.tcgetattr(STDIN)
    save_terminal_attributes = t.dup
    t.lflag &= ~Termios::ICANON
    Termios.tcsetattr(STDIN, 0, t)

    # Set terminal_attributes back to how we found them...
    at_exit { Termios.tcsetattr(STDIN, 0, save_terminal_attributes) }
  rescue RuntimeError => exception    # Necessary for automated testing.
    if exception.message =~ /can't get terminal parameters/
      # :todo: Can we detect if they are piping/redirecting stdout? Don't show warning if they are simply piping stdout.
      # On the other hand, when ELSE do we expect to not find a terminal? Is this message *ever* helpful?
      # Only testing? Then maybe the tests should set an environment variable or *something* to communicate that they want non-interactive mode.
      puts 'Warning: Terminal not found.'
      $interactive = false
    else
      raise
    end
  end
  $termios_loaded = true
rescue Gem::LoadError
  $termios_loaded = false
end

class IO
  # Gets a single character, as a string.
  # Adjusts for the different behavior of getc if we are using termios to get it to return immediately when you press a single key
  # or if they are not using that behavior and thus have to press Enter after their single key.
  def getch(options = {})
    response = getc
    if !$termios_loaded
      next_char = getc
      new_line_characters_expected = ["\n"]
      #new_line_characters_expected = ["\n", "\r"] if windows?
      if next_char.chr.in?(new_line_characters_expected)
        # Eat the newline character
      else
        # Don't eat it
        # (This case is necessary, for escape sequences, for example, where they press only one key, but it produces multiple characters.)
        STDIN.ungetc(next_char)
      end
    end

    response = response.chr
    response = response.downcase if options[:downcase]

    # Handle multi-character escape sequence such as the up arrow key ("\e[A")
    if response == "\e"
      response << (next_char = STDIN.getch)
      if next_char == '['
        response << (next_char = STDIN.getch)
      end
    end

    response
  end
end

