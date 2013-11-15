simpalytics
===========

Get analytical data from App Annie, Google Analytics and Flurry in the form {metric_name, date, value}.
Use the ruby scripts to get your web and app analytic data in a simple to use format. Use the classes to
run a daily script and populate/update your own three column database.

### Ruby Gem Dependencies

#### App Annie
    base64
    json
    curb
    yaml

### Parameters.yml

A parameters.yml file is needed to define your accounts and what metrics you want to gather. This file is
not committed to the repository to prevent system specific or sensitive information from being
included. However, a parameters.yml.dist file is included for you to use as a base for your parameters.yml file.

    cp app/config/parameters.yml.dist app/config/parameters.yml
