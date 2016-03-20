require './board'

board = Board.new(19)

black = true

positions = 400.times.map do
  "abcdefghijklmnopqrs".chars.sample.concat(
    "abcdefghijklmnopqrs".chars.sample
  )
end
#positions = ["ba", "bc", "aa", "ac", "bb", "ab", "da", "ca", "db", "cb"]

positions.each do |position|
  begin
    stone = if black
      board.black_stone(position)
    else
      board.white_stone(position)
    end
  rescue Board::IllegalMoveError => e
    next
  end

  puts "\e[H\e[2J"
  puts "White captures: %d, Black captures: %d" % [
    board.white_captures, board.black_captures
  ]
  puts board.to_s
  puts "Moves: %d" % board.moves
  sleep 0.05
  black = !black
end
