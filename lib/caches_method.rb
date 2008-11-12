# CachesMethod
module CachesMethod
  def self.included(base)
    base.extend(ClassMethods)
  end

  def sanitize_method_name(name)
    name, punctuation = name.to_s.sub(/([?!=])/, ''), $1
    "#{name}#{punctuation}" 
  end

  def keyify(args)
    args.map{|a| a.to_s}.join("/")
  end

  module ClassMethods
    def caches_method(method, options = {})
      #options:
      #ttl - expire time
      #expire_methods - array of methods that expire the cache

      options.reverse_merge!(:ttl => 15.minutes, :expire_methods => [])

      
      class_eval do
        define_method(sanitize_method_name("#{method}_with_cache")) do |*args|
          cache_key = "#{self.class.name}/#{self.id}/#{method}/"
          Rails.cache.write(cache_key + "_index", (Rails.cache.read(cache_key + "_index") || []) + [cache_key + keyify(args)])
          Rails.cache.fetch(cache_key + keyify(args), 
                            :expires_in => options[:ttl]) do
            self.send(sanitize_method_name("#{method}_without_cache"), *args)
          end
        end

        if !self.instance_methods.include?(method.to_s)
          define_method("#{method}", lambda{nil})
        end
        
        alias_method_chain method, :cache 
      end

      [options[:expire_methods]].flatten.each do |em|
        class_eval do
          define_method(sanitize_method_name("#{em}_with_expire")) do |*args|
            cache_key = "#{self.class.name}/#{self.id}/#{method}/"
            (Rails.cache.read(cache_key + "_index") || []).each do |ck|
              Rails.cache.delete(ck)
            end
            Rails.cache.delete(cache_key + "_index")
            self.send(sanitize_method_name("#{em}_without_expire"), *args)
          end

          alias_method_chain em, :expire
        end
      end
    end

    def sanitize_method_name(name)
      name, punctuation = name.to_s.sub(/([?!=])/, ''), $1
      "#{name}#{punctuation}" 
    end
  end #ClassMethods

end #CachesMethod
