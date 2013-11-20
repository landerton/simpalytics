require 'base64'
require 'json'
require 'curb'
require 'yaml'
require 'open-uri'

class AppAnnieApi

    # Initialize the following:
    #  * Yaml configuration parameters
    #  * Authentication token
    def initialize
        @config = YAML::load(File.open('parameters.yml'))['app_annie']
        @token = api_token(@config['username'], @config['password'])
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
                if app['sales']
                    metrics += get_sales_metrics(app['sales'], account['account_id'], app['app_id'], start_date, end_date)
                end

                # Get the rating metrics and add them to combined metrics
                if app['ratings']
                    metrics += get_rating_metrics(app['ratings'], account['account_id'], app['app_id'])
                end

                # Get the ranking metrics and add them to combined metrics
                if app['rankings']
                    metrics += get_ranks_metrics(app['rankings'], account['account_id'], app['app_id'], start_date, end_date)
                end
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
    # for the last three days.
    def get_metrics_latest
        get_metrics_days_back(3)
    end


    # Get a list of of all account info and corresponding app info.
    # Use to get account_id(s) and app_id(s) for config file.
    def get_account_list
        account_list = fetch_account_list

        account_list.each do |account| 
            account['app_list'] = fetch_app_list(account['account_id'])
        end

        account_list
    end


    private


    def api_token(email, password)
        'Basic ' + Base64.encode64("#{email}:#{password}")
    end

    def get_sales_metrics(app_config, account_id, app_id, start_date, end_date)
        metrics = Array.new

        # Make the sales api call for this app and date range
        sales_list = fetch_sales_list(account_id, app_id, start_date, end_date)

        # Iterate through each days worth of sales
        sales_list.each do |day|

            # If we want to collect download data for this app
            if app_config['downloads']
                metrics << create_metric(app_config['downloads'], day['date'], day['units']['app']['downloads'])
            end

            # If we want to collect revenue data for this app
            if app_config['revenue']
                metrics << create_metric(app_config['revenue'], day['date'], day['revenue']['app']['downloads'])
            end
        end

        metrics
    end

    def get_rating_metrics(app_config, account_id, app_id)
        metrics = Array.new
        date = format_date(Time.now - (1*24*60*60))

        # Make the rating api call for this app
        rating_list = fetch_ratings_list(account_id, app_id)

        if rating_list.empty?
            return metrics
        end

        if app_config['all_count'] && app_config['all_average']
            all_stars = sum_rating_stars(rating_list, 'all_ratings')
            all_count = sum_rating_counts(rating_list, 'all_ratings')

            metrics << create_metric(app_config['all_count'], date, all_count)

            if all_count > 0
                avg = all_stars / all_count.to_f
                avg = avg.round(2)
                metrics << create_metric(app_config['all_average'], date, avg)
            end
        end

        if app_config['cur_count'] && app_config['cur_average']
            current_stars = sum_rating_stars(rating_list, 'current_ratings')
            current_count = sum_rating_counts(rating_list, 'current_ratings')

            metrics << create_metric(app_config['cur_count'], date, current_count)

            if current_count > 0
                avg = current_stars / current_count.to_f
                avg = avg.round(2)
                metrics << create_metric(app_config['cur_average'], date, avg)
            end
        end

        metrics
    end

    def get_ranks_metrics(app_config, account_id, app_id, start_date, end_date)
        metrics = Array.new

        app_config.each do |rank_category|
            params = ''
            if rank_category['country']
                params += '&countries=' + rank_category['country']
            end
            if rank_category['category']
                params += '&category=' + URI::encode(rank_category['category'])
            end
            if rank_category['device']
                params += '&device=' + rank_category['device']
            end
            if rank_category['feed']
                params += '&feed=' + rank_category['feed']
            end

            app_ranks = fetch_ranks_list(account_id, app_id, start_date, end_date, params)
            if !app_ranks.empty?
                ranks = app_ranks.first['ranks']
                ranks.each do |date, ranking|
                    metrics << create_metric(rank_category['name'], date, ranking)
                end
            end
        end

        metrics
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

    def fetch_sales_list(account_id, app_id, start_date, end_date)
        path = "/accounts/#{account_id}/apps/#{app_id}/sales"
        params = "?break_down=date&start_date=#{start_date}&end_date=#{end_date}&interval=daily"
        response = JSON.parse(api_request(path+params))

        response['sales_list']
    end

    def fetch_ratings_list(account_id, app_id)
        path = "/accounts/#{account_id}/apps/#{app_id}/ratings?country=US"
        response = JSON.parse(api_request(path))

        response['rating_list']
    end

    def fetch_ranks_list(account_id, app_id, start_date, end_date, additional_params)
        path = "/accounts/#{account_id}/apps/#{app_id}/ranks"
        params = "?start_date=#{start_date}&end_date=#{end_date}"
        response = JSON.parse(api_request(path+params+additional_params))

        response['app_ranks']
    end

    def fetch_category_list(platform)
        path = "/meta/#{platform}/categories"
        response = JSON.parse(api_request(path))

        response['categories']
    end

    def sum_rating_stars(rating_list, rating_name)
        total = rating_list.inject(0){|stars, country| 
            stars += check_nil(country[rating_name]['star_1_count']) * 1
            stars += check_nil(country[rating_name]['star_2_count']) * 2
            stars += check_nil(country[rating_name]['star_3_count']) * 3
            stars += check_nil(country[rating_name]['star_4_count']) * 4
            stars += check_nil(country[rating_name]['star_5_count']) * 5
        }
        total
    end

    def sum_rating_counts(rating_list, rating_name)
        total = rating_list.inject(0){|count, country|
            count += check_nil(country[rating_name]['rating_count'])
        }
        total
    end

    def check_nil(variable)
        if !variable.nil?
            return variable
        end
        return 0
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
