require 'set'

class Stone
  attr_reader :x, :y
  def initialize(x, y)
    @x = x
    @y = y
  end

  def friend_of?(stone)
    stone.instance_of?(self.class)
  end
  def enemy_of?(stone)
    !friend_of?(stone)
  end
end

class BlackStone < Stone
  def to_s
    "○"
  end
end

class WhiteStone < Stone
  def to_s
    "●"
  end
end

class EmptyCell

  attr_reader :board, :x, :y, :str

  def initialize(board, x, y)
    @board = board
    @x = x
    @y = y
    #@str = get_str
  end

  def highlight_select(str)
    if row_highlighted? && col_highlighted?
      str[0]
    elsif row_highlighted?
      str[1]
    elsif col_highlighted?
      str[2]
    else
      str[3]
    end
  end

  def row_highlighted?
    board.highlight_x == x
  end

  def col_highlighted?
    board.highlight_y == y
  end

  def to_s
    get_str
  end

  def inspect
    "#<EmptyCell:%s x=%d, y=%d>" % [object_id, x, y]
  end

  private
  def get_str
    if x == 0
      if y == 0
        highlight_select("┏┍┎┌")
      elsif y == board.size - 1
        highlight_select("┓┑┒┐")
      else
        highlight_select("┳┯┰┬")
      end
    elsif x == board.size - 1
      if y == 0
        highlight_select("┗┕┖└")
      elsif y == board.size - 1
        highlight_select("┛┙┚┘")
      else
        highlight_select("┻┷┸┴")
      end
    elsif y == 0
      highlight_select("┣┝┠├")
    elsif y == board.size - 1
      highlight_select("┫┥┨┤")
    else
      highlight_select("╋┿╂┼")
    end
  end
end

class Board

  attr_reader :size
  attr_accessor :moves, :highlight_x, :highlight_y
  attr_writer :white_captures, :black_captures

  class IllegalMoveError < StandardError ; end
  class OutOfBoundsError < StandardError ; end
  
  def initialize(size)
    @size = size
    @moves = 0
  end

  def highlight_position
    position_from_xy(highlight_y, highlight_x)
  end

  def black_captures
    @black_captures ||= 0
  end

  def white_captures
    @white_captures ||= 0
  end

  def matrix
    @matrix ||= build_board
  end

  def to_s
    matrix.map {|a| a.join}.join("\n")
  end

  def black_stone(position)
    place_stone(position, BlackStone)
  end

  def white_stone(position)
    place_stone(position, WhiteStone)
  end

  def place_stone(position, klass)
    y,x = if position.respond_to?(:x) && position.respond_to?(:y)
            [position.y, position.x]
          else
            xy_from_position(position)
          end
    #puts "x = #{x}, y = #{y}"
    raise OutOfBoundsError.new if x >= size || x < 0 || y >= size  || y < 0
    raise IllegalMoveError.new if matrix[x][y].is_a?(Stone)
    stone = matrix[x][y] = klass.new(x, y)
    destroy_enemy_groups(stone)
    self.moves += 1
    return stone
  end

  def destroy_enemy_groups(stone)
    neighbouring_enemy_groups(stone).each do |group|
      if group_liberties(group).size < 1
        destroy_group(group)
      end
    end
  end

  def destroy_group(group)
    if group.first.is_a?(BlackStone)
      self.white_captures += group.size
    else
      self.black_captures += group.size
    end
    group.each do |stone|
      matrix[stone.x][stone.y] = EmptyCell.new(self, stone.x, stone.y)
    end
  end

  def neighbours(stone)
    a = []
    if stone.x > 0
      a << matrix[stone.x - 1][stone.y]
    end

    if stone.y > 0
      a << matrix[stone.x][stone.y - 1]
    end

    if stone.x < size - 1
      a << matrix[stone.x + 1][stone.y]
    end

    if stone.y < size - 1
      a << matrix[stone.x][stone.y + 1]
    end
    return a
  end

  def liberties(stone)
    neighbours(stone).select do |n|
      n.is_a?(EmptyCell)
    end
  end

  def group_liberties(group)
    group.map do |stone|
      liberties(stone)
    end.flatten.uniq
  end

  def neighbouring_stones(stone)
    neighbours(stone).select do |n|
      n.is_a?(Stone)
    end
  end

  def enemy_neighbours(stone)
    neighbouring_stones(stone).select do |n|
      n.enemy_of?(stone)
    end
  end

  def friendly_neighbours(stone)
    neighbouring_stones(stone).select do |n|
      n.friend_of?(stone)
    end
  end

  def group(stone, set = Set.new)
    neighbours = friendly_neighbours(stone)
    neighbours.each do |n|
      if set.add?(n)
        group(n, set)
      end
    end
    set.add(stone)
    return set
  end

  def neighbouring_enemy_groups(stone)
    sets = []
    enemy_neighbours(stone).each do |neighbour|
      x = sets.any? {|set| set.include?(neighbour)}
      next if x
      g = group(neighbour)
      sets << g
    end
    return sets
  end

  private
  def build_board
    size.times.each_with_index.map do |y, xi|
      size.times.each_with_index.map do |x, yi| 
        EmptyCell.new(self, xi, yi)
      end
    end
  end

  private
  def xy_from_position(position)
    position.chars.map { |c| c.downcase.ord - 97 }
  end

  private
  def position_from_xy(x, y)
    "%s%s" % [(x + 97).chr, (y + 97).chr]
  end

end
