load 'AppAnnieApi.rb'
load 'GoogleAnalyticsApi.rb'
load 'FlurryApi.rb'

app_annie = AppAnnieApi.new
google_analytics = GoogleAnalyticsApi.new
flurry_analytics = FlurryApi.new

# I would use these exact calls to get the data needed to populate/update my database everyday

# Gets the last 3 days worth of data. 
# Some metrics take a couple days to populate in App Annie.
puts app_annie.get_metrics_latest

# Gets the last 3 days worth of data. 
# Some metrics take a couple days to populate in Google Analytics.
puts google_analytics.get_metrics_latest

# Gets the last 45 days worth of data. 
# Flurry metrics like sessions will often not be reported until the next time the app is opened.
# I give them 45 days, which is usually pretty stable.
puts flurry_analytics.get_metrics_latest
puts

# Get data for days back from today
# puts app_annie.get_metrics_days_back(5)
# puts google_analytics.get_metrics_days_back(5)
# puts flurry_analytics.get_metrics_days_back(5)
# puts

# Get past data for a range of dates
# puts app_annie.get_metrics_date_range('2013-11-01', '2013-11-02')
# puts google_analytics.get_metrics_date_range('2013-11-01', '2013-11-04')
# puts flurry_analytics.get_metrics_date_range('2013-11-01', '2013-11-02')
# puts

# Same thing as above only for a specific date
# puts app_annie.get_metrics_date('2013-10-24')
# puts google_analytics.get_metrics_date('2013-10-24')
# puts flurry_analytics.get_metrics_date('2013-10-24')
# puts
