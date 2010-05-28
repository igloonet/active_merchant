require 'digest/md5'

module ActiveMerchant #:nodoc:
  module Utils #:nodoc:
    def generate_unique_id
      md5 = Digest::MD5.new
      now = Time.now
      md5 << now.to_s
      md5 << String(now.usec)
      md5 << String(rand(0))
      md5 << String($$)
      md5 << self.class.name
      md5.hexdigest
    end
    
    module_function :generate_unique_id    
    
    # convert string to camel case
    def self.camelize(lower_case_and_underscored_word, first_letter_in_uppercase = true)
      lower_case_and_underscored_word.to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
    end
    
  end
end