#!/bin/bash
set -euo pipefail
exec > >(tee -a /var/log/install-wordpress.log) 2>&1

DB_HOST='${db_host}'
DB_NAME='${db_name}'
DB_USER='${db_user}'
DB_PASSWORD="$(printf '%s' '${db_password_b64}' | base64 -d)"
ENABLE_HTTPS='${enable_https}'
DATA_DEVICE='${data_device}'

WEB_ROOT=/var/www/html

echo "==============================================================="
echo " Installation WordPress — base $DB_NAME sur $DB_HOST"
echo " HTTPS : $ENABLE_HTTPS — volume de données : $DATA_DEVICE"
echo "==============================================================="

echo "[1/9] Mise à jour du système..."
dnf -y upgrade --refresh

echo "[2/9] Apache + PHP (PHP 8.x d'Amazon Linux 2023)..."
dnf install -y httpd php php-fpm php-mysqlnd wget unzip openssl
dnf install -y --setopt=strict=0 php-gd php-mbstring php-xml php-opcache php-intl php-zip || true

echo "[3/9] Démarrage d'Apache et de PHP-FPM..."
systemctl enable --now php-fpm
systemctl enable --now httpd

echo "[4/9] Attente du volume EBS $DATA_DEVICE..."
ALT_DEVICE="$(printf '%s' "$DATA_DEVICE" | sed 's|/dev/sd|/dev/xvd|')"
ROOT_DISK="/dev/$(lsblk -no PKNAME "$(findmnt -no SOURCE /)")"
DATA_DEV=""
for i in $(seq 1 60); do
  for d in "$DATA_DEVICE" "$ALT_DEVICE"; do
    if [ -b "$d" ]; then
      CANDIDAT="$(readlink -f "$d")"
      if [ "$CANDIDAT" != "$ROOT_DISK" ]; then
        DATA_DEV="$CANDIDAT"
        break 2
      fi
    fi
  done
  sleep 5
done

if [ -n "$DATA_DEV" ]; then
  echo "[5/9] Volume trouvé ($DATA_DEV) : formatage si vierge + montage sur $WEB_ROOT..."
  if [ -z "$(blkid -o value -s TYPE "$DATA_DEV" 2>/dev/null || true)" ]; then
    mkfs -t xfs -f "$DATA_DEV"
  fi
  DATA_UUID="$(blkid -o value -s UUID "$DATA_DEV")"
  mkdir -p "$WEB_ROOT"
  if ! grep -q "$DATA_UUID" /etc/fstab; then
    echo "UUID=$DATA_UUID $WEB_ROOT xfs defaults,nofail 0 2" >> /etc/fstab
  fi
  systemctl daemon-reload
  mount "$WEB_ROOT"
else
  echo "[5/9] ERREUR : volume $DATA_DEVICE introuvable après 5 min."
  echo "      Installation sur le disque racine (mode dégradé)."
fi

echo "[6/9] Téléchargement de WordPress..."
if [ ! -f "$WEB_ROOT/wp-settings.php" ]; then
  cd /tmp
  rm -rf /tmp/wordpress-extract latest.zip
  wget -q https://wordpress.org/latest.zip
  unzip -q latest.zip -d /tmp/wordpress-extract
  cp -r /tmp/wordpress-extract/wordpress/. "$WEB_ROOT/"
  rm -rf /tmp/wordpress-extract latest.zip
else
  echo "      WordPress déjà présent sur le volume : conservé."
fi

echo "[7/9] wp-config.php vers $DB_HOST..."
php_escape() { printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e "s/'/\\\\'/g"; }
salt() { openssl rand -base64 48 | tr -d '\n=' | tr '/+' '_-'; }

if [ ! -f "$WEB_ROOT/wp-config.php" ]; then
  cat > "$WEB_ROOT/wp-config.php" <<WPCONF
<?php
define( 'DB_NAME',     '$(php_escape "$DB_NAME")' );
define( 'DB_USER',     '$(php_escape "$DB_USER")' );
define( 'DB_PASSWORD', '$(php_escape "$DB_PASSWORD")' );
define( 'DB_HOST',     '$(php_escape "$DB_HOST")' );
define( 'DB_CHARSET',  'utf8mb4' );
define( 'DB_COLLATE',  '' );

define( 'AUTH_KEY',         '$(salt)' );
define( 'SECURE_AUTH_KEY',  '$(salt)' );
define( 'LOGGED_IN_KEY',    '$(salt)' );
define( 'NONCE_KEY',        '$(salt)' );
define( 'AUTH_SALT',        '$(salt)' );
define( 'SECURE_AUTH_SALT', '$(salt)' );
define( 'LOGGED_IN_SALT',   '$(salt)' );
define( 'NONCE_SALT',       '$(salt)' );

\$table_prefix = 'wp_';

define( 'WP_DEBUG', false );
define( 'FS_METHOD', 'direct' );
define( 'DISALLOW_FILE_EDIT', true );

if ( ! defined( 'ABSPATH' ) ) {
    define( 'ABSPATH', __DIR__ . '/' );
}
require_once ABSPATH . 'wp-settings.php';
WPCONF
else
  echo "      wp-config.php déjà présent : conservé."
fi

echo "[8/9] Attente de la base $DB_HOST:3306 (max 5 min)..."
DB_OK=false
for i in $(seq 1 60); do
  if timeout 3 bash -c "exec 3<>/dev/tcp/$DB_HOST/3306" 2>/dev/null; then
    DB_OK=true
    echo "      Base accessible."
    break
  fi
  sleep 5
done
if [ "$DB_OK" != "true" ]; then
  echo "      ATTENTION : base injoignable (security group RDS ? DB_HOST = .address ?)"
fi

echo "[9/9] Permissions + redémarrage + test..."
chown -R apache:apache "$WEB_ROOT"
find "$WEB_ROOT" -type d -exec chmod 755 {} \;
find "$WEB_ROOT" -type f -exec chmod 644 {} \;
chmod 640 "$WEB_ROOT/wp-config.php"
systemctl restart php-fpm httpd

for i in $(seq 1 12); do
  if curl -fsS -o /dev/null http://localhost/; then
    echo "      Apache répond sur le port 80."
    break
  fi
  sleep 5
done

if [ "$ENABLE_HTTPS" = "true" ]; then
  echo "[bonus] HTTPS 443 avec certificat autosigné..."
  dnf install -y mod_ssl
  mkdir -p /etc/pki/tls/private /etc/pki/tls/certs
  if [ ! -f /etc/pki/tls/certs/wordpress.crt ]; then
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
      -keyout /etc/pki/tls/private/wordpress.key \
      -out /etc/pki/tls/certs/wordpress.crt \
      -subj "/CN=liora-wordpress"
    chmod 600 /etc/pki/tls/private/wordpress.key
  fi
  sed -i \
    -e 's|^SSLCertificateFile .*|SSLCertificateFile /etc/pki/tls/certs/wordpress.crt|' \
    -e 's|^SSLCertificateKeyFile .*|SSLCertificateKeyFile /etc/pki/tls/private/wordpress.key|' \
    /etc/httpd/conf.d/ssl.conf
  systemctl restart httpd
  curl -kfsS -o /dev/null https://localhost/ && echo "      HTTPS actif (certificat autosigné)."
fi

echo "==============================================================="
echo " Installation terminée — journal : /var/log/install-wordpress.log"
echo "==============================================================="
