module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    module Integrations #:nodoc:
      module Paypal
        # This module is included in subpayments of a MassPay notification
        module MasspayNotificationSubpaymentMethods
                 
          # Returns the unique_id of the given MassPay subpayment   
          def unique_id
            params['unique_id']
          end
          
        end
      end
    end
  end
end


