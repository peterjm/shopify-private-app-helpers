GOOGLE_CHART_ORDERS_BY_HOUR_JS = <<-JAVASCRIPT
  google.charts.load('current', {packages: ['corechart', 'bar']});
  google.charts.setOnLoadCallback(drawMultSeries);

  function drawMultSeries() {
    var data = new google.visualization.DataTable();
    data.addColumn('timeofday', 'Time of Day');
    data.addColumn('number', 'Monday');
    data.addColumn('number', 'Tuesday');
    data.addColumn('number', 'Wednesday');
    data.addColumn('number', 'Thursday');
    data.addColumn('number', 'Friday');
    data.addColumn('number', 'Saturday');
    data.addColumn('number', 'Sunday');

    data.addRows([
      ROWS_GO_HERE
    ]);

    var options = {
      title: 'Orders Throughout the Day',
      hAxis: {
        title: 'Time of Day',
        format: 'h:mm a',
        viewWindow: {
          min: [7, 0, 0],
          max: [19, 00, 0]
        }
      },
      vAxis: {
        title: 'Number of Orders'
      }
    };

    var chart = new google.visualization.ColumnChart(document.getElementById('chart_div'));
    chart.draw(data, options);
  }
JAVASCRIPT

def orders_by_day_and_hour(orders)
  orders_by_day = orders.group_by { |o| DateTime.parse(o.created_at).cwday }
  orders_by_day_and_hour = orders_by_day.inject({}) { |h, (day, ogroup)|
    h[day] = {
      9 => [],
      10 => [],
      11 => [],
      12 => [],
      13 => [],
      14 => [],
      15 => [],
      16 => [],
      17 => [],
      18 => [],
      19 => [],
      20 => [],
      21 => []
    }.merge(ogroup.group_by { |o| DateTime.parse(o.created_at).strftime("%H").to_i })
    h
  }
  orders_by_day_and_hour.map { |k, v| [k, v.map { |h, orders| [h, orders] }.sort] }.sort
end

def orders_by_hour_and_day(orders)
  orders_by_hour = orders.group_by { |o| DateTime.parse(o.created_at).strftime("%H").to_i }
  orders_by_hour_and_day = orders_by_hour.inject({}) { |h, (hour, ogroup)|
    h[hour] = {
      1 => [],
      2 => [],
      3 => [],
      4 => [],
      5 => [],
      6 => [],
      7 => []
    }.merge(ogroup.group_by { |o| DateTime.parse(o.created_at).cwday })
    h
  }
  orders_by_hour_and_day.map { |k, v| [k, v.map { |h, orders| [h, orders] }.sort] }.sort
end

def chart_row(hour, values)
  if hour > 12
    display_time = hour - 12
    time = 'pm'
  else
    display_time = hour
    time = 'am'
  end
  "[{v: [#{hour}, 0, 0], f: '#{display_time} #{time}'}, #{values.map(&:to_s).join(', ')}]"
end

def count_chart_js_for_orders(orders)
  ohd = orders_by_hour_and_day(orders)
  rows = ohd.map { |h, oh| chart_row(h, oh.map { |(d, od)| od.count.to_s }) }
  rows_js = rows.join(",\n      ")
  GOOGLE_CHART_ORDERS_BY_HOUR_JS.sub('ROWS_GO_HERE', rows_js)
end
