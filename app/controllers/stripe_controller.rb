class StripeController < ApplicationController
  before_filter :umi_authenticate_token!

  @@service = "stripe"

  def received
    data = Cloudfuji::Utils.normalize_keys(params)

    p data

    method = data[:type].split(".")[0..-2].join("_").to_sym
    event  = self.send(method, data)
    event[:user_ido_id] = current_user.ido_id

    puts event.inspect

    Cloudfuji::Event.publish(event)

    render :json => "OK"
  end

  private

  def events
    {
      "charge"                => ["failed", "succeeded", "refunded", "disputed"],
      "customer"              => ["created", "updated", "deleted"],
      "customer.subscription" => ["created", "updated", "deleted", "trial_will_end"],
      "customer.discount"     => ["created", "updated", "deleted"],
      "invoice"               => ["created", "updated", "payment_succeeded", "payment_failed"],
      "invoiceitem"           => ["created", "updated", "deleted"],
      "plan"                  => ["created", "updated", "deleted"],
      "coupon"                => ["created", "updated", "deleted"],
      "transfer"              => ["created", "failed"],
      "ping"                  => []
    }
  end

  # Charge
  # charge.refunded  {:type=>"charge.refunded",  :data=>{:object=>{:currency=>"usd", :amount=>100, :description=>"description", :card=>{:country=>nil, :exp_month=>1, :id=>"cc_00000000000000", :object=>"card", :last4=>"4242", :exp_year=>2012, :type=>"Visa"}, :id=>"ch_00000000000000", :paid=>true, :object=>"charge", :created=>1327102285, :livemode=>false, :refunded=>true, :fee=>0}}, :livemode=>false, :created=>1326853478, :id=>"note_00000000000000"}
  # charge.succeeded {:type=>"charge.succeeded", :data=>{:object=>{:currency=>"usd", :amount=>100, :description=>"description", :card=>{:country=>nil, :exp_month=>1, :id=>"cc_00000000000000", :object=>"card", :last4=>"4242", :exp_year=>2012, :type=>"Visa"}, :id=>"ch_00000000000000", :paid=>true, :object=>"charge", :created=>1327102285, :livemode=>false, :refunded=>false, :fee=>nil}}, :livemode=>false, :created=>1326853478, :id=>"note_00000000000000"}
  # charge.failed    {:type=>"charge.failed",    :data=>{:object=>{:currency=>"usd", :amount=>100, :description=>"description", :card=>{:country=>nil, :exp_month=>1, :id=>"cc_00000000000000", :object=>"card", :last4=>"0002", :exp_year=>2012, :type=>"Visa"}, :id=>"ch_00000000000000", :paid=>false, :object=>"charge", :created=>1327102285, :livemode=>false, :refunded=>false, :fee=>nil}}, :livemode=>false, :created=>1326853478, :id=>"note_00000000000000"}
  # charge.disputed  {:type=>"charge.disputed",  :data=>{:object=>{:currency=>"usd", :amount=>100, :description=>"description", :card=>{:country=>nil, :exp_month=>1, :id=>"cc_00000000000000", :object=>"card", :last4=>"4242", :exp_year=>2012, :type=>"Visa"}, :id=>"ch_00000000000000", :paid=>true, :object=>"charge", :created=>1327102285, :livemode=>false, :refunded=>false, :fee=>nil}}, :livemode=>false, :created=>1326853478, :id=>"note_00000000000000"}
  def charge(event)
    data = event[:data]
    charge = data[:object]
    category, name = event[:type].split(".")
    human = "#{category.titleize} #{name.upcase} in the amount of $#{charge[:amount]} wth a fee of $#{charge[:fee]}: '#{charge[:description]}"
    {
      :category => category,
      :name => name,
      :data => charge.merge({:human => human})
    }
  end

  # Coupon
  # coupon.created {:type=>"coupon.created", :data=>{:object=>{:times_redeemed=>0, :percent_off=>15, :duration=>"once", :livemode=>false, :object=>"coupon", :id=>"15OFF"}}, :livemode=>false, :created=>1326853478, :id=>"note_00000000000000"}
  # coupon.deleted {:type=>"coupon.deleted", :data=>{:object=>{:times_redeemed=>0, :percent_off=>15, :duration=>"once", :livemode=>false, :object=>"coupon", :id=>"15OFF"}}, :livemode=>false, :created=>1326853478, :id=>"note_00000000000000"}
  def coupon(event)
    data   = event[:data]
    coupon = data[:object]
    category, name = event[:type].split(".")
    human = "#{category.titleize} #{name.upcase} (#{coupon[:id]}), #{coupon[:percent_off]}% off for #{coupon[:duration]}, redeemed #{coupon[:times_redeemed]} times"
    {
      :category => category,
      :name => name,
      :data => coupon.merge({:human => human})
    }
  end

  # Customer
  # customer.created {:type=>"customer.created", :data=>{:object=>{:created=>1326853478, :livemode=>false, :object=>"customer", :id=>"cus_00000000000000", :email=>"webhook-test@stripe.com"}}, :livemode=>false, :created=>1326853478, :id=>"note_00000000000000", :action=>"received", :controller=>"stripes", :stripe=>{:type=>"customer.created", :data=>{:object=>{:created=>1326853478, :livemode=>false, :object=>"customer", :id=>"cus_00000000000000", :email=>"webhook-test@stripe.com"}}, :livemode=>false, :created=>1326853478, :id=>"note_00000000000000"}}
  # customer.updated {:type=>"customer.updated", :data=>{:object=>{:created=>1327099721, :livemode=>false, :description=>"new description", :object=>"customer", :id=>"cus_00000000000000", :email=>"webhook-test@stripe.com"}, :previous_attributes=>{:description=>nil}}, :livemode=>false, :created=>1326853478, :id=>"note_00000000000000", :action=>"received", :controller=>"stripes", :stripe=>{:type=>"customer.updated", :data=>{:object=>{:created=>1327099721, :livemode=>false, :description=>"new description", :object=>"customer", :id=>"cus_00000000000000", :email=>"webhook-test@stripe.com"}, :previous_attributes=>{:description=>nil}}, :livemode=>false, :created=>1326853478, :id=>"note_00000000000000"}}
  # customer.deleted {:type=>"customer.deleted", :data=>{:object=>{:created=>1327099721, :livemode=>false, :description=>"new description", :object=>"customer", :deleted=>true, :id=>"cus_00000000000000", :email=>"webhook-test@stripe.com"}}, :livemode=>false, :created=>1326853478, :id=>"note_00000000000000", :action=>"received", :controller=>"stripes", :stripe=>{:type=>"customer.deleted", :data=>{:object=>{:created=>1327099721, :livemode=>false, :description=>"new description", :object=>"customer", :deleted=>true, :id=>"cus_00000000000000", :email=>"webhook-test@stripe.com"}}, :livemode=>false, :created=>1326853478, :id=>"note_00000000000000"}}
  def customer(event)
    data   = event[:data]
    customer = data[:object]
    category, name = event[:type].split(".")
    human = "#{category.titleize} #{name.upcase} (#{customer[:id]}), #{customer[:email]}"
    {
      :category => category,
      :name => name,
      :data => customer.merge({:human => human})
    }
  end

  # Customer Discount
  # customer.discount.created {:type=>"customer.discount.created", :data=>{:object=>{:coupon=>{:times_redeemed=>1, :percent_off=>10, :duration=>"once", :livemode=>false, :object=>"coupon", :id=>"10OFF"}, :start=>1327102084, :object=>"discount", :id=>"di_00000000000000", :end=>1329780484}}, :livemode=>false, :created=>1326853478, :id=>"note_00000000000000", :action=>"received", :controller=>"stripes", :stripe=>{:type=>"customer.discount.created", :data=>{:object=>{:coupon=>{:times_redeemed=>1, :percent_off=>10, :duration=>"once", :livemode=>false, :object=>"coupon", :id=>"10OFF"}, :start=>1327102084, :object=>"discount", :id=>"di_00000000000000", :end=>1329780484}}, :livemode=>false, :created=>1326853478, :id=>"note_00000000000000"}}
  # customer.discount.updated {:type=>"customer.discount.updated", :data=>{:object=>{:coupon=>{:times_redeemed=>1, :percent_off=>5, :duration=>"once", :livemode=>false, :object=>"coupon", :id=>"5OFF"}, :start=>1327102090, :object=>"discount", :id=>"di_00000000000000", :end=>1329780490}, :previous_attributes=>{:coupon=>{:times_redeemed=>1, :percent_off=>10, :duration=>"once", :livemode=>false, :object=>"coupon", :id=>"10OFF"}, :start=>1327102084, :id=>"di_00000000000000", :end=>1329780484}}, :livemode=>false, :created=>1326853478, :id=>"note_00000000000000", :action=>"received", :controller=>"stripes", :stripe=>{:type=>"customer.discount.updated", :data=>{:object=>{:coupon=>{:times_redeemed=>1, :percent_off=>5, :duration=>"once", :livemode=>false, :object=>"coupon", :id=>"5OFF"}, :start=>1327102090, :object=>"discount", :id=>"di_00000000000000", :end=>1329780490}, :previous_attributes=>{:coupon=>{:times_redeemed=>1, :percent_off=>10, :duration=>"once", :livemode=>false, :object=>"coupon", :id=>"10OFF"}, :start=>1327102084, :id=>"di_00000000000000", :end=>1329780484}}, :livemode=>false, :created=>1326853478, :id=>"note_00000000000000"}}
  # customer.discount.deleted {:type=>"customer.discount.deleted", :data=>{:object=>{:start=>1327102084, :id=>"di_00000000000000", :object=>"discount", :end=>1329780484, :coupon=>{:duration=>"once", :id=>"10OFF", :percent_off=>10, :object=>"coupon", :livemode=>false, :times_redeemed=>1}}}, :livemode=>false, :created=>1326853478, :id=>"note_00000000000000", :action=>"received", :controller=>"stripes", :stripe=>{:type=>"customer.discount.deleted", :data=>{:object=>{:start=>1327102084, :id=>"di_00000000000000", :object=>"discount", :end=>1329780484, :coupon=>{:duration=>"once", :id=>"10OFF", :percent_off=>10, :object=>"coupon", :livemode=>false, :times_redeemed=>1}}}, :livemode=>false, :created=>1326853478, :id=>"note_00000000000000"}}
  def customer_discount(event)
    data              = event[:data]
    customer_discount = data[:object]
    category, sub, name = event[:type].split(".")
    category = "#{category} #{sub}"
    human = "#{category.titleize} #{name.upcase} (#{customer_discount[:id]}), #{customer_discount[:coupon][:percent_off]}% off for #{customer_discount[:coupon][:duration]}, redeemed #{customer_discount[:coupon][:times_redeemed]} times"
    {
      :category => category,
      :name     => name,
      :data     => customer_discount.merge({:human => human})
    }
  end

  # Customer Subscription
  # customer.subscription.created        {:type=>"customer.subscription.created",        :data=>{:object=>{:start=>1327101120, :customer=>"cus_00000000000000", :plan=>{:interval=>"month", :currency=>"usd", :amount=>999, :id=>"plan", :name=>"New Plan", :object=>"plan", :livemode=>false}, :status=>"active", :object=>"subscription", :current_period_end=>1329779520, :current_period_start=>1327101120}}, :livemode=>false, :created=>1326853478, :id=>"note_00000000000000", :action=>"received", :controller=>"stripes", :stripe=>{:type=>"customer.subscription.created", :data=>{:object=>{:start=>1327101120, :customer=>"cus_00000000000000", :plan=>{:interval=>"month", :currency=>"usd", :amount=>999, :id=>"plan", :name=>"New Plan", :object=>"plan", :livemode=>false}, :status=>"active", :object=>"subscription", :current_period_end=>1329779520, :current_period_start=>1327101120}}, :livemode=>false, :created=>1326853478, :id=>"note_00000000000000"}}
  # customer.subscription.updated        {:type=>"customer.subscription.updated",        :data=>{:previous_attributes=>{:start=>1327101120, :plan=>{:interval=>"month", :currency=>"usd", :amount=>999, :id=>"plan", :name=>"New Plan", :object=>"plan", :livemode=>false}}, :object=>{:start=>1327101170, :customer=>"cus_PJgjMGxt8e018U", :plan=>{:interval=>"month", :currency=>"usd", :amount=>999, :id=>"other_plan", :name=>"Other Plan", :object=>"plan", :livemode=>false}, :status=>"active", :object=>"subscription", :current_period_end=>1329779520, :current_period_start=>1327101120}}, :livemode=>false, :created=>1326853478, :id=>"note_00000000000000", :action=>"received", :controller=>"stripes", :stripe=>{:type=>"customer.subscription.updated", :data=>{:previous_attributes=>{:start=>1327101120, :plan=>{:interval=>"month", :currency=>"usd", :amount=>999, :id=>"plan", :name=>"New Plan", :object=>"plan", :livemode=>false}}, :object=>{:start=>1327101170, :customer=>"cus_PJgjMGxt8e018U", :plan=>{:interval=>"month", :currency=>"usd", :amount=>999, :id=>"other_plan", :name=>"Other Plan", :object=>"plan", :livemode=>false}, :status=>"active", :object=>"subscription", :current_period_end=>1329779520, :current_period_start=>1327101120}}, :livemode=>false, :created=>1326853478, :id=>"note_00000000000000"}}
  # customer.subscription.deleted        {:type=>"customer.subscription.deleted",        :data=>{:object=>{:canceled_at=>1327101174, :customer=>"cus_00000000000000", :current_period_end=>1329779520, :start=>1327101170, :object=>"subscription", :current_period_start=>1327101120, :plan=>{:amount=>999, :livemode=>false, :interval=>"month", :object=>"plan", :id=>"other_plan", :name=>"Other Plan", :currency=>"usd"}, :status=>"canceled", :ended_at=>1327101174}}, :livemode=>false, :created=>1326853478, :id=>"note_00000000000000", :action=>"received", :controller=>"stripes", :stripe=>{:type=>"customer.subscription.deleted", :data=>{:object=>{:canceled_at=>1327101174, :customer=>"cus_00000000000000", :current_period_end=>1329779520, :start=>1327101170, :object=>"subscription", :current_period_start=>1327101120, :plan=>{:amount=>999, :livemode=>false, :interval=>"month", :object=>"plan", :id=>"other_plan", :name=>"Other Plan", :currency=>"usd"}, :status=>"canceled", :ended_at=>1327101174}}, :livemode=>false, :created=>1326853478, :id=>"note_00000000000000"}}
  # customer.subscription.trial_will_end {:type=>"customer.subscription.trial_will_end", :data=>{:object=>{:start=>1327101120, :customer=>"cus_00000000000000", :plan=>{:interval=>"month", :currency=>"usd", :amount=>999, :id=>"plan", :name=>"New Plan", :object=>"plan", :livemode=>false}, :status=>"active", :object=>"subscription", :current_period_end=>1329779520, :current_period_start=>1327101120}}, :livemode=>false, :created=>1326853478, :id=>"note_00000000000000", :action=>"received", :controller=>"stripes", :stripe=>{:type=>"customer.subscription.trial_will_end", :data=>{:object=>{:start=>1327101120, :customer=>"cus_00000000000000", :plan=>{:interval=>"month", :currency=>"usd", :amount=>999, :id=>"plan", :name=>"New Plan", :object=>"plan", :livemode=>false}, :status=>"active", :object=>"subscription", :current_period_end=>1329779520, :current_period_start=>1327101120}}, :livemode=>false, :created=>1326853478, :id=>"note_00000000000000"}}
  def customer_subscription(event)
    data           = event[:data]
    subscription   = data[:object]
    category, sub, name = event[:type].split(".")
    category = "#{category} #{sub}"
    human = "#{category.titleize} #{name.upcase} (#{subscription[:customer]}) on plan #{subscription[:plan][:name]} for $#{subscription[:plan][:amount]}/#{subscription[:plan][:interval]}"
    {
      :category => category,
      :name     => name,
      :data     => subscription.merge({:human => human})
    }
  end

  # Invoice
  # invoice.created           {:type=>"invoice.created",           :data=>{:object=>{:next_payment_attempt=>1327101120, :date=>1327101120, :customer=>"cus_00000000000000", :attempted=>false, :lines=>{:subscriptions=>[{:amount=>999, :period=>{:start=>1327101120, :end=>1329779520}, :plan=>{:amount=>999, :livemode=>false, :interval=>"month", :object=>"plan", :id=>"plan", :name=>"New Plan", :currency=>"usd"}}]}, :livemode=>false, :closed=>false, :object=>"invoice", :id=>"in_00000000000000", :paid=>false, :subtotal=>999, :period_end=>1327101120, :total=>999, :period_start=>1327101120, :attempt_count=>0}}, :livemode=>false, :created=>1326853478, :id=>"note_00000000000000", :action=>"received", :controller=>"stripes", :stripe=>{:type=>"invoice.created", :data=>{:object=>{:next_payment_attempt=>1327101120, :date=>1327101120, :customer=>"cus_00000000000000", :attempted=>false, :lines=>{:subscriptions=>[{:amount=>999, :period=>{:start=>1327101120, :end=>1329779520}, :plan=>{:amount=>999, :livemode=>false, :interval=>"month", :object=>"plan", :id=>"plan", :name=>"New Plan", :currency=>"usd"}}]}, :livemode=>false, :closed=>false, :object=>"invoice", :id=>"in_00000000000000", :paid=>false, :subtotal=>999, :period_end=>1327101120, :total=>999, :period_start=>1327101120, :attempt_count=>0}}, :livemode=>false, :created=>1326853478, :id=>"note_00000000000000"}}
  # invoice.updated           {:type=>"invoice.updated",           :data=>{:object=>{:date=>1327108539, :customer=>"cus_00000000000000", :attempted=>true, :lines=>{:invoiceitems=>[{:amount=>1500, :date=>1327108499, :customer=>"cus_00000000000000", :invoice=>"in_00000000000000", :livemode=>false, :object=>"invoiceitem", :id=>"ii_00000000000000", :currency=>"usd"}]}, :livemode=>false, :closed=>true, :object=>"invoice", :id=>"in_00000000000000", :paid=>true, :subtotal=>1500, :period_end=>1327193179, :charge=>"ch_00000000000000", :total=>1500, :period_start=>1327106779, :attempt_count=>1}, :previous_attributes=>{:attempted=>false, :closed=>false, :paid=>false, :charge=>nil}}, :livemode=>false, :created=>1326853478, :id=>"note_00000000000000", :action=>"received", :controller=>"stripes", :stripe=>{:type=>"invoice.updated", :data=>{:object=>{:date=>1327108539, :customer=>"cus_00000000000000", :attempted=>true, :lines=>{:invoiceitems=>[{:amount=>1500, :date=>1327108499, :customer=>"cus_00000000000000", :invoice=>"in_00000000000000", :livemode=>false, :object=>"invoiceitem", :id=>"ii_00000000000000", :currency=>"usd"}]}, :livemode=>false, :closed=>true, :object=>"invoice", :id=>"in_00000000000000", :paid=>true, :subtotal=>1500, :period_end=>1327193179, :charge=>"ch_00000000000000", :total=>1500, :period_start=>1327106779, :attempt_count=>1}, :previous_attributes=>{:attempted=>false, :closed=>false, :paid=>false, :charge=>nil}}, :livemode=>false, :created=>1326853478, :id=>"note_00000000000000"}}
  # invoice.payment_succeeded {:type=>"invoice.payment_succeeded", :data=>{:object=>{:next_payment_attempt=>nil, :period_end=>1327101120, :period_start=>1327101120, :attempt_count=>1, :lines=>{:subscriptions=>[{:amount=>999, :plan=>{:interval=>"month", :currency=>"usd", :amount=>999, :id=>"plan", :name=>"New Plan", :object=>"plan", :livemode=>false}, :period=>{:start=>1327101120, :end=>1329779520}}]}, :id=>"in_00000000000000", :paid=>true, :customer=>"cus_00000000000000", :closed=>true, :total=>999, :charge=>"ch_00000000000000", :object=>"invoice", :subtotal=>999, :livemode=>false, :attempted=>true, :date=>1327101120}}, :livemode=>false, :created=>1326853478, :id=>"note_00000000000000", :action=>"received", :controller=>"stripes", :stripe=>{:type=>"invoice.payment_succeeded", :data=>{:object=>{:next_payment_attempt=>nil, :period_end=>1327101120, :period_start=>1327101120, :attempt_count=>1, :lines=>{:subscriptions=>[{:amount=>999, :plan=>{:interval=>"month", :currency=>"usd", :amount=>999, :id=>"plan", :name=>"New Plan", :object=>"plan", :livemode=>false}, :period=>{:start=>1327101120, :end=>1329779520}}]}, :id=>"in_00000000000000", :paid=>true, :customer=>"cus_00000000000000", :closed=>true, :total=>999, :charge=>"ch_00000000000000", :object=>"invoice", :subtotal=>999, :livemode=>false, :attempted=>true, :date=>1327101120}}, :livemode=>false, :created=>1326853478, :id=>"note_00000000000000"}}
  # invoice.payment_failed    {:type=>"invoice.payment_failed",    :data=>{:object=>{:period_end=>1327101120, :period_start=>1327101120, :attempt_count=>2, :lines=>{:subscriptions=>[{:amount=>999, :plan=>{:interval=>"month", :currency=>"usd", :amount=>999, :id=>"plan", :name=>"New Plan", :object=>"plan", :livemode=>false}, :period=>{:start=>1327101120, :end=>1329779520}}]}, :id=>"in_00000000000000", :paid=>false, :customer=>"cus_00000000000000", :closed=>true, :total=>999, :charge=>"ch_00000000000000", :object=>"invoice", :subtotal=>999, :livemode=>false, :attempted=>true, :date=>1327101120}}, :livemode=>false, :created=>1326853478, :id=>"note_00000000000000", :action=>"received", :controller=>"stripes", :stripe=>{:type=>"invoice.payment_failed", :data=>{:object=>{:period_end=>1327101120, :period_start=>1327101120, :attempt_count=>2, :lines=>{:subscriptions=>[{:amount=>999, :plan=>{:interval=>"month", :currency=>"usd", :amount=>999, :id=>"plan", :name=>"New Plan", :object=>"plan", :livemode=>false}, :period=>{:start=>1327101120, :end=>1329779520}}]}, :id=>"in_00000000000000", :paid=>false, :customer=>"cus_00000000000000", :closed=>true, :total=>999, :charge=>"ch_00000000000000", :object=>"invoice", :subtotal=>999, :livemode=>false, :attempted=>true, :date=>1327101120}}, :livemode=>false, :created=>1326853478, :id=>"note_00000000000000"}}
  def invoice(event)
    data           = event[:data]
    invoice        = data[:object]
    category, name = event[:type].split(".")
    human          = "#{category.titleize} #{name.upcase} (#{invoice[:id]})"

    {
      :category => category,
      :name     => name,
      :data     => invoice.merge({:human => human})
    }
  end

  # Invoice Item
  # invoiceitem.created {:type=>"invoiceitem.created", :data=>{:object=>{:amount=>-999, :date=>1327101170, :customer=>"cus_00000000000000", :livemode=>false, :description=>"description", :object=>"invoiceitem", :id=>"ii_00000000000000", :currency=>"usd"}}, :livemode=>false, :created=>1326853478, :id=>"note_00000000000000"}
  # invoiceitem.updated {:type=>"invoiceitem.updated", :data=>{:object=>{:amount=>1000, :date=>1327101894, :customer=>"cus_00000000000000", :livemode=>false, :object=>"invoiceitem", :id=>"ii_00000000000000", :currency=>"usd"}, :previous_attributes=>{:amount=>500}}, :livemode=>false, :created=>1326853478, :id=>"note_00000000000000"}
  # invoiceitem.deleted {:type=>"invoiceitem.deleted", :data=>{:object=>{:currency=>"usd", :amount=>-999, :description=>"description", :id=>"ii_00000000000000", :customer=>"cus_00000000000000", :object=>"invoiceitem", :livemode=>false, :date=>1327101170}}, :livemode=>false, :created=>1326853478, :id=>"note_00000000000000"}
  def invoiceitem(event)
    data           = event[:data]
    item           = data[:object]
    category, name = event[:type].split(".")
    human          = "#{category.titleize} #{name.upcase} (#{item[:id]}) for #{item[:amount]} #{item[:currency].upcase} on #{item[:date]} charged to customer #{item[:customer]}: #{item[:description]}"

    {
      :category => category,
      :name     => name,
      :data     => item.merge({:human => human})
    }
  end

  # Plan
  # plan.created {:type=>"plan.created", :data=>{:object=>{:interval=>"month", :currency=>"usd", :amount=>999, :id=>"plan", :name=>"New Plan", :object=>"plan", :livemode=>false}}, :livemode=>false, :created=>1326853478, :id=>"note_00000000000000"}
  # plan.updated {:type=>"plan.updated", :data=>{:previous_attributes=>{:name=>"New Plan"}, :object=>{:interval=>"month", :currency=>"usd", :amount=>999, :id=>"plan", :name=>"Updated Plan", :object=>"plan", :livemode=>false}}, :livemode=>false, :created=>1326853478, :id=>"note_00000000000000"}
  # plan.deleted {:type=>"plan.deleted", :data=>{:object=>{:interval=>"month", :currency=>"usd", :amount=>999, :id=>"plan", :name=>"Updated Plan", :object=>"plan", :livemode=>false}}, :livemode=>false, :created=>1326853478, :id=>"note_00000000000000"}
  def plan(event)
    data           = event[:data]
    plan           = data[:object]
    category, name = event[:type].split(".")
    human          = "#{category.titleize} '#{plan[:name]}' #{name.upcase} (#{plan[:id]}) for #{plan[:amount]} #{plan[:currency].upcase}/#{plan[:interval]}"

    {
      :category => category,
      :name => name,
      :data => plan.merge({:human => human})
    }
  end

  def transfer
    data           = event[:data]
    transfer       = data[:object]
    category, name = event[:type].split(".")
    human          = "#{category.titleize} #{name.upcase} (#{transfer[:status]}) for #{transfer[:amount] / 100.0 }"

    {
      :category => category,
      :name => name,
      :data => plan.merge({:human => human})
    }

  end
end

