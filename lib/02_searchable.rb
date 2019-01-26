require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    params_string = params.keys.map{|key| "#{key} = ?"}.join(" AND ")
    p params_string
    p params.values
    data = DBConnection.execute(<<~SQL, *(params.values))
      SELECT
        * 
      FROM
        #{table_name}
      WHERE
        #{params_string}
    SQL
    parse_all(data)
  end
end

class SQLObject
  extend Searchable
end
