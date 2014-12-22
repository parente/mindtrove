.PHONY: help setup nginx nginx-image nginx-reload omnifocus

NGINX_IMAGE:=parente/nginx
HTML_DIR:=/srv/html

WEBDAV_IMAGE:=parente/webdav
OMNIFOCUS_DIR:=/srv/webdav

SHELL:=/bin/bash

help:
	@cat Makefile

setup: nginx-image
# setup static html dirs with proper permissions
	@mkdir -p $(HTML_DIR)
	@chown -R root:www-data $(HTML_DIR)
	@chmod -R go-w $(HTML_DIR)
	@chmod g+s $(HTML_DIR)/*
# enable log rotation for docker
	@cp ./src/logrotate/docker /etc/logrotate.d/docker

nginx-image:
	@cd src/nginx; docker build -t $(NGINX_IMAGE) .

nginx-reload:
	@ps aux | grep 'nginx: master' | grep -v grep | awk '{print $$2}' | xargs kill -HUP

nginx:
	@-docker rm -f nginx	
	@docker run -d --name nginx \
	-p 80:80 \
	--restart on-failure \
	-v $(HTML_DIR):/usr/local/nginx/html:ro \
	-v `pwd`/src/nginx:/srv/nginx:ro \
	$(NGINX_IMAGE)

nginx-dev:
	@-docker rm -f nginx-dev
	@docker run -d --name nginx-dev \
    -p 8080:80 \
	-v $(HTML_DIR):/usr/local/nginx/html:ro \
	-v `pwd`/src/nginx:/srv/nginx:ro \
	$(NGINX_IMAGE)

omnifocus:
	@docker run -d --name omnifocus \
    -p 8443:443 \
    --restart on-failure \
    -v $(OMNIFOCUS_DIR):/srv/webdav \
    -e PASSWORD=`read -p "Password: " -s PASSWORD && echo $$PASSWORD` \
    $(WEBDAV_IMAGE) 

