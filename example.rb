load 'AppAnnieApi.rb'

app_annie = AppAnnieApi.new

# I would use this exact call to get the data needed to populate/update my database everyday
puts app_annie.get_metrics_days_back(3)
puts

# This isn't too reliable because some fields are still not populated for acouple of days,
# even though app annie says they are
puts app_annie.get_metrics_latest
puts

# This works to get past data for a range of dates
puts app_annie.get_metrics_date_range('2013-11-01', '2013-11-02')
puts

# Same thing as above only for a specific date
puts app_annie.get_metrics_date('2013-11-04')
puts
