class Module
  unless respond_to?(:mattr_reader)
    def mattr_reader(*syms)
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

  unless respond_to?(:mattr_writer)
    def mattr_writer(*syms)
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
      end
    end
  end

  unless respond_to?(:mattr_accessor)
    def mattr_accessor(*syms)
      mattr_reader(*syms)
      mattr_writer(*syms)
    end
  end
end
