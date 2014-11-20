# Omniauth Example App

## Run

1. Copy config/secret.yml.example to config/secrets.yml and assign proper values.
2. Run database migration.
3. Run rails server.

## Implemenation Details

### Models

* User - The account for authentication, using devise.
* OmniauthRef - To store the omniauth data.
* OmniauthProvider - The interface to gen the OmniauthProvider::Base-based object. Define the supported providers.
* OmniauthProvider::Base - The base class of OmniauthProvider, define the methods to handle the omniauth account creation and binding.
* OmniauthProvider::Facebook  - The Facebook provider class.

### Controllers

* OmniauthCallbacksController - To receive the request from omniauth app.
* OmniauthMailController - To handle the case that there is on email information from omniauth.

### Views

* OmniauthMailController#new - The page for asking the email information.

## Authors

Sibevin Wang

## Copyright

Copyright (c) 2014 Sibevin Wang. Released under the MIT license.
