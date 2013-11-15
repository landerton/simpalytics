require 'base64'
require 'json'
require 'curb'
require 'yaml'

class AppAnnieApi

    # Initialize the following:
    #  * Yaml configuration parameters
    #  * Authentication token
    #  * List of all accounts and apps
    #  * Hash of all apps and their latest update dates 
    def initialize
        @config = YAML::load(File.open('parameters.yml'))['app_annie']
        @token = api_token(@config['username'], @config['password'])
        @account_list = fetch_account_list

        @account_list.each do |account| 
            account['app_list'] = fetch_app_list(account['account_id'])
        end

        @latest_metric_dates = get_latest_metric_dates(@account_list)
    end

    # Get all defined metrics for all apps defined in the config yaml file
    # for a given date range.
    # Returns an array of hashes in the form
    # {"metric_name"=>"SOME_NAME", "date"=>"YYYY-MM-DD", "value"=>number}
    def get_metrics_date_range(start_date, end_date)
        metrics = Array.new

        # Iterate through each store account in the config file
        @config['accounts'].each do |account|

            # Iterate through each app for the given account
            account['apps'].each do |app|

                # Get the sales metrics and add them to combined metrics
                metrics += get_sales_metrics(app, account['account_id'], app['app_id'], start_date, end_date)
            end
        end

        metrics
    end

    # Get all defined metrics for all apps defined in the config yaml file
    # for the latest sales date recorded.
    # Returns an array of hashes in the form
    # {"metric_name"=>"SOME_NAME", "date"=>"YYYY-MM-DD", "value"=>number}
    # TODO: Google Play gives value of zero for downloads on latest sales date.
    def get_metrics_latest
        metrics = Array.new

        # Iterate through each store account in the config file
        @config['accounts'].each do |account|

            # Iterate through each app for the given account
            account['apps'].each do |app|
                # Get the last available sales date
                date = @latest_metric_dates[app['app_id'].to_s]

                # Get the sales metrics and add them to combined metrics
                metrics += get_sales_metrics(app, account['account_id'], app['app_id'], date, date)
            end
        end

        metrics
    end

    # Get all defined metrics for all apps defined in the config yaml file
    # for a given date.
    # Returns an array of hashes in the form
    # {"metric_name"=>"SOME_NAME", "date"=>"YYYY-MM-DD", "value"=>number}
    def get_metrics_date(date)
        get_metrics_date_range(date, date)
    end

    # Get all defined metrics for all apps defined in the config yaml file
    # for days back from today.
    # Returns an array of hashes in the form
    # {"metric_name"=>"SOME_NAME", "date"=>"YYYY-MM-DD", "value"=>number}
    def get_metrics_days_back(days_back)
        now = Time.now - (1*24*60*60)
        prev = Time.now - ((days_back+1)*24*60*60)
        now = format_date(now)
        prev = format_date(prev)

        get_metrics_date_range(prev, now)
    end


    private


    def api_token(email, password)
        'Basic ' + Base64.encode64("#{email}:#{password}")
    end

    def fetch_account_list
        path = '/accounts'
        response = JSON.parse(api_request(path))

        if response['code'] != 200
            raise 'Could not obtain account information from App Annie'
        end
      
        response['account_list']
    end

    def fetch_app_list(account_id)
        path = "/accounts/#{account_id}/apps"
        response = JSON.parse(api_request(path))

        if response['code'] != 200
            raise "Could not obtain app information from App Annie account: #{account_id}"
        end

        response['app_list']
    end

    def get_sales_metrics(app_config, account_id, app_id, start_date, end_date)
        metrics = Array.new

        # Make the sales api call for this app and date range
        sales_list = fetch_sales_list(account_id, app_id, start_date, end_date)

        # Iterate through each days worth of sales
        sales_list.each do |day|

            # If we want to collect download data for this app
            if app_config['downloads']
                metric = Hash.new
                metric['metric_name'] = app_config['downloads']
                metric['date'] = day['date']
                metric['value'] = day['units']['app']['downloads']
                metrics << metric
            end

            # If we want to collect revenue data for this app
            if app_config['revenue']
                metric = Hash.new
                metric['metric_name'] = app_config['revenue']
                metric['date'] = day['date']
                metric['value'] = day['revenue']['app']['downloads']
                metrics << metric
            end
        end

        metrics
    end

    def fetch_sales_list(account_id, app_id, start_date, end_date)
        path = "/accounts/#{account_id}/apps/#{app_id}/sales"
        params = "?break_down=date&start_date=#{start_date}&end_date=#{end_date}"
        response = JSON.parse(api_request(path+params))

        response['sales_list']
    end

    def get_latest_metric_dates(account_list)
        metric_dates = Hash.new

        account_list.each do |account| 
            account['app_list'].each do |app|
                metric_dates[app['app_id']] = app['last_sales_date']
            end
        end

        metric_dates
    end

    def format_date(date)
        date.strftime("%Y-%m-%d")
    end

    def api_request(path)
        appannie_api = @config['api_uri']
        url = appannie_api + path

        # Attempt the api call
        result = Curl.get(url) do |api_http|
            api_http.headers['Authorization'] = @token
            api_http.headers['Accept'] = 'application/json'
        end
        status = result.response_code

        # Sometimes the calls fail unexpectedly, give it a couple tries.
        i = 0
        while (i < 3) && (status != 200)
            result = Curl.get(url) do |api_http|
                api_http.headers['Authorization'] = @token
                api_http.headers['Accept'] = 'application/json'
            end

            i += 1
            status = result.response_code
        end

        if status != 200
            raise "Api call #{url} failed with status #{status}"
        end

        result.body_str
    end
end
