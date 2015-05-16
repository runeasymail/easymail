# Install autoconfig and autodiscover
mkdir /usr/share/nginx/autoconfig_and_autodiscover

cp $CURRENT_DIR/autoconfig.php /usr/share/nginx/autoconfig_and_autodiscover/
set_hostname /usr/share/nginx/autoconfig_and_autodiscover/autoconfig.php

cp $CURRENT_DIR/autodiscover.php /usr/share/nginx/autoconfig_and_autodiscover/
set_hostname /usr/share/nginx/autoconfig_and_autodiscover/autodiscover.php

cp $CURRENT_DIR/nginx_config_for_autoconfig_and_autodiscover /etc/nginx/sites-enabled/autoconfig_and_autodiscover
set_hostname /etc/nginx/sites-enabled/autoconfig_and_autodiscover
