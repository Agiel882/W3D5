require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    unless @columns
      data = DBConnection.execute2(<<-SQL)
        SELECT
          *
        FROM
          #{table_name}
      SQL
    @columns = data[0].map(&:to_sym)
    end
    @columns
  end

  def self.finalize!
    columns.each do |col|
      self.define_method(col) do
        attributes[col]
      end
      self.define_method("#{col}=") do |var|
        attributes[col] = var
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.to_s.tableize
  end

  def self.all
    data = DBConnection.execute(<<~SQL)
      SELECT
        *
      FROM
        '#{table_name}'
    SQL
    parse_all(data)
  end

  def self.parse_all(results)
    results.map{|datum| self.new(datum)}
  end

  def self.find(id)
    data = DBConnection.execute(<<~SQL, id)
      SELECT
        *
      FROM
        '#{table_name}'
      WHERE
        id = ?
    SQL
    parse_all(data)[0]
  end

  def initialize(params = {})
    params.each do |k, v|
      raise "unknown attribute '#{k}'" unless self.class.columns.include?(k.to_sym)
      self.send("#{k}=", v)
    end

  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map{|col| send("#{col}")}
  end

  def insert
    col_names = self.class.columns.join(", ")
    question_marks = (["?"] * self.class.columns.length).join(", ")
    DBConnection.execute(<<~SQL, *attribute_values)
    INSERT INTO
      #{self.class.table_name} (#{col_names})
    VALUES
      (#{question_marks})
    SQL
    self.id = DBConnection.last_insert_row_id
  end


  def update
    cols = attributes.keys.map(&:to_s)
    column_string = cols.join(" = ?, ") + " = ?"
    DBConnection.execute(<<~SQL, *attribute_values)
      UPDATE
        #{self.class.table_name}
      SET
        #{column_string}
      WHERE
        id = #{self.id}
    SQL
  end

  def save
    if self.id
      update
    else
      insert
    end
  end
end
