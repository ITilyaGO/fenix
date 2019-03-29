require 'active_record/connection_adapters/sqlite3_adapter'

# module ActiveRecord::ConnectionAdapters
class ActiveRecord::ConnectionAdapters::SQLite3Adapter
  def initialize(db, logger, connection_options, config)
    # @config = d
    # binding.pry
    super(db, logger)
    
    @active = nil
    @statements = StatementPool.new(@connection, self.class.type_cast_config_to_integer(config.fetch(:statement_limit) { 1000 }))
    @config = config
    
    @visitor = Arel::Visitors::SQLite.new self
    @quoted_column_names = {}
    
    if self.class.type_cast_config_to_boolean(config.fetch(:prepared_statements) { true })
      @prepared_statements = true
    else
      @prepared_statements = false
    end
    # super
    # elf.new(db, logger, connection_options, config)
    # super
    # (a, b, nil, d)
    # db.create_function('regexp', 2) do |func, pattern, expression|
    #   regexp = Regexp.new(pattern.to_s, Regexp::IGNORECASE)
    # 
    #   if expression.to_s.match(regexp)
    #     func.result = 1
    #   else
    #     func.result = 0
    #   end
    # end
    
    db.create_function('umlike', 2) do |func, pattern, expression|
      # func.result = 1 if /#{ expression }/ =~ pattern
      # binding.pry
      # func.result = 1
      func.result = (/#{pattern.force_encoding(Encoding::UTF_8)}/ui).match(expression.force_encoding(Encoding::UTF_8).to_s) ? 1 : 0
    end
    
    # like_function = proc do |ctx, x, y|
    #   1 if /#{ x }/ =~ y
    # end
    # 
    # connection.create_function('unlike', 2, like_function)
  end
end