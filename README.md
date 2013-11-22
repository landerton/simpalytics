simpalytics
===========

Get metric data from App Annie, Google Analytics, and Flurry APIs in an array of hashes in the form
{"metric_name"=>"METRIC_NAME", "date"=>"YYYY-MM-DD", "value"=>numeric_value}.
Use the ruby scripts to get your web and app analytic data in a simple to use format. Use the classes to
run a daily cron job and populate/update your own three column database.

### Ruby Gem Dependencies

#### App Annie
    base64
    json
    curb
    yaml
    open-uri

#### Google Analytics
    gattica
    yaml

[Gattica][gattica-gem] is an easy to use Gem for getting data from the Google Analytics API. You'll need to clone
the [gattica][gattica-gem] repo, create, and install the gem.

#### Flurry
    yaml
    curb
    json

### Parameters.yml

A parameters.yml file is needed to define your accounts and what metrics you want to gather. This file is
not committed to the repository to prevent system specific or sensitive information from being
included. However, a parameters.yml.dist file is included for you to use as a base for your parameters.yml file.

    cp parameters.yml.dist parameters.yml

### Using to Populate/Update a Database

These scripts were ment to be used to gather daily metrics and then use them to populate and update a three column 
database. The database should be unique for metric_name and date, so that values can update after being initially 
populated. Check out example.rb to see what methods can be used.

    app_annie = AppAnnieApi.new
    google_analytics = GoogleAnalyticsApi.new
    flurry_analytics = FlurryApi.new

    # I would use these exact calls to get the data needed to populate/update my database everyday

    # Gets the last 3 days worth of data. 
    # Some metrics take a couple days to populate in App Annie.
    # Getting the last 3 days worth of metrics will update values that were not yet reported.
    app_annie.get_metrics_latest

    # Gets the last 3 days worth of data. 
    # Some metrics take a couple days to populate in Google Analytics.
    google_analytics.get_metrics_latest

    # Gets the last 45 days worth of data. 
    # Flurry metrics like sessions will often not be reported until the next time the app is opened.
    # I give them 45 days, at which time the value is usually pretty stable.
    flurry_analytics.get_metrics_latest

[gattica-gem]: https://github.com/chrisle/gattica
