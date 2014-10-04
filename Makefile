.PHONY: nginx nginx-image nginx-reload

NGINX_IMAGE:=parente/nginx

nginx-image:
	@cd src/nginx; docker build -t $(NGINX_IMAGE) .

nginx-reload:
	@ps aux | grep 'nginx: master' | grep -v grep | awk '{print $$2}' | xargs kill -HUP

nginx:
	@docker run -d --name nginx \
	-p 80:80 \
	--restart on-failure \
	-v /srv/html:/usr/local/nginx/html:ro \
	-v ./src/nginx:/srv/nginx:ro \
	$(NGINX_IMAGE)
