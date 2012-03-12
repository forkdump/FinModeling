module FinModeling

  class AnnualReportFiling < CompanyFiling

    CONSTRUCTOR_PATH = "constructors/"
    def self.download(url, caching=true)
      uid = url.split("/")[-2..-1].join('-').gsub(/\.[A-zA-z]*$/, '')
      constructor_file = CONSTRUCTOR_PATH + uid + '.rb'
      if caching==true && File.exists?(constructor_file)
        eval(File.read(constructor_file))
        return @filing
      end

      filing = super(url)

      file = File.open(constructor_file, "w")
      filing.write_constructor(file, "@filing")
      file.close

      return filing
    end

    def balance_sheet
      if @balance_sheet.nil?
        calculations=@taxonomy.callb.calculation
        bal_sheet = calculations.find{ |x| (x.clean_downcased_title =~ /statement.*financial.*position/) or
                                           (x.clean_downcased_title =~ /statement.*financial.*condition/) or
                                           (x.clean_downcased_title =~ /balance.*sheet/) }
        if bal_sheet.nil?
          raise RuntimeError.new("Couldn't find balance sheet in: " + calculations.map{ |x| "\"#{x.clean_downcased_title}\"" }.join("; "))
        end
    
        @balance_sheet = BalanceSheetCalculation.new(bal_sheet)
      end
      return @balance_sheet
    end

    def income_statement
      if @income_stmt.nil?
        calculations=@taxonomy.callb.calculation
        inc_stmt = calculations.find{ |x| (x.clean_downcased_title =~ /statement.*operations/) or
                                          (x.clean_downcased_title =~ /statement[s]*.*of.*earnings/) or
                                          (x.clean_downcased_title =~ /statement[s]*.*of.*income/) or
                                          (x.clean_downcased_title =~ /statement[s]*.*of.*net.*income/) }
        if inc_stmt.nil?
          raise RuntimeError.new("Couldn't find income statement in: " + calculations.map{ |x| "\"#{x.clean_downcased_title}\"" }.join("; "))
        end
    
        @income_stmt = IncomeStatementCalculation.new(inc_stmt)
      end
      return @income_stmt
    end

    def is_valid?
      return (income_statement.is_valid? and balance_sheet.is_valid?)
    end

    def write_constructor(file, item_name)
      bs_name = item_name + "_bs"
      is_name = item_name + "_is"
      self.balance_sheet.write_constructor(file, bs_name)
      self.income_statement.write_constructor(file, is_name)

      # FIXME: this isn't the smartest way to go. It should have specs; it doesn't have full functionality
      file.puts "#{item_name} = FinModeling::FakeAnnualFiling.new(#{bs_name}, #{is_name})"
    end
  end
end
