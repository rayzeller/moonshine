moonshine
=========

Analytics Module

Define a config file for your Model in app/fermenters:
```ruby
class OrderFermenter < Moonshine::Fermenter

  type 'order'
  time :created_at

  data_point :store_id, :distinct => true
  data :user_id, :swipe_fee, :cc_charge
  data_point :sales_tax, :key => :tax, :summed => true
  data_point :total, :summed => true
  data_point :subtotal, :summed => true

  def swipe_fee
    object.calc_swipe 
  end

  def cc_charge
    object.calc_cc_charge
  end

  tag :generic, :if =>  lambda { |object| object.generic == true || object.fake == true}

end
```

Anything you label ```:distinct => true``` can be queried on.
Anything you label ```:summed => true``` will automatically be summed and aggreagated in the background.
Anything you list as a tag can be queried on.  If you don't list any tags, the default tag (which is always added) is ```_all```.

Right now you can query a maximum of one "distinct" event.  You can query multiple tag events, but they are not aggregated together.  One example is classifying multiple types of events:

```
  tag :holiday_order, :if =>  lambda { |object| object.created_at.happens_on_a_holiday}
  tag :power_user_order, :if =>  lambda { |object| object.user.is_a_power_user}
  tag :test_order, :if =>  lambda { |object| object.test?}
```
These are not mutually exclusive.

Include this in your model:
```ruby
include Moonshine::Observer
include Moonshine::Checksum
```

The Observer will automatically send events to Moonshine as a delayed job after they are committed to the DB.  
Including Checksum allows you to do integrity checks against your Moonshine Mongo instance to make sure they are in sync.

Examples:

```
Order.repair(Time.zone.now.beginning_of_day, Time.zone.now)
```
makes sure all orders today have been sent.  If not it will sync them back up.

```
Order.checksum(Time.zone.now.beginning_of_day, Time.zone.now)
```
does a dry run.  It will return a hash of all inconsistencies between Moonshine and your DB.

Retrieving events:

```ruby
start = Time.now.beginning_of_month
stop = Time.now
type = 'order'
only = 'total'
filter_key = 'store_id'
filter_value = '1'
metric = 'all'
tags = ['generic']

options = {:start => start, :stop => stop, :type => type, :only => only, :tags => tags, :metric => metric, :filter_key => filter_key, :filter_value => filter_value}
          
json = Moonshine.bootleg(options)
```

returns:

```
{"generic":
  {
    "2012-10-11T07:00:00+00:00":{"count":49,"total":21300},
    "2012-10-12T07:00:00+00:00":{"count":49,"total":22500}
  }
}
```

etc.
