require 'strscan'

module Nitlink
  class Splitter
    def initialize(string)
      @string = string
      @scanner = StringScanner.new(string)
    end

    def split_on_unquoted(seperator)
      # 0 = start of string
      split_positions, ignored_split_positions = [0], [] 
      in_quote = false

      until @scanner.eos?
        char = @scanner.getch
        @scanner.getch if in_quote && char == "\\"

        in_quote = !in_quote if char == '"'
        @scanner.skip_until(/>/) and next if char == '<' && in_url?

        if char == seperator
          ignored_split_positions = []
          (in_quote ? ignored_split_positions : split_positions) << @scanner.pos
        end
      end
      split_positions << @string.length # end of string
      split_positions += ignored_split_positions if in_quote # dangling quote

      split_positions.sort.each_cons(2).inject([]) do |split_parts, (start_pos, end_pos)|
        split_parts << @string[start_pos...end_pos].chomp(seperator)
      end
    end

    def in_url?
      preceeding = @scanner.string[0...(@scanner.pos - 1)].strip
      preceeding.end_with?(',') || preceeding.empty?
    end
  end
end