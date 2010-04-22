# Extends the class object with class and instance accessors for class attributes,
# just like the native attr* accessors for instance attributes.
#
#  class Person
#    cattr_accessor :hair_colors
#  end
#
#  Person.hair_colors = [:brown, :black, :blonde, :red]
class Class
  unless self.respond_to?(:cattr_reader)
    def cattr_reader(*syms)
      options = syms.extract_options!
      syms.each do |sym|
        class_eval(<<-EOS, __FILE__, __LINE__ + 1)
          unless defined? @@#{sym}
            @@#{sym} = nil
          end

          def self.#{sym}
            @@#{sym}
          end
        EOS

        unless options[:instance_reader] == false
          class_eval(<<-EOS, __FILE__, __LINE__ + 1)
            def #{sym}
              @@#{sym}
            end
          EOS
        end
      end
    end
  end

  unless self.respond_to?(:cattr_writer)
    def cattr_writer(*syms)
      options = syms.extract_options!
      syms.each do |sym|
        class_eval(<<-EOS, __FILE__, __LINE__ + 1)
          unless defined? @@#{sym}
            @@#{sym} = nil
          end

          def self.#{sym}=(obj)
            @@#{sym} = obj
          end
        EOS

        unless options[:instance_writer] == false
          class_eval(<<-EOS, __FILE__, __LINE__ + 1)
            def #{sym}=(obj)
              @@#{sym} = obj
            end
          EOS
        end
        self.send("#{sym}=", yield) if block_given?
      end
    end
  end

  unless self.respond_to?(:cattr_accessor)
    def cattr_accessor(*syms, &blk)
      cattr_reader(*syms)
      cattr_writer(*syms, &blk)
    end
  end

  unless self.respond_to?(:class_inheritable_reader)
    def class_inheritable_reader(*syms)
      options = syms.extract_options!
      syms.each do |sym|
        next if sym.is_a?(Hash)
        class_eval(<<-EOS, __FILE__, __LINE__ + 1)
          def self.#{sym}                                # def self.after_add
            read_inheritable_attribute(:#{sym})          #   read_inheritable_attribute(:after_add)
          end                                            # end
                                                         #
          #{"                                            #
          def #{sym}                                     # def after_add
            self.class.#{sym}                            #   self.class.after_add
          end                                            # end
          " unless options[:instance_reader] == false }  # # the reader above is generated unless options[:instance_reader] == false
        EOS
      end
    end
  end

  unless self.respond_to?(:class_inheritable_writer)
    def class_inheritable_writer(*syms)
      options = syms.extract_options!
      syms.each do |sym|
        class_eval(<<-EOS, __FILE__, __LINE__ + 1)
          def self.#{sym}=(obj)                          # def self.color=(obj)
            write_inheritable_attribute(:#{sym}, obj)    #   write_inheritable_attribute(:color, obj)
          end                                            # end
                                                         #
          #{"                                            #
          def #{sym}=(obj)                               # def color=(obj)
            self.class.#{sym} = obj                      #   self.class.color = obj
          end                                            # end
          " unless options[:instance_writer] == false }  # # the writer above is generated unless options[:instance_writer] == false
        EOS
      end
    end
  end

  unless self.respond_to?(:class_inheritable_hash_writer)
    def class_inheritable_hash_writer(*syms)
      options = syms.extract_options!
      syms.each do |sym|
        class_eval(<<-EOS, __FILE__, __LINE__ + 1)
          def self.#{sym}=(obj)                          # def self.nicknames=(obj)
            write_inheritable_hash(:#{sym}, obj)         #   write_inheritable_hash(:nicknames, obj)
          end                                            # end
                                                         #
          #{"                                            #
          def #{sym}=(obj)                               # def nicknames=(obj)
            self.class.#{sym} = obj                      #   self.class.nicknames = obj
          end                                            # end
          " unless options[:instance_writer] == false }  # # the writer above is generated unless options[:instance_writer] == false
        EOS
      end
    end
  end

  unless self.respond_to?(:class_inheritable_accessor)
    def class_inheritable_accessor(*syms)
      class_inheritable_reader(*syms)
      class_inheritable_writer(*syms)
    end
  end

  unless self.respond_to?(:class_inheritable_hash)
    def class_inheritable_hash(*syms)
      class_inheritable_reader(*syms)
      class_inheritable_hash_writer(*syms)
    end
  end

  unless self.respond_to?(:inheritable_attributes)
    def inheritable_attributes
      @inheritable_attributes ||= EMPTY_INHERITABLE_ATTRIBUTES
    end
  end

  unless self.respond_to?(:write_inheritable_attribute)
    def write_inheritable_attribute(key, value)
      if inheritable_attributes.equal?(EMPTY_INHERITABLE_ATTRIBUTES)
        @inheritable_attributes = {}
      end
      inheritable_attributes[key] = value
    end
  end

  unless self.respond_to?(:write_inheritable_hash)
    def write_inheritable_hash(key, hash)
      write_inheritable_attribute(key, {}) if read_inheritable_attribute(key).nil?
      write_inheritable_attribute(key, read_inheritable_attribute(key).merge(hash))
    end
  end

  unless self.respond_to?(:read_inheritable_attribute)
    def read_inheritable_attribute(key)
      inheritable_attributes[key]
    end
  end

  private
    # Prevent this constant from being created multiple times
    EMPTY_INHERITABLE_ATTRIBUTES = {}.freeze unless const_defined?(:EMPTY_INHERITABLE_ATTRIBUTES)

    def inherited_with_inheritable_attributes(child)
      inherited_without_inheritable_attributes(child) if respond_to?(:inherited_without_inheritable_attributes)

      if inheritable_attributes.equal?(EMPTY_INHERITABLE_ATTRIBUTES)
        new_inheritable_attributes = EMPTY_INHERITABLE_ATTRIBUTES
      else
        new_inheritable_attributes = inheritable_attributes.inject({}) do |memo, (key, value)|
          memo.update(key => value.duplicable? ? value.dup : value)
        end
      end

      child.instance_variable_set('@inheritable_attributes', new_inheritable_attributes)
    end

    alias inherited_without_inheritable_attributes inherited
    alias inherited inherited_with_inheritable_attributes
  
end
