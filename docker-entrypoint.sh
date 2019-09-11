#!/bin/bash

update_configurations() {
  URL=${1-site.test}
  DB=${2-wpsite}


echo >&2 "Setting up configurations for wordpress site ${URL}"
  if [ ! -z "${WORDPRESS_REPOSITORY}" ] ; then
    wp dotenv set WP_SITEURL https://${URL}
    wp dotenv set WP_HOME https://${URL}
    wp dotenv set DOMAIN_CURRENT_SITE https://${URL}

    wp dotenv set DB_NAME ${DB}
    wp dotenv set DB_USER ${MYSQL_USER-root}
    wp dotenv set DB_PASSWORD ${MYSQL_ROOT_PASSWORD-password}
    wp dotenv set DB_HOST ${MYSQL_HOST-bcgov_mysql}
    wp dotenv set MULTISITE ${WORDPRESS_MULTISITE-1}
    wp dotenv set WP_ENV development
    wp dotenv salts regenerate
  else
    cd /data/www-app/${URL}/web
    wp core download
    wp config create --dbname=${DB} --dbuser=${MYSQL_USER-root} --dbpass=${MYSQL_ROOT_PASSWORD-password} --dbhost=${MYSQL_HOST-bcgov_mysql} --skip-check
    wp config set WP_SITEURL https://${URL}
    wp config set WP_HOME https://${URL}
    if [ "${WORDPRESS_MULTISITE-1}" == 1 ]; then
      wp config set MULTISITE true
    fi
  fi

  #wp dotenv set DOMAIN_CURRENT_SITE https://${URL}
  # means database needs to be created.
  if [ -z "$(wp db check  --quiet)" ] ; then
    echo >&2 "Creating database ${DB} for wordpress site ${URL} "
    wp db create;
  else
    echo >&2 "Database already created"
  fi

  if ! $(wp core is-installed); then
    if [ "${WORDPRESS_MULTISITE}" == 1 ]; then
      echo >&2 "Installing multisite wordpress for ${URL}"
      wp core multisite-install --url="${URL}" --title="${WORDPRESS_TITLE:-Dev Multi}" --admin_user=${WORDPRESS_USER-admin} --admin_password="${WORDPRESS_PASSWORD-password}" --admin_email="${WORDPRESS_EMAIL-user@example.com}"
    else
      echo >&2 "Installing wordpress for ${URL}"
      wp core install --url="${URL}" --title="${WORDPRESS_TITLE:-Dev Single}" --admin_user=${WORDPRESS_USER-admin} --admin_password="${WORDPRESS_PASSWORD-password}" --admin_email="${WORDPRESS_EMAIL-user@example.com}"
    fi
  fi

  if [ "${WORDPRESS_MULTISITE-1}" == 1 ]; then
    wp network meta set 1 fileupload_maxk 30000
  fi
  wp core update
  wp core version
  wp core verify-checksums
  echo >&2 "Wordpress has successfully been installed."
}

install_wordpress() {
  URL=${1-site.test}
  DB=${2-wpsite}
  mkdir -p /data/www-app/${URL}/web && cd /data/www-app/${URL}/web
  update_configurations ${URL} ${DB}
}
# this is development branch of blog_gov_bc.ca.git
install_wordpress_composer() {
  URL=${1-site.test}
  DB=${2-wpsite}
  REPO=${3-}
  BRANCH=${4-development}
  echo >&2 "Getting ${URL} configurations"

  git config --global user.email "govwordpress@gov.bc.ca"
  git config --global user.name "Gov Wordpress"

  mkdir -p /data/www-app/${URL} && cd /data/www-app/${URL}
  # this means no repo, so do default
  if [ ! -e /data/www-app/${URL}/composer.json ] && [ ! -e /data/www-app/${URL}/composer-dev.json ]; then
      git clone -b ${BRANCH} ${REPO} .
      echo >&2 "Fetching repo ${REPO} ${BRANCH}"
  else
      git stash # just in case, which im sure something gets changed.
      git checkout ${BRANCH}
      git pull

  fi
  cd /data/www-app/${URL}



  if [ -e /data/www-app/${URL}/composer.json ] || [ -e /data/www-app/${URL}/composer-dev.json ]; then
    ## This accounts for composer-dev files.
    if [ -e /data/www-app/${URL}/composer-dev.json ]; then
      COMPOSER="composer-dev.json" composer update --ignore-platform-reqs
    else
      COMPOSER="composer.json" composer update --ignore-platform-reqs
    fi

    wp package install aaemnnosttv/wp-cli-dotenv-command:^1.0
    echo >&2 "Finished updating composer files for ${URL}"

    # create uploads if doesn't exists
    if [ ! -e /data/www-app/${URL}/web/app/uploads ]
    then
      echo >&2 "Making uploads directory"
      mkdir -p /data/www-app/${URL}/web/app/uploads
    fi
    #chmod  755 /data/www-app/${URL}/web/app

    echo "path: web/wp" $'\r\n'"url: ${URL} " > wp-cli.yml

    if [ ! -e /data/www-app/${URL}/.env ]; then
      echo >&2 "Creating .env file"
      touch /data/www-app/${URL}/.env
    fi
    update_configurations ${URL} ${DB}

  else
    echo >&2 "Error composer file not found...."
  fi
}

set -e
echo >&2 'Starting Wordpress build'
cd /data/www-app

if [ -z "${WORDPRESS_REPOSITORY}" ] ; then
  echo >&2 'Installing Wordpress from source'
  install_wordpress "${WORDPRESS_SITE}.test" "${WORDPRESS_SITE}"
else
  echo >&2 'Installing Wordpress with composer file (BEDROCK)'
  install_wordpress_composer "${WORDPRESS_SITE}.test" "${WORDPRESS_SITE}" "${WORDPRESS_REPOSITORY}" "${WORDPRESS_REPOSITORY_BRANCH-master}"
fi

echo >&2 "Completed Wordpress build for ${WORDPRESS_SITE}.test"

#/usr/sbin/nginx -s stop
exec "$@"
