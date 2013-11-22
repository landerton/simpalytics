require 'yaml'
require 'curb'
require 'json'

class FlurryApi

    # Initialize the following:
    #  * Yaml configuration parameters
    def initialize
        @config = YAML::load(File.open('parameters.yml'))['flurry']
    end

    # Get all defined metrics for all apps defined in the config yaml file
    # for a given date range.
    # Returns an array of hashes in the form
    # {"metric_name"=>"SOME_NAME", "date"=>"YYYY-MM-DD", "value"=>number}
    def get_metrics_date_range(start_date, end_date)
        metrics = Array.new

        # Iterate through each app in the config file
        @config['apps'].each do |app|

            # Get metrics and add them to combined metrics
            if app['metrics']
                metrics += get_app_metrics(app['metrics'], app['api_key'], start_date, end_date)
            end
        end

        metrics
    end

    # Get all defined metrics for all apps defined in the config yaml file
    # for a given date.
    def get_metrics_date(date)
        get_metrics_date_range(date, date)
    end

    # Get all defined metrics for all apps defined in the config yaml file
    # for days back from today.
    def get_metrics_days_back(days_back)
        now = Time.now - (1*24*60*60)
        prev = Time.now - ((days_back+1)*24*60*60)
        now = format_date(now)
        prev = format_date(prev)

        get_metrics_date_range(prev, now)
    end

    # Get all defined metrics for all apps defined in the config yaml file
    # for the last 45 days. Flurry sessions continue to update after the
    # date passes, because often it isn't reported until the next time the
    # app is opened.
    def get_metrics_latest
        get_metrics_days_back(45)
    end


    private


    def get_app_metrics(metrics_config, api_key, start_date, end_date)
        metrics = Array.new

        # Iterate through each metirc
        metrics_config.each do |metric|
            days = fetch_metric_list(metric['type'], api_key, start_date, end_date)

            if days.kind_of?(Array)
                days.each do |day|
                    metrics << create_metric(metric['name'], day['@date'], day['@value'])
                end
            else
                # For single day, an array is not returned
                metrics << create_metric(metric['name'], days['@date'], days['@value'])
            end
        end

        metrics
    end

    def create_metric(metric_name, date, value)
        metric = Hash.new
        metric['metric_name'] = metric_name
        metric['date'] = date
        metric['value'] = value
        metric
    end

    def format_date(date)
        date.strftime("%Y-%m-%d")
    end

    def fetch_metric_list(metric_type, api_key, start_date, end_date)
        path = "/appMetrics/#{metric_type}?apiAccessCode=#{@config['api_access_code']}"
        params = "&apiKey=#{api_key}&startDate=#{start_date}&endDate=#{end_date}&groupBy=DAYS"
        response = JSON.parse(api_request(path+params))

        response['day']
    end

    def api_request(path)
        api_uri = @config['api_uri']
        url = api_uri + path

        # Attempt the api call
        result = api_call(url)
        status = result.response_code

        # Sometimes the calls fail unexpectedly, give it a couple tries.
        i = 0
        while (i < 3) && (status != 200)
            result = api_call(url)

            i += 1
            status = result.response_code
        end

        if status != 200
            raise "Api call #{url} failed with status #{status}"
        end

        result.body_str
    end

    def api_call(url)
        # The Flurry API is rate limited at 1 request per second... lame. Delaying to be safe.
        sleep(1)

        result = Curl.get(url) do |api_http|
            api_http.headers['Accept'] = 'application/json'
        end

        result
    end
end
