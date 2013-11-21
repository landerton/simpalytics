load 'AppAnnieApi.rb'
load 'GoogleAnalyticsApi.rb'

app_annie = AppAnnieApi.new
google_analytics = GoogleAnalyticsApi.new

# I would use this exact call to get the data needed to populate/update my database everyday
# Gets the last 3 days worth of data
puts app_annie.get_metrics_latest
puts google_analytics.get_metrics_latest
puts

# Get data for days back from today
# puts app_annie.get_metrics_days_back(5)
# puts google_analytics.get_metrics_days_back(5)
# puts

# Get past data for a range of dates
# puts app_annie.get_metrics_date_range('2013-11-01', '2013-11-02')
# puts google_analytics.get_metrics_date_range('2013-11-01', '2013-11-04')
# puts

# Same thing as above only for a specific date
# puts app_annie.get_metrics_date('2013-10-24')
# puts google_analytics.get_metrics_date('2013-10-24')
# puts
