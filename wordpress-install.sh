

update_configurations() {
  URL=${1-site.test}
  DB=${2-wpsite}

  if [ ! -e /data/www-app/${URL}/.env ]; then
    echo >&2 "Creating .env file"
    touch /data/www-app/${URL}/.env
  fi
  echo >&2 "Setting up configurations for wordpress site ${URL}"
  wp dotenv set WP_SITEURL https://${URL}
  wp dotenv set WP_HOME https://${URL}
  wp dotenv set DB_NAME ${DB}
  wp dotenv set DB_USER ${MYSQL_USER-root}
  wp dotenv set DB_PASSWORD ${MYSQL_ROOT_PASSWORD-password}
  wp dotenv set DB_HOST mysql
  wp dotenv set MULTISITE 1

  #wp dotenv set DOMAIN_CURRENT_SITE https://${URL}
  # means database needs to be created.
  if [ -z "$(wp db check --quiet)" ] ; then
    echo >&2 "Creating database ${DB} for wordpress site ${URL}"
    wp db create;
  fi

  echo "path: web/wp" $'\r\n'"url: ${URL} " > wp-cli.yml

  if ! $(wp core is-installed); then
    echo >&2 "Installing multisite wordpress for ${URL}"
    wp core multisite-install --url="${URL}" --title="${WORDPRESS_TITLE:-Dev Multi}" --admin_user=${WORDPRESS_USER-admin} --admin_password="${WORDPRESS_PASSWORD-password}" --admin_email="${WORDPRESS_EMAIL-user@example.com}"
  fi
  wp dotenv salts regenerate
  wp network meta set 1 fileupload_maxk 30000
  wp core update
  wp core version
  wp core verify-checksums
}

# this is development branch of blog_gov_bc.ca.git
install_wordpress() {
  URL=${1-site.test}
  DB=${2-wpsite}
  REPO=${3-}
  BRANCH=${4-development}
  echo >&2 "Getting ${URL} configurations"

  mkdir -p /data/www-app/${URL} && cd /data/www-app/${URL}
  # this means no repo, so do default
  if [ ! -e /data/www-app/${URL}/composer.json ]; then
    if [ -z "${REPO}" ] ; then
      echo >&2 "Building new project from roots/bedrock"
      composer create-project --ignore-platform-reqs --prefer-source roots/bedrock .
    else
      git clone -b ${BRANCH} ${REPO} .
      echo >&2 "Fetching repo ${REPO} ${BRANCH}"
    fi
  else
    if [ ! -z "${REPO}" ] ; then
      cd /data/www-app/${URL}
      echo >&2 "Found ${URL} configuration, checking if there is an up to date copy.."
      git pull
    fi
  fi
  cd /data/www-app/${URL}



  # create uploads if doesn't exists
  if [ -e /data/www-app/${URL}/composer.json ]; then
    composer update --ignore-platform-reqs
    wp package install aaemnnosttv/wp-cli-dotenv-command:^1.0

    echo >&2 "Finished updating composer files for ${URL}"

    if [ -e /data/www-app/${URL}/web/app/uploads ]
    then
      echo >&2 'Found Uploads directory'
    else
      echo >&2 "Making uploads directory"
      mkdir -p /data/www-app/${URL}/web/app/uploads
    fi
    chmod -R 777 /data/www-app/${URL}/web/app
    update_configurations ${URL} ${DB}

  else
    echo >&2 "Error composer file not found...."
  fi
}

install_wordpress "${WORDPRESS_SITE}.test" "${WORDPRESS_SITE}" "${WORDPRESS_REPOSITORY}" "master"
install_wordpress "wp.test" "wptest" "${WORDPRESS_REPOSITORY_TEST}" "development"
