require 'gattica'
require 'yaml'

class GoogleAnalyticsApi

    # Initialize the following:
    #  * Yaml configuration parameters
    #  * Gattica object
    def initialize
        @config = YAML::load(File.open('parameters.yml'))['google_analytics']
        @ga = Gattica.new({ 
            :email => @config['username'], 
            :password => @config['password']
        })
    end

    # Get all defined metrics for all accounts defined in the config yaml file
    # for a given date range.
    # Returns an array of hashes in the form
    # {"metric_name"=>"SOME_NAME", "date"=>"YYYY-MM-DD", "value"=>number}
    def get_metrics_date_range(start_date, end_date)
        metrics = Array.new

        # Iterate through each profile in the config file
        @config['profiles'].each do |profile|

            # Get metrics and add them to combined metrics
            if profile['metrics']
                metrics += get_profile_metrics(profile['metrics'], profile['profile_id'], start_date, end_date)
            end
        end

        metrics        
    end

    # Get all defined metrics for all profiles defined in the config yaml file
    # for a given date.
    def get_metrics_date(date)
        get_metrics_date_range(date, date)
    end

    # Get all defined metrics for all profiles defined in the config yaml file
    # for days back from today.
    def get_metrics_days_back(days_back)
        now = Time.now - (1*24*60*60)
        prev = Time.now - ((days_back+1)*24*60*60)
        now = format_date(now)
        prev = format_date(prev)

        get_metrics_date_range(prev, now)
    end

    # Get all defined metrics for all profiles defined in the config yaml file
    # for the last three days.
    def get_metrics_latest
        get_metrics_days_back(3)
    end

    # Print the information for each account you have connected in Google Analytics
    # Use to get profile_id(s) for config file
    def show_account_info
        # Get a list of accounts
        accounts = @ga.accounts

        # Show information about accounts
        puts "---------------------------------"
        puts "Available profiles: " + accounts.count.to_s
        accounts.each do |account|
            puts "   --> " + account.title
            puts "   last updated: " + account.updated.inspect
            puts "   web property: " + account.web_property_id
            puts "     profile id: " + account.profile_id.inspect
            puts "          goals: " + account.goals.count.inspect
        end
    end


    private


    def get_profile_metrics(metrics_config, profile_id, start_date, end_date)
        metrics = Array.new

        # Iterate through each metirc
        metrics_config.each do |metric|
            type = metric['type']
            days = fetch_data(profile_id, type, start_date, end_date)

            days.each do |day|
                date = day.dimensions.first[:date]
                value = day.metrics.first[type.to_sym]
                metrics << create_metric(metric['name'], format_date_from_string(date), value)
            end
        end

        metrics
    end

    def fetch_data(profile_id, type, start_date, end_date)
        # Set the profile id
        @ga.profile_id = profile_id

        # Get the data 
        data = @ga.get({ 
            :start_date   => start_date,
            :end_date     => end_date,
            :dimensions   => ['date'],
            :metrics      => [type],
        })

        data.to_h['points']
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

    def format_date_from_string(date_string)
        date = Date.strptime(date_string,"%Y%m%d")
        date.strftime("%Y-%m-%d")
    end
end
