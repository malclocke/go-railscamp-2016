class SgfStatement
  attr_reader :key, :value
  def initialize(statement)
    @key, @value = statement.match(/([A-Z]+?)\[(.+?)\]/)[1,2]
  end
end

class Sgf

  include Enumerable

  attr_reader :string

  def initialize(string)
    @string = string
  end

  def to_s
    string
  end

  def each
    string.split(';').each do |command|
      command.scan(/[A-Z]+?\[.+?\]/) do |statement|
        yield SgfStatement.new(statement)
      end
    end
  end

  def find_statement(name)
    find do |statement|
      statement.key == name
    end
  end

  def find_statement_value(key, default)
    statement = find_statement(key)
    statement ? statement.value : default
  end

  def board_size
    find_statement('SZ').value.to_i
  end

  def moves
    select do |statement|
      statement.key == "B" || statement.key == "W"
    end
  end

  def white_name
    @white_name ||= find_statement_value('PW', 'Unknown')
  end

  def black_name
    @black_name ||= find_statement_value('PB', 'Unknown')
  end
end
