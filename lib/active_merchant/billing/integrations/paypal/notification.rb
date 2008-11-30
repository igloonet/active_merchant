module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    module Integrations #:nodoc:
      module Paypal
        # Parser and handler for incoming Instant payment notifications from paypal. 
        # The Example shows a typical handler in a rails application. Note that this
        # is an example, please read the Paypal API documentation for all the details
        # on creating a safe payment controller.
        #
        # Example
        #  
        #   class BackendController < ApplicationController
        #     include ActiveMerchant::Billing::Integrations
        #
        #     def paypal_ipn
        #       begin
        #         # Handle regular IPN
        #         notify = Paypal::Notification.new(request.raw_post)
        #         invoice = Invoice.find(notify.item_id)
        #         receive_invoice_payment(notify, invoice) if notify.acknowledge
        #       rescue Notification::UnsupportedPostDataError # thrown if the raw_post was from a masspay IPN
        #         # Handle MassPay IPN
        #         notify = Paypal::MasspayNotification.new(request.raw_post)
        #         bill_ids = notify.payments.collect{|p| p.unique_id}
        #         bills = Bill.find_all_by_id(bill_ids)
        #         make_bill_payments(notify, bills) if notify.acknowledge
        #       end
        #     
        #       render :nothing
        #     end
        #
        #     def receive_invoice_payment(notify, invoice)
        #       if notify.complete? and invoice.total == notify.amount
        #         invoice.update_attribute(:status, 'paid')
        #       else
        #         # raise invoice payment errors
        #       end
        #     end
        #
        #     def make_bill_payments(notify, bills)
        #       if notify.complete? and bills.inject(0){|sum, b| sum + b.total} == notify.amount
        #         bills.each {|b| b.update_attribute(:status, 'paid') }
        #       else
        #         # raise bill payment errors
        #       end
        #     end
        #   
        #   end
        class Notification < ActiveMerchant::Billing::Integrations::Notification
          include NotificationCommonMethods

          # Id of this transaction (paypal number)
          def transaction_id
            params['txn_id']
          end

          # the money amount we received in X.2 decimal.
          def gross
            params['mc_gross']
          end

          # the markup paypal charges for the transaction
          def fee
            params['mc_fee']
          end
          
          # the markup paypal charges for the transaction, in cents
          def fee_cents
            (fee.to_f * 100.0).round
          end

          # What currency have we been dealing with
          def currency
            params['mc_currency']
          end

          # This is the item number which we submitted to paypal 
          # The custom field is also mapped to item_id because PayPal
          # doesn't return item_number in dispute notifications
          def item_id
            params['item_number'] || params['custom']
          end

          # This is the invoice which you passed to paypal 
          def invoice
            params['invoice']
          end   
          
          def account
            params['business'] || params['receiver_email']
          end
          
          
          private
          
          def validate_ipn_type
            raise UnsupportedPostDataError.new("This class does not support IPNs of txn_type \"masspay\". Please instantiate a Paypal::MasspayNotification instead.") if !type.nil? and type.downcase.to_sym == :masspay
          end
        end
      end
    end
  end
end
