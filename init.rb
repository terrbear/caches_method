require 'rubygems'
gem 'activerecord'
require 'activerecord'
require File.join(File.dirname(__FILE__), 'lib/caches_method')
ActiveRecord::Base.send :include, CachesMethod
