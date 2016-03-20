require './sgf'
require './board'

sgf = Sgf.new(File.read(ARGV[0]))

board = Board.new(sgf.board_size)

sgf.moves.each do |move|
  if move.key == 'B'
    board.black_stone(move.value)
  elsif move.key == 'W'
    board.white_stone(move.value)
  end
  puts "\e[H\e[2J"
  puts "White: %s (captures: %d), Black: %s (captures: %d)" % [
    sgf.white_name, board.white_captures, sgf.black_name, board.black_captures
  ]
  puts board.to_s
  puts "Move: %d" % [board.moves]
  sleep(0.1)
end
