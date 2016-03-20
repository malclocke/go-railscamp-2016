require './game'

game = Game.new
game.boardsize = 9

game.board.highlight_x = game.board.highlight_y = 0

game.play
