# Install autoconfig and autodiscover

AUTOCONFIG_DIR="$CURRENT_DIR/autoconfig"

mkdir /usr/share/nginx/autoconfig_and_autodiscover

cp $AUTOCONFIG_DIR/autoconfig.php /usr/share/nginx/autoconfig_and_autodiscover/
set_hostname /usr/share/nginx/autoconfig_and_autodiscover/autoconfig.php

cp $AUTOCONFIG_DIR/autodiscover.php /usr/share/nginx/autoconfig_and_autodiscover/
set_hostname /usr/share/nginx/autoconfig_and_autodiscover/autodiscover.php

cp $AUTOCONFIG_DIR/nginx_config /etc/nginx/sites-enabled/autoconfig_and_autodiscover
set_hostname /etc/nginx/sites-enabled/autoconfig_and_autodiscover
