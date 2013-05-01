moonshine
=========

Analytics Module

This doesn't work yet.  Just getting the code started.  Will be adding dependencies and crap soon.


Bare bones example:
```ruby
Moonshine.send(id: order.id,
      :type => 'order',
      :time => order.created_at.utc,
      :data => {
        :user_id => "#{order.user_id}", 
        :store_id => "#{order.store_id}", 
        :total => order.total,
        :tax => order.sales_tax,
      }
    )
```

```ruby
Moonshine.get({:start => Time.zone.now.beginning_of_month, :stop => Time.zone.now - 2.weeks, :metric => 'sum', :type => 'order', :key => 'total'})
```

returns:

{Mon, 01 Apr 2013 00:00:00 PDT -07:00=>500.0, Tue, 02 Apr 2013 00:00:00 PDT -07:00=>500.0, Wed, 03 Apr 2013 00:00:00 PDT -07:00=>500.0, Thu, 04 Apr 2013 00:00:00 PDT -07:00=>500.0, Fri, 05 Apr 2013 00:00:00 PDT -07:00=>500.0, Sat, 06 Apr 2013 00:00:00 PDT -07:00=>500.0, Sun, 07 Apr 2013 00:00:00 PDT -07:00=>500.0, Mon, 08 Apr 2013 00:00:00 PDT -07:00=>500.0, Tue, 09 Apr 2013 00:00:00 PDT -07:00=>500.0, 500, 10 Apr 2013 00:00:00 PDT -07:00=>500.0, Thu, 11 Apr 2013 00:00:00 PDT -07:00=>500.0, Fri, 12 Apr 2013 00:00:00 PDT -07:00=>990337.0, Sat, 13 Apr 2013 00:00:00 PDT -07:00=>500.0, Mon, 15 Apr 2013 00:00:00 PDT -07:00=>500.0}
