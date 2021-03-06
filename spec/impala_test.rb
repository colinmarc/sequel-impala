require File.join(File.dirname(File.expand_path(__FILE__)), 'spec_helper.rb')

describe "Impala column/table comments and describe" do
  before do
    @db = DB
  end
  after do
    @db.drop_table?(:items)
  end

  it "should set table and column comments correctly" do
    @db.create_table!(:items, :comment=>'tab_com') do
      Integer :i, :comment=>'col_com'
    end
    @db.describe(:items).first[:comment].must_equal 'col_com'
    @db.describe(:items, :formatted=>true).find{|r| r[:type].to_s.strip == 'comment' && r[:name] == ''}[:comment].strip.must_equal 'tab_com'
  end
end

describe "Impala dataset" do
  before do
    @db = DB
    @db.create_table!(:items) do
      Integer :id
      Integer :number
      String :name
    end
    @ds = @db[:items].order(:id)
    @ds.insert(1, 10, 'a')
  end
  after do
    @db.drop_table?(:items)
  end

  it "#update should emulate UPDATE" do
    @ds.update(:number=>20, :name=>'b')
    @ds.all.must_equal [{:id=>1, :number=>20, :name=>'b'}]
    @ds.where(:id=>1).update(:number=>30, :name=>'c')
    @ds.all.must_equal [{:id=>1, :number=>30, :name=>'c'}]
    @ds.where(:id=>2).update(:number=>40, :name=>'d')
    @ds.all.must_equal [{:id=>1, :number=>30, :name=>'c'}]
  end
end

describe "Impala dataset" do
  before do
    @db = DB
    @db.create_table!(:items){Integer :number}
    @ds = @db[:items]
    @ds.insert(1)
  end
  after do
    @db.drop_table?(:items)
  end

  it "#delete should emulate DELETE" do
    @ds.where(:number=>2).delete.must_equal nil
    @ds.count.must_equal 1
    @ds.where(:number=>1).delete.must_equal nil
    @ds.count.must_equal 0

    @ds.insert(1)
    @ds.count.must_equal 1
    @ds.delete.must_equal nil
    @ds.count.must_equal 0
  end

  it "#truncate should emulate TRUNCATE" do
    @ds.truncate.must_equal nil
    @ds.count.must_equal 0
  end

  it "#insert_overwrite should overwrite tables" do
    @ds.insert_overwrite.insert(2)
    @ds.select_map(:number).must_equal [2]
    @ds.insert(4)
    @ds.select_order_map(:number).must_equal [2, 4]
    @ds.insert_overwrite.insert(3)
    @ds.select_map(:number).must_equal [3]
  end
end

describe "Impala string comparisons" do
  before do
    @db = DB
    @db.create_table!(:items){String :name}
    @ds = @db[:items]
    @ds.insert('m')
  end
  after do
    @db.drop_table?(:items)
  end

  it "should work for equality and inequality" do
    @ds.where(:name => 'm').all.must_equal [{:name=>'m'}]
    @ds.where(:name => 'j').all.must_equal []
    @ds.exclude(:name => 'j').all.must_equal [{:name=>'m'}]
    @ds.exclude(:name => 'm').all.must_equal []
    @ds.where{name > 'l'}.all.must_equal [{:name=>'m'}]
    @ds.where{name > 'm'}.all.must_equal []
    @ds.where{name < 'n'}.all.must_equal [{:name=>'m'}]
    @ds.where{name < 'm'}.all.must_equal []
    @ds.where{name >= 'm'}.all.must_equal [{:name=>'m'}]
    @ds.where{name >= 'n'}.all.must_equal []
    @ds.where{name <= 'm'}.all.must_equal [{:name=>'m'}]
    @ds.where{name <= 'l'}.all.must_equal []
  end
end

describe "Impala date manipulation functions" do
  before do
    @db = DB
    @db.create_table!(:items){Time :t}
    @ds = @db[:items]
    @ds.insert(Date.today)
  end
  after do
    @db.drop_table?(:items)
  end

  it "date_add should work correctly" do
    @ds.get{date_add(t, 0)}.to_date.must_equal Date.today
    @ds.get{date_add(t, Sequel.lit('interval 0 days'))}.to_date.must_equal Date.today
    @ds.get{date_add(t, 1)}.to_date.must_equal(Date.today+1)
    @ds.get{date_add(t, Sequel.lit('interval 1 day'))}.to_date.must_equal(Date.today+1)
    @ds.get{date_add(t, -1)}.to_date.must_equal(Date.today-1)
    @ds.get{date_add(t, Sequel.lit('interval -1 day'))}.to_date.must_equal(Date.today-1)
  end

  it "should work with Sequel date_arithmetic extension" do
    @ds.extension!(:date_arithmetic)
    @ds.get(Sequel.date_add(:t, :days=>1)).to_date.must_equal(Date.today+1)
    @ds.get(Sequel.date_sub(:t, :days=>1)).to_date.must_equal(Date.today-1)
  end
end

describe "Impala syntax" do
  def ct_sql(opts)
    DB.send(:create_table_sql, :t, Sequel::Schema::CreateTableGenerator.new(DB){}, opts)
  end

  it "should produce correct sql for create_table" do
    ct_sql(:external=>true).must_equal 'CREATE EXTERNAL TABLE `t` ()'
    ct_sql(:stored_as=>:parquet).must_equal 'CREATE TABLE `t` () STORED AS parquet'
    ct_sql(:location=>'/a/b').must_equal "CREATE TABLE `t` () LOCATION '/a/b'"
    ct_sql(:field_term=>"\02").must_equal "CREATE TABLE `t` () ROW FORMAT DELIMITED FIELDS TERMINATED BY '\02'"
    ct_sql(:field_term=>"\02", :field_escape=>"\a").must_equal "CREATE TABLE `t` () ROW FORMAT DELIMITED FIELDS TERMINATED BY '\02' ESCAPED BY '\a'"
    ct_sql(:line_term=>"\01").must_equal "CREATE TABLE `t` () ROW FORMAT DELIMITED LINES TERMINATED BY '\01'"
  end

  it "should produce correct sql for load_data" do
    DB.send(:load_data_sql, '/a/b', :c, {}).must_equal "LOAD DATA INPATH '/a/b' INTO TABLE `c`"
    DB.send(:load_data_sql, '/a/b', :c, :overwrite=>true).must_equal "LOAD DATA INPATH '/a/b' OVERWRITE INTO TABLE `c`"
  end
end

describe "Impala create_table" do
  before do
    @db = DB
  end
  after do
    @db.drop_table?(:items)
  end

  it "should handle row format options" do
    DB.create_table(:items, :field_term=>"\001", :field_escape=>"\002", :line_term=>"\003"){Integer :a; Integer :b}
  end
end

describe "Impala parquet support" do
  before do
    @db = DB
  end
  after do
    @db.drop_table?(:items)
    @db.drop_table?(:items2)
  end

  it "should support parquet format using create_table :stored_as option" do
    @db.create_table!(:items, :stored_as=>:parquet){Integer :number}
    @ds = @db[:items]
    @ds.insert(1)
    @ds.all.must_equal [{:number=>1}]
  end

  it "should support parquet format via Dataset#to_parquet" do
    @db.create_table!(:items){Integer :number}
    @ds = @db[:items]
    @ds.insert(1)
    @ds.to_parquet(:items2)
    @db[:items2].all.must_equal [{:number=>1}]
  end
end unless DB.adapter_scheme == :rbhive

describe "Impala create/drop schemas" do
  before do
    DB.drop_table?(:s1__items)
    DB.drop_schema(:s1, :if_exists=>true)
  end

  it "should use correct SQL" do
    DB.send(:create_schema_sql, :s1, {}).must_equal "CREATE SCHEMA `s1`"
    DB.send(:create_schema_sql, :s1, :if_not_exists=>true).must_equal "CREATE SCHEMA IF NOT EXISTS `s1`"
    DB.send(:create_schema_sql, :s1, :location=>'/a/b').must_equal "CREATE SCHEMA `s1` LOCATION '/a/b'"

    DB.send(:drop_schema_sql, :s1, {}).must_equal "DROP SCHEMA `s1`"
    DB.send(:drop_schema_sql, :s1, :if_exists=>true).must_equal "DROP SCHEMA IF EXISTS `s1`"
  end

  it "should support create_schema and drop_schema" do
    DB.create_schema(:s1)
    DB.create_schema(:s1, :if_not_exists=>true)
    proc{DB.create_schema(:s1)}.must_raise Sequel::DatabaseError
    DB.create_table(:s1__items){Integer :number}
    DB[:s1__items].insert(1)
    DB[:s1__items].all.must_equal [{:number=>1}]
    DB.drop_table(:s1__items)
    DB.drop_schema(:s1)
    proc{DB.drop_schema(:s1)}.must_raise Sequel::DatabaseError
    DB.drop_schema(:s1, :if_exists=>true)
  end
end

describe "Impala :search_path option" do
  before do
    DB.create_schema(:s1, :if_not_exists=>true)
    DB.create_schema(:s2, :if_not_exists=>true)
    DB.create_schema(:s3, :if_not_exists=>true)
    DB.create_table(:s1__t1){Integer :a}
    DB.create_table(:s2__t1){Integer :a}
    DB.create_table(:s3__t1){Integer :a}
    DB.create_table(:s2__t2){Integer :a}
    DB.create_table(:s3__t2){Integer :a}
    DB.create_table(:s3__t3){Integer :a}
    DB.opts[:search_path] = 's1,s2,s3'
  end
  after do
    DB.opts.delete(:search_path)
    DB.drop_table?(:s3__t3, :s3__t2, :s2__t2, :s3__t1, :s2__t1, :s1__t1)
    DB.drop_schema(:s3)
    DB.drop_schema(:s2)
    DB.drop_schema(:s1)
  end

  it "should use the search_path to implicitly qualify tables" do
    DB[:t1].insert(1)
    DB[:t2].insert(1)
    DB[:t3].insert(1)
    DB[:s1__t1].count.must_equal 1
    DB[:s2__t2].count.must_equal 1
    DB[:s3__t3].count.must_equal 1
    DB[:t1].select_map(:a).must_equal [1]
    DB[:t1].join(:t2, [:a]).select_map([:t1__a, :t2__a]).must_equal [[1, 1]]
    DB[:t1].join(:t2, [:a]).join(:t3, [:a]).select_map([:t1__a, :t2__a, :t3__a]).must_equal [[1, 1, 1]]
  end
end

describe "Impala except/intersect" do
  before do
    DB.create_table!(:a){Integer :a; Integer :b; Integer :c}
    DB.create_table!(:b){Integer :d; Integer :e; Integer :f}
  end
  after do
    DB.drop_table?(:a)
    DB.drop_table?(:b)
  end

  it "should be emulated correctly" do
    DB[:a].import([:a, :b, :c], [[1,2,3], [1,2,3], [2,3,4], [3,4,5], [3,4,5]])
    DB[:b].import([:d, :e, :f], [[1,2,3], [2,3,4], [2,3,4], [4,5,6], [4,5,6]])

    DB[:a].intersect(DB[:b]).select_order_map([:a, :b, :c]).must_equal [[1,2,3], [2,3,4]]
    DB[:b].intersect(DB[:a]).select_order_map([:d, :e, :f]).must_equal [[1,2,3], [2,3,4]]
    DB[:a].intersect(DB[:a]).select_order_map([:a, :b, :c]).must_equal [[1,2,3], [2,3,4], [3,4,5]]
    DB[:b].intersect(DB[:b]).select_order_map([:d, :e, :f]).must_equal [[1,2,3], [2,3,4], [4,5,6]]

    DB[:a].except(DB[:b]).select_order_map([:a, :b, :c]).must_equal [[3,4,5]]
    DB[:b].except(DB[:a]).select_order_map([:d, :e, :f]).must_equal [[4,5,6]]
    DB[:a].except(DB[:a]).select_order_map([:a, :b, :c]).must_equal []
    DB[:b].except(DB[:b]).select_order_map([:d, :e, :f]).must_equal []

    DB[:a].intersect(DB[:b]).unfiltered.select_order_map([:a, :b, :c]).must_equal [[1,2,3], [2,3,4]]
    DB[:a].except(DB[:b]).unfiltered.select_order_map([:a, :b, :c]).must_equal [[3,4,5]]

    DB[:a].intersect(DB[:b], :alias=>:q).where(:q__b=>2).select_order_map([:a, :b, :c]).must_equal [[1,2,3]]
    DB[:a].except(DB[:b], :alias=>:q).where(:q__b=>2).select_order_map([:a, :b, :c]).must_equal []
    DB[:a].except(DB[:b], :alias=>:q).where(:q__b=>4).select_order_map([:a, :b, :c]).must_equal [[3,4,5]]
  end
end

