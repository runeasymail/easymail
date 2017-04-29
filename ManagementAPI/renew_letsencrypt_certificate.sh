export LETSENCRYPT_STRING="__EASY_MAIL_INCLUDE_LETSENCRYPT__"
export ROUNDCUBE_FILE="/etc/nginx/sites-enabled/roundcube"

# Check if Roundcube and the API are configured to work with Letsencrypt
if ! [grep -q $LETSENCRYPT_STRING $ROUNDCUBE_FILE];
then
        # Get ManagementAPI credentials
        export MANAGEMENT_API_CONFIG="/opt/easymail/ManagementAPI/config.ini"
        export HOSTNAME=$(cat "$MANAGEMENT_API_CONFIG" | grep hostname= | awk -F'=' '{ print $2;}')
        export MANAGEMENT_API_USERNAME=$(cat "$MANAGEMENT_API_CONFIG" | grep username: | awk -F':' '{ print $2;}')
        export MANAGEMENT_API_PASSWORD=$(cat "$MANAGEMENT_API_CONFIG" | grep password: | awk -F':' '{ print $2;}')

        # Auth in front of the API
        export MANAGEMENT_API_TOKEN=$(curl --insecure -X POST -F "username=$MANAGEMENT_API_USERNAME" -F "password=$MANAGEMENT_API_PASSWORD" "https://$HOSTNAME/api/auth" | python -c 'import$
print(json.load(sys.stdin)["token"])')

		# Renew the Letsencrypt SSL if to token is not empty
        if [ -n "$MANAGEMENT_API_TOKEN" ];
        then
                curl --insecure -X POST -H "Auth-token: $MANAGEMENT_API_TOKEN" -H "Cache-Control: no-cache" -F "hostname=$HOSTNAME" "https://$HOSTNAME/api/ssl/letsencrypt/install"

                echo 'The Letsencrypt SSL has been renewed successfully!';
        fi
fi
