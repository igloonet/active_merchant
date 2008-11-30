require 'active_merchant/billing/integrations/paypal/masspay_notification_subpayment_methods.rb'

module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    module Integrations #:nodoc:
      module Paypal
        # Parser and handler for incoming MassPay Instant payment notifications from paypal.
        #
        # For an example of how to handle both MassPay IPNs and regular IPNs in your Rails
        # controllers, see the documentation for Notification
        class MasspayNotification < ActiveMerchant::Billing::Integrations::Notification
          include NotificationCommonMethods
          
          PAYMENT_SPECIFIC_KEYS = [
            # A string ending with an underscore and a 1-3 digit number (ie. mc_gross_123)
            /(.*)_\d{1,3}/]
          DISALLOWED_PAYMENT_KEYS = ['verify_sign']
          
          # Returns the email address of the account that initiated this MassPay transaction.
          def account
            params['payer_email']
          end
          
          # Returns the currency code that payments were made in.
          # All payments in a MassPay transaction must be made in the same currency.
          def currency
            @currency ||= payments[0].currency if payments.length > 0
          end
          
          # Returns the sum of each payment's fee.
          def fee
            @fee ||= (payments.length > 0 ? payments.inject(0){|sum, p| sum + p.fee_cents} / 100.0 : 0)
          end
          
          # Returns the sum of each payment's gross.
          def gross
            @gross ||= (payments.length > 0 ? payments.inject(0){|sum, p| sum + p.gross_cents} / 100.0 : 0)
          end
          
          # Returns an array of instances of Paypal::Notification, one for each payment in the MassPay transaction.
          #
          # The Paypal::Notifications returned inherit the methods in MasspayNotificationSubpaymentMethods, and 
          # call the acknowledge method of the original MassPay notification when their acknowledge methods are called.
          def payments
            @payments ||= parse_params_into_payments
          end

          
          private
                    
          def payment_specific_params
            @payment_specific_params ||= @params.reject{|key, value| !is_payment_specific_param?(key)}
          end
          
          def payment_global_params
            @payment_global_params ||= @params.reject{|key, value| !is_payment_global_param?(key)}.merge({'txn_type' => 'masspay_subpayment'})
          end
          
          def parse_params_into_payments
            # Collect a list of transactions and their keys
            #
            # {:masspay_txn_id_1 => 'ABCD', :masspay_txn_id_2 => 'EFGH'...:masspay_txn_id_n => 'WXYZ'}
            # ...turns into...
            # [1,2...n]
            transaction_keys = payment_specific_params.collect{|key, value| 
              match = /masspay_txn_id_(\d{1,3})/.match(key)
              match[1] if match
            }.compact
            
            # For each found transaction, reconstruct a Paypal::Notification
            payments = transaction_keys.collect{|transaction_number|
              simulated_post = PostData.new
              
              params_for_this_transaction = payment_specific_params.reject{|key,value| /_#{transaction_number}$/.match(key).nil?}
              params_for_this_transaction.each_pair{|key, value|
                simulated_post[key.sub(/_\d{1,3}/,'')] = value
              }
              simulated_post.merge!(payment_global_params)
              
              reconstruct_notification_from_post(simulated_post)
            }
            
            # Return the array of Paypal::Notification instances
            payments
          end
          
          def reconstruct_notification_from_post(post)
            reconstructed_notification = Paypal.notification(post.to_post_data)
            subpaymentify_notification!(reconstructed_notification)
            
            reconstructed_notification
          end
          
          def subpaymentify_notification!(notification)
            parent_acknowledge = class << self; self end.send(:instance_method, :acknowledge)
            parent_notification = self
            
            singleton_class = (class << notification; self end)
            singleton_class.send(:define_method, :acknowledge) { parent_acknowledge.bind(parent_notification).call }
            singleton_class.send(:include, MasspayNotificationSubpaymentMethods)
          end
          
          def is_payment_specific_param?(key)
            PAYMENT_SPECIFIC_KEYS.find{|k| k.match(key)} ? true : false
          end
          
          def is_payment_global_param?(key)
            (DISALLOWED_PAYMENT_KEYS.find{|k| k.match(key)} or PAYMENT_SPECIFIC_KEYS.find{|k| k.match(key)}) ? false : true
          end
          
          def validate_ipn_type
            raise UnsupportedPostDataError.new("IPN is of txn_type \"#{type}\". This class supports IPNs of txn_type \"masspay\" only.") if !type.nil? and type.downcase.to_sym != :masspay
          end
        end
      end
    end
  end
end
