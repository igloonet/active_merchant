module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    module Integrations #:nodoc:
      module Paypal
        # This module is included in both Notification and MasspayNotification
        module NotificationCommonMethods
                    
          def self.included(mod) #:nodoc:
            mod.send(:include, PostsData)
            mod.send(:alias_method_chain, :parse, :ipn_validation)
          end
          
          # Was the transaction complete?
          def complete?
            status == "Completed"
          end

          # When was this payment received by the client. 
          # sometimes it can happen that we get the notification much later. 
          # One possible scenario is that our web application was down. In this case paypal tries several 
          # times an hour to inform us about the notification
          def received_at
            Time.parse params['payment_date']
          end
          
          # Status of transaction.
          #
          # List of possible values for single transactions:
          # <tt>Canceled-Reversal</tt>::
          # <tt>Completed</tt>::
          # <tt>Denied</tt>::
          # <tt>Expired</tt>::
          # <tt>Failed</tt>::
          # <tt>In-Progress</tt>::
          # <tt>Partially-Refunded</tt>::
          # <tt>Pending</tt>::
          # <tt>Processed</tt>::
          # <tt>Refunded</tt>::
          # <tt>Reversed</tt>::
          # <tt>Voided</tt>::
          #
          # List of possible values for MassPay transactions:
          # <tt>Completed</tt>::
          # <tt>Denied</tt>::
          # <tt>Processed</tt>::
          #
          # List of possible values for sub-transactions of a MassPay transaction:
          # <tt>Completed</tt>::
          # <tt>Failed</tt>::
          # <tt>Reversed</tt>::
          # <tt>Unclaimed</tt>::
          def status
            params['status'] || params['payment_status']
          end
          
          # What type of transaction are we dealing with?
          def type
            params['txn_type']
          end
          
          # Was this a test transaction?
          def test?
            params['test_ipn'] == '1'
          end
          
          # Acknowledge the transaction to paypal. This method has to be called after a new 
          # ipn arrives. Paypal will verify that all the information we received are correct and will return a 
          # ok or a fail.
          #
          # The return value from this method is memoized; it querys PayPal's servers only once, storing
          # the result, and returning the stored result upon subsequent invocations.
          # 
          # Example:
          # 
          #   def paypal_ipn
          #     notify = Paypal.notification(request.raw_post)
          #
          #     if notify.acknowledge 
          #       ... process order ... if notify.complete?
          #     else
          #       ... log possible hacking attempt ...
          #     end
          def acknowledge
            return @acknowledgement unless @acknowledgement.nil?
            @acknowledgement = request_acknowledgement
          end
          
          
          private
          
          def request_acknowledgement
            payload =  raw

            response = ssl_post(Paypal.service_url + '?cmd=_notify-validate', payload, 
              'Content-Length' => "#{payload.size}",
              'User-Agent'     => "Active Merchant -- http://activemerchant.org"
            )

            raise StandardError.new("Faulty paypal result: #{response}") unless ["VERIFIED", "INVALID"].include?(response)

            response == "VERIFIED"
          end
          
          def parse_with_ipn_validation(post)
            parse_without_ipn_validation(post)
            validate_ipn_type
          end
        end
      end
    end
  end
end


