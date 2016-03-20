require 'io/console'
require './board'

class Player

  attr_reader :board, :colour

  def initialize(board, colour)
    @board = board
    @colour = colour
  end
end

class HumanPlayer < Player

  def print_board
    puts "\e[H\e[2J"
    puts board.to_s
  end

  def get_move
    loop do
      print_board

      c = read_char
      break if c == "q"
      case c
      when "\e[A", "\eOA", "j"
        # Up
        board.highlight_x = [board.highlight_x - 1, 0].max
      when "\e[B", "\eOB", "k"
        # Down
        board.highlight_x = [board.highlight_x + 1, board.size - 1].min
      when "\e[D", "\eOD", "h"
        # Left
        board.highlight_y = [board.highlight_y - 1, 0].max
      when "\e[C", "\eOC", "l"
        # Right
        board.highlight_y = [board.highlight_y + 1, board.size - 1].min
      when "\r"
        return board.highlight_position
      else
        puts "WTF #{c.inspect}"
      end
    end
  end

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

  def oponent_moved(position)
    # noop for a human
  end
end

class GnuGoPlayer < Player

  def gnugo
    @gnugo ||= get_pipe
  end

  def oponent_moved(position)
    gnugo_command (
      "play %s %s" % [
        oponent_colour, position_to_coord(position)
      ]
    )
  end

  def oponent_colour
    colour == "white" ? "black" : "white"
  end

  def get_move
    line = gnugo_command("genmove %s" % colour).chomp
    if line.chomp == "= PASS"
      return nil
    end
    _, position = line.split(' ')
    x, y = position.chars
    if x.downcase.ord >= 105
      x = (x.downcase.ord - 1).chr
    end
    "%s%s" % [x.downcase, (y.to_i + 96).chr]
  end

  private
  def get_pipe
    IO.popen("gnugo --mode gtp", "r+").tap do |io|
      gnugo_command("boardsize %d" % board.size, io)
      gnugo_command("clear_board", io)
    end
  end

  private
  def position_to_coord(position)
    x,y = position.chars
    "%s%d" % [x.upcase, y.downcase.ord - 96]
  end

  private
  def gnugo_command(str, io = nil)
    io ||= gnugo
    puts "SENDING '#{str}'"
    io.puts str
    res = ""
    loop do
      line = io.gets
      break if line == "\n"
      res.concat(line)
    end
    puts "RECEIVED '#{res}'"
    return res
  end
end

class Game

  attr_writer :moves, :boardsize

  def moves
    @moves ||= 0
  end

  def boardsize
    @boardsize ||= 19
  end

  def board
    @board ||= Board.new(boardsize)
  end

  def black
    @black ||= HumanPlayer.new(board, "black")
  end

  def white
    @white ||= GnuGoPlayer.new(board, "white")
  end

  def play
    until game_over?
      if position = black.get_move
        board.black_stone(position)
        white.oponent_moved(position)
      end

      if position = white.get_move
        board.white_stone(position)
        black.oponent_moved(position)
      end
    end
  end

  def play_move(player)
    player.play_move
    self.moves += 1
  end

  def game_over?
    moves > 50
  end
end
