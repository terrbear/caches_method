require 'test/unit'
require File.join(File.dirname(__FILE__), '../init.rb')

class HashCache
  def initialize
    @hash = Hash.new
  end

  def fetch(key, options = {}, &block)
    @hash[key] ||= yield
  end

  def delete(key)
    @hash.delete(key)
  end

  def read(key)
    @hash[key]
  end

  def write(key, value)
    @hash[key] = value
  end

  def reset!
    @hash = Hash.new
  end
end

class Rails
  def self.cache
    @@hash_cache ||= HashCache.new  
  end
end

class CachedMethodRecord 
  include CachesMethod

  def self.reset!
    @@cache_num = 4
  end

  def self.cache_me_plz
    @@cache_num ||= 4
    @@cache_num += 1
  end

  def self.no_cache_plz; end;

  def id
    1
  end

  def expensive_method
    @@count ||= 4
    @@count += 1
  end

  def uncached_expensive_method
    @@count ||= 4
    @@count += 1
  end

  def blank_cache!

  end

  def blank_cache?
  end

  def blank_cache
  end

  def expensive_method_with_args(name)
    name.to_s.length + @@seed
  end

  def seed=(value)
    @@seed = value
  end

  def seed
    @@seed ||= 0
  end

  #only a different method to reset cache
  def reset_seed(value)
    @@seed = (value)
  end

  def reset!
    @@count = 4
  end

  caches_method :cache_me_plz, :expire_methods => [:no_cache_plz]
  caches_method :expensive_method, :expire_methods => [:blank_cache!, :blank_cache?, :blank_cache]
  caches_method :expensive_method_with_args, :expire_methods => [:reset_seed]
end

class CachesMethodTest < Test::Unit::TestCase
  def setup
    CachedMethodRecord.reset!
    @record = CachedMethodRecord.new
    @record.reset!
    Rails.cache.reset!
  end

  def test_class_methods_cached
    assert CachedMethodRecord.cache_me_plz == 5
    assert CachedMethodRecord.cache_me_plz == 5
  end

  def test_class_methods_support_expiry
    assert CachedMethodRecord.cache_me_plz == 5
    assert CachedMethodRecord.cache_me_plz == 5
    CachedMethodRecord.no_cache_plz 
    assert CachedMethodRecord.cache_me_plz != 5
  end

  def test_expensive_method_is_cached
    assert @record.expensive_method == 5
    assert @record.expensive_method == 5
  end

  def test_uncached_expensive_method
    assert @record.expensive_method == 5
    assert @record.uncached_expensive_method != 5
    assert @record.expensive_method == 5
  end

  def test_expiry_methods
    assert @record.expensive_method == 5
    assert @record.expensive_method == 5
    @record.blank_cache
    assert @record.expensive_method != 5
  end

  def test_make_sure_caches_dont_step_on_each_other
    assert @record.expensive_method == 5
    assert @record.expensive_method == 5
    @record.seed = 0
    assert @record.expensive_method_with_args("john") == 4
    @record.seed = 5
    @record.blank_cache
    assert @record.expensive_method_with_args("john") == 4
  end

  def test_expiry_methods_can_take_arguments
    @record.seed = 0
    assert_equal 4, @record.expensive_method_with_args("john") 
    @record.seed = 2
    assert_equal 4, @record.expensive_method_with_args("john")
    @record.reset_seed(5)
    assert_equal 9, @record.expensive_method_with_args("john")
  end

  def test_cache_methods_pay_attention_to_arguments
    @record.seed = 0
    assert_equal @record.expensive_method_with_args("john"), 4
    assert_equal @record.expensive_method_with_args("terry"), 5
  end

  def test_bangs_work
    assert @record.expensive_method == 5
    assert @record.expensive_method == 5
    @record.blank_cache!
    assert @record.expensive_method != 5
  end

  def test_questions_work
    assert @record.expensive_method == 5
    assert @record.expensive_method == 5
    @record.blank_cache?
    assert @record.expensive_method != 5
  end
end
