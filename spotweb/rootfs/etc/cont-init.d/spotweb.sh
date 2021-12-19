#!/usr/bin/with-contenv bashio
# ==============================================================================
# Home Assistant Community Add-on: spotweb
# This file validates config and creates the database
# ==============================================================================

# fix permissions
mkdir /app/cache
mkdir /var/tmp/nginx
chown -R nginx:nginx /app/cache
chown -R nginx:root /var/tmp/nginx

declare mysql_host
declare mysql_user
declare mysql_port
declare mysql_pass
declare mysql_db="spotweb"

if bashio::config.has_value 'remote_mysql_host'; then
  if ! bashio::config.has_value 'remote_mysql_database'; then
    bashio::exit.nok \
      "Remote database has been specified but no database is configured"
  fi

  if ! bashio::config.has_value 'remote_mysql_username'; then
    bashio::exit.nok \
      "Remote database has been specified but no username is configured"
  fi

  if ! bashio::config.has_value 'remote_mysql_password'; then
    bashio::log.fatal \
      "Remote database has been specified but no password is configured"
  fi

  if ! bashio::config.exists 'remote_mysql_port'; then
    bashio::exit.nok \
      "Remote database has been specified but no port is configured"
  fi
else
  if ! bashio::services.available 'mysql'; then
     bashio::log.fatal \
       "Local database access should be provided by the MariaDB addon"
     bashio::exit.nok \
       "Please ensure it is installed and started"
  fi

  mysql_host=$(bashio::services "mysql" "host")
  mysql_pass=$(bashio::services "mysql" "password")
  mysql_port=$(bashio::services "mysql" "port")
  mysql_user=$(bashio::services "mysql" "username")

# write db config file
cat >/app/dbsettings.inc.php <<EOL
<?php
\$dbsettings['engine'] = "pdo_mysql";
\$dbsettings['host'] = "$mysql_host:$mysql_port";
\$dbsettings['dbname'] = "$mysql_db";
\$dbsettings['user'] = "$mysql_user";
\$dbsettings['pass'] = "$mysql_pass";
EOL

bashio::log.warning "Spotweb is using the Maria DB addon"
bashio::log.warning "Please ensure this is included in your backups"
bashio::log.warning "Uninstalling the MariaDB addon will remove any data"

 # Check if database already exists
RESULT=`mysql -u "$mysql_user" -p"$mysql_pass" -h "$mysql_host" -P "$mysql_port" --skip-column-names -e "SHOW DATABASES LIKE '$mysql_db'"`
if [ "$RESULT" == "$mysql_db" ]; then
    # database already exists, do healthcheck with upgrade-db
    php /app/bin/upgrade-db.php>/dev/null
else
    # database does not yet exist
    bashio::log.info "Creating database with default settings...."
    mysql \
        -u "${mysql_user}" -p"${mysql_pass}" \
        -h "${mysql_host}" -P "${mysql_port}" \
        -e "CREATE DATABASE ${mysql_db};"
    # init database with default values
    php /app/bin/upgrade-db.php
    # set systemtype to public (as we're behind ingress)
    php /app/bin/upgrade-db.php --set-systemtype public
    # we also set some sane default settings
    mysql \
        -u "${mysql_user}" -p"${mysql_pass}" \
        -h "${mysql_host}" -P "${mysql_port}" \
        -D "${mysql_db}" \
        -e "REPLACE INTO usergroups(userid, groupid) VALUES (1, 2); \
            REPLACE INTO usergroups(userid, groupid) VALUES (1, 3); \
            REPLACE INTO usergroups(userid, groupid) VALUES (1, 4); \
            REPLACE INTO usergroups(userid, groupid) VALUES (1, 5); \
            UPDATE usersettings SET otherprefs='a:27:{s:17:\"template_specific\";a:1:{s:6:\"we1rdo\";a:1:{s:15:\"example_setting\";i:1;}}s:7:\"perpage\";i:25;s:15:\"date_formatting\";s:5:\"human\";s:15:\"normal_template\";s:6:\"we1rdo\";s:15:\"mobile_template\";s:6:\"we1rdo\";s:15:\"tablet_template\";s:6:\"we1rdo\";s:14:\"count_newspots\";s:2:\"on\";s:17:\"mouseover_subcats\";s:2:\"on\";s:13:\"keep_seenlist\";s:2:\"on\";s:15:\"auto_markasread\";s:2:\"on\";s:17:\"keep_downloadlist\";s:2:\"on\";s:14:\"keep_watchlist\";s:2:\"on\";s:17:\"nzb_search_engine\";s:8:\"nzbindex\";s:13:\"show_filesize\";s:2:\"on\";s:16:\"show_reportcount\";s:2:\"on\";s:19:\"minimum_reportcount\";s:1:\"1\";s:14:\"show_nzbbutton\";s:2:\"on\";s:13:\"show_multinzb\";s:2:\"on\";s:9:\"customcss\";s:0:\"\";s:18:\"newspotdefault_tag\";s:9:\"anonymous\";s:19:\"newspotdefault_body\";s:0:\"\";s:13:\"user_language\";s:5:\"en_US\";s:12:\"show_avatars\";s:2:\"on\";s:27:\"usemailaddress_for_gravatar\";b:1;s:11:\"nzbhandling\";a:7:{s:6:\"action\";s:6:\"nzbget\";s:9:\"local_dir\";s:4:\"/tmp\";s:14:\"prepare_action\";s:5:\"merge\";s:7:\"command\";s:0:\"\";s:7:\"sabnzbd\";a:4:{s:3:\"url\";s:0:\"\";s:6:\"apikey\";s:0:\"\";s:8:\"username\";s:0:\"\";s:8:\"password\";s:0:\"\";}s:6:\"nzbget\";a:6:{s:4:\"host\";s:28:\"addon_62c7908d_nzbget_docker\";s:4:\"port\";s:5:\"46836\";s:3:\"ssl\";s:0:\"\";s:8:\"username\";s:6:\"nzbget\";s:8:\"password\";s:0:\"\";s:7:\"timeout\";s:2:\"30\";}s:9:\"nzbvortex\";a:3:{s:4:\"host\";s:0:\"\";s:4:\"port\";s:0:\"\";s:6:\"apikey\";s:0:\"\";}}s:13:\"notifications\";a:6:{s:6:\"boxcar\";a:3:{s:5:\"email\";s:0:\"\";s:7:\"enabled\";b:0;s:6:\"events\";a:7:{s:17:\"watchlist_handled\";b:0;s:11:\"nzb_handled\";b:0;s:18:\"retriever_finished\";b:0;s:13:\"report_posted\";b:0;s:11:\"spot_posted\";b:0;s:10:\"user_added\";b:0;s:19:\"newspots_for_filter\";b:0;}}s:5:\"growl\";a:4:{s:4:\"host\";s:0:\"\";s:8:\"password\";s:0:\"\";s:7:\"enabled\";b:0;s:6:\"events\";a:7:{s:17:\"watchlist_handled\";b:0;s:11:\"nzb_handled\";b:0;s:18:\"retriever_finished\";b:0;s:13:\"report_posted\";b:0;s:11:\"spot_posted\";b:0;s:10:\"user_added\";b:0;s:19:\"newspots_for_filter\";b:0;}}s:3:\"nma\";a:3:{s:3:\"api\";s:0:\"\";s:7:\"enabled\";b:0;s:6:\"events\";a:7:{s:17:\"watchlist_handled\";b:0;s:11:\"nzb_handled\";b:0;s:18:\"retriever_finished\";b:0;s:13:\"report_posted\";b:0;s:11:\"spot_posted\";b:0;s:10:\"user_added\";b:0;s:19:\"newspots_for_filter\";b:0;}}s:5:\"prowl\";a:3:{s:6:\"apikey\";s:0:\"\";s:7:\"enabled\";b:0;s:6:\"events\";a:7:{s:17:\"watchlist_handled\";b:0;s:11:\"nzb_handled\";b:0;s:18:\"retriever_finished\";b:0;s:13:\"report_posted\";b:0;s:11:\"spot_posted\";b:0;s:10:\"user_added\";b:0;s:19:\"newspots_for_filter\";b:0;}}s:7:\"twitter\";a:7:{s:11:\"screen_name\";s:0:\"\";s:13:\"request_token\";s:0:\"\";s:20:\"request_token_secret\";s:0:\"\";s:12:\"access_token\";s:0:\"\";s:19:\"access_token_secret\";s:0:\"\";s:7:\"enabled\";b:0;s:6:\"events\";a:7:{s:17:\"watchlist_handled\";b:0;s:11:\"nzb_handled\";b:0;s:18:\"retriever_finished\";b:0;s:13:\"report_posted\";b:0;s:11:\"spot_posted\";b:0;s:10:\"user_added\";b:0;s:19:\"newspots_for_filter\";b:0;}}s:5:\"email\";a:2:{s:7:\"enabled\";b:0;s:6:\"events\";a:7:{s:17:\"watchlist_handled\";b:0;s:11:\"nzb_handled\";b:0;s:18:\"retriever_finished\";b:0;s:13:\"report_posted\";b:0;s:11:\"spot_posted\";b:0;s:10:\"user_added\";b:0;s:19:\"newspots_for_filter\";b:0;}}}s:16:\"defaultsortfield\";s:0:\"\";}' WHERE 1;"
fi


