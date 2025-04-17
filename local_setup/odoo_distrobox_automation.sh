#!/usr/bin/env bash
# This is a script to setup Odoo 18 on a Debian-based system a compilation of commands i used to setup odoo on distrobox.

set -e

# ---- CONFIGURABLE VARIABLES ----
ODOO_VERSION="18.0"
ODOO_DIR="$HOME/odoo"
ODOO_SERVER_DIR="$ODOO_DIR/odoo-server"
ODOO_CONFIG="/etc/odoo-server.conf"
ODOO_DB="odoo18"
ODOO_DB_USER="odoo"
ODOO_DB_PASSWORD="odoo_pwd123" # Change as needed
ODOO_ADMIN_PASSWD="admin"
ODOO_PORT="8069"
ODOO_LOG="/var/log/odoo/odoo-server.log"

# ---- UPDATE AND INSTALL SYSTEM DEPENDENCIES ----
sudo apt update
sudo apt upgrade -y

sudo apt install -y git python3 python3-pip build-essential wget python3-dev python3-venv python3-wheel \
  libxslt-dev libzip-dev libldap2-dev libsasl2-dev python3-setuptools node-less libjpeg-dev gdebi \
  libpq-dev python3-dev libxml2-dev libxslt1-dev libldap2-dev libsasl2-dev libffi-dev \
  nodejs npm xfonts-75dpi postgresql postgresql-contrib

# ---- START POSTGRESQL ----
sudo pg_ctlcluster 14 main start || true

# ---- CREATE POSTGRESQL USER ----
sudo -u postgres psql -c "DO \$\$ BEGIN IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '${ODOO_DB_USER}') THEN CREATE ROLE ${ODOO_DB_USER} WITH SUPERUSER LOGIN PASSWORD '${ODOO_DB_PASSWORD}'; END IF; END \$\$;"

# ---- CREATE ODOO DATABASE (OPTIONAL, Odoo can create it via web UI) ----
sudo -u postgres psql -c "SELECT 1 FROM pg_database WHERE datname = '${ODOO_DB}'" | grep -q 1 || sudo -u postgres createdb -O ${ODOO_DB_USER} ${ODOO_DB}

# ---- INSTALL NODE.JS TOOLS ----
sudo npm install -g rtlcss

# ---- INSTALL WKHTMLTOPDF (STATIC BUILD) ----
cd /tmp
wget -q https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6-1.bionic_amd64.deb
sudo apt install -y ./wkhtmltox_0.12.6-1.bionic_amd64.deb

# ---- CREATE LOG DIRECTORY ----
sudo mkdir -p /var/log/odoo
sudo chown $USER:$USER /var/log/odoo

# ---- CLONE ODOO SOURCE ----
mkdir -p "$ODOO_DIR"
git clone --depth 1 --branch $ODOO_VERSION https://github.com/odoo/odoo "$ODOO_SERVER_DIR"
sudo chown -R $USER:$USER "$ODOO_SERVER_DIR"

# ---- PYTHON VIRTUAL ENVIRONMENT ----
cd "$ODOO_SERVER_DIR"
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip setuptools wheel

# ---- FIX gevent/psycopg2 ISSUES IN requirements.txt ----
sed -i 's/gevent==21.8.0/gevent==22.10.2/g' requirements.txt
sed -i 's/psycopg2\b/psycopg2-binary/g' requirements.txt

pip install -r requirements.txt

# ---- CREATE ODOO CONFIGURATION FILE ----
sudo tee $ODOO_CONFIG >/dev/null <<EOF
[options]
admin_passwd = $ODOO_ADMIN_PASSWD
xmlrpc_port = $ODOO_PORT
logfile = $ODOO_LOG
addons_path = $ODOO_SERVER_DIR/addons
db_user = $ODOO_DB_USER
db_password = $ODOO_DB_PASSWORD
db_host = localhost
db_port = 5432
EOF

sudo chown $USER:$USER $ODOO_CONFIG
sudo chmod 640 $ODOO_CONFIG

echo
echo "---------------------------------------------"
echo "Odoo 18 setup complete!"
echo "To start Odoo, run:"
echo "  cd $ODOO_SERVER_DIR"
echo "  source venv/bin/activate"
echo "  ./odoo-bin -c $ODOO_CONFIG"
echo
echo "Then open http://localhost:$ODOO_PORT in your browser."
echo "---------------------------------------------"
