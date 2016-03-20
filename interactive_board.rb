require 'io/console'
require './board'

def read_char
  STDIN.echo = false
  STDIN.raw!

  input = STDIN.getc.chr
  if input == "\e" then
    input << STDIN.read_nonblock(3) rescue nil
    input << STDIN.read_nonblock(2) rescue nil
  end
ensure
  STDIN.echo = true
  STDIN.cooked!

  return input
end

board = Board.new(19)

board.highlight_x = 0
board.highlight_y = 0

loop do
  puts "\e[H\e[2J"
  puts board.to_s

  c = read_char
  break if c == "q"
  case c
  when "\e[A", "\eOA", "j"
    # Up
    board.highlight_x = [board.highlight_x - 1, 0].max
  when "\e[B", "\eOB", "k"
    # Down
    board.highlight_x = [board.highlight_x + 1, board.size].min
  when "\e[D", "\eOD", "h"
    # Left
    board.highlight_y = [board.highlight_y - 1, 0].max
  when "\e[C", "\eOC", "l"
    # Right
    board.highlight_y = [board.highlight_y + 1, board.size].min
  when "\r"
    board.black_stone(board.highlight_position)
  else
    puts "WTF #{c.inspect}"
  end
end
