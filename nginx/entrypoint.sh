#!/bin/bash
[[ ! -d /var/www/html/Organizr.git ]] && (git clone https://github.com/causefx/Organizr /var/www/html/Organizr/) && (chown -R nginx:nginx "/var/www/html/Organizr")
# Variables
HOST='$host'
XIP='$remote_addr'
proxy='$proxy_add_x_forwarded_for'
NGINX_SCHEME='$scheme'
NAME='$server_name'
NGINX_REQUEST_URI='$request_uri'
cgiparam='$document_root$fastcgi_script_name'
upgrade='$http_upgrade'
URI='$uri'
STATUS='$status'
Allowed_country='$allowed_country'
# Locations
if [ ! -e ${plex} ]; then
    plex=$(cat <<-END
    location /web {
       proxy_pass http://openvpn:32400;
       proxy_set_header Host $HOST;
       proxy_set_header X-Real-IP $XIP;
       proxy_set_header X-Forwarded-For $proxy;
    }

    location /plexweb {
       proxy_pass http://localhost/web;
    }
END
)
fi

if [ ! -e ${ombi} ]; then
ombi=$(cat <<-END
    location /ombi {
       proxy_pass http://openvpn:5000;
       proxy_http_version 1.1;
       proxy_set_header Upgrade $upgrade;
       proxy_set_header Connection keep-alive;
       proxy_set_header Host $HOST;
       #proxy_set_header X-Real-IP $remote_addr;
       #proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
END
)
fi

if [ ! -e ${sonarr} ]; then
sonarr=$(cat <<-END
    location /sonarr {
       proxy_pass http://openvpn:8989;
       proxy_set_header Host $HOST;
       proxy_set_header X-Real-IP $XIP;
       proxy_set_header X-Forwarded-For $proxy;
    }
END
)
fi

if [ ! -e ${radarr} ]; then
radarr=$(cat <<-END
    location /radarr {
       proxy_pass http://openvpn:7878;
       proxy_set_header Host $HOST;
       proxy_set_header X-Real-IP $XIP;
       proxy_set_header X-Forwarded-For $proxy;
    }
END
)
fi

if [ ! -e ${jackett} ]; then
jackett=$(cat <<-END
    location /jackett/ {
       proxy_pass http://openvpn:9117;
       proxy_set_header Host $HOST;
       proxy_set_header X-Real-IP $XIP;
       proxy_set_header X-Forwarded-For $proxy;
    }
END
)
fi
if [ ! -e ${deluge} ]; then
deluge=$(cat <<-END
    location /deluge {
       proxy_pass http://openvpn:8112;
       proxy_set_header X-Deluge-Base "/deluge/";
#       include proxy-control.conf;
       add_header X-Frame-Options SAMEORIGIN;
    }
END
)
fi

if [ ! -e ${portainer} ]; then
portainer=$(cat <<-END
   location /portainer/ {
     proxy_pass http://portainer:9000/;
     proxy_http_version 1.1;
     proxy_set_header   Host               $HOST;
     proxy_set_header   X-Real-IP          $XIP;
     proxy_set_header   X-Forwarded-For    $proxy;
     proxy_set_header   X-Forwarded-Proto  $NGINX_SCHEME;
     proxy_set_header   Upgrade            $upgrade;
     proxy_set_header   Connection         "upgrade";
   }
END
)
fi

if [ ! -e ${plexpy} ]; then
plexpy=$(cat <<-END
   location /plexpy {
     proxy_pass http://plexpy:8181;
     proxy_set_header   Host               $HOST;
     proxy_set_header   X-Real-IP          $XIP;
     proxy_set_header   X-Forwarded-For    $proxy;
     proxy_set_header   X-Forwarded-Proto  $NGINX_SCHEME;
     proxy_set_header   Upgrade            $upgrade;
     proxy_set_header        X-Forwarded-Ssl      on;
   }
END
)
fi
if [ ! -e ${GEOBLOCK} ]; then
GEOBLOCK==$(cat <<-END
    if ($Allowed_country = no) {
        return 444;
    }
END
)
fi

# Create nginx config file
cat > "/etc/nginx/conf.d/default.conf" << EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name ${domain} localhost;
    return 301 https://$NAME$NGINX_REQUEST_URI;
}
server {
    listen 443 ssl http2 default_server;
    listen [::]:443 ssl http2 default_server;
    include /etc/nginx/snippets/strong-ssl.conf;
    ssl_certificate /etc/letsencrypt/archive/${domain}/fullchain1.pem;
    ssl_certificate_key /etc/letsencrypt/archive/${domain}/privkey1.pem;

    root /var/www/html/Organizr;

    index index.php;

    error_page 400 401 402 403 404 /error.php?error=$STATUS;

${GEOBLOCK}

    location / {
        try_files $URI $URI/ =404;

    }

    location ~ (\.json$) {
        return 404;
    }

    location ~ \.php$ {
       fastcgi_split_path_info ^(.+\.php)(/.+)$;
       try_files $URI =404;
       include /etc/nginx/fastcgi_params;
       fastcgi_pass php:9000;
       fastcgi_param SCRIPT_FILENAME $cgiparam;
       fastcgi_index index.php;
    }
${plex}
${ombi}
${sonarr}
${deluge}
${radarr}
${jackett}
${portainer}
${plexpy}
}
EOF
echo "Final configuration for nginx:"
cat /etc/nginx/conf.d/default.conf
exec "$@"

