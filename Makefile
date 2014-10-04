.PHONY: help setup nginx nginx-image nginx-reload

NGINX_IMAGE:=parente/nginx
HTML_DIR:=/srv/html

help:
	@cat Makefile

setup: nginx-image
	@mkdir -p $(HTML_DIR)
	@chown -R root:www-data $(HTML_DIR)
	@chmod -R go-w $(HTML_DIR)
	@chmod g+s $(HTML_DIR)/*

nginx-image:
	@cd src/nginx; docker build -t $(NGINX_IMAGE) .

nginx-reload:
	@ps aux | grep 'nginx: master' | grep -v grep | awk '{print $$2}' | xargs kill -HUP

nginx:
	@docker run -d --name nginx \
	-p 80:80 \
	--restart on-failure \
	-v $(HTML_DIR):/usr/local/nginx/html:ro \
	-v `pwd`/src/nginx:/srv/nginx:ro \
	$(NGINX_IMAGE)
