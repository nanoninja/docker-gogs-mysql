# Gogs application

CONFIG="$(shell pwd)/etc/app.ini"

include .env

help:
	@echo ""
	@echo "Usage:"
	@echo "  make [COMMAND]"
	@echo ""
	@echo "Commands:"
	@echo "  cert            Generate SSL certificates"
	@echo "  clean           Clean all services and volumes"
	@echo "  config-create   Copy the configuration file from the dist file"
	@echo "  config-read     Read configuration from server"
	@echo "  config-write    Override configuration to the server"
	@echo "  install         Automatic installation of Gogs"
	@echo "  logs            Follow log output"
	@echo "  run             Start without automatically filling form"

run:
	@make config-create
	@docker-compose up -d
	@make cert
	@make config-write
	@sleep 13

install:
	@make run
	@docker run --env-file $(shell pwd)/.env --rm -v $(shell pwd)/bin/install.sh:/install.sh --net=host appropriate/curl /bin/sh /install.sh
	@make config-read

logs:
	@docker-compose logs -f

clean:
	@docker-compose down -v
	@rm -f $(CONFIG)

cert:
	@docker-compose exec -T gogsapp bash -c "cd /app/gogs; exec /app/gogs/gogs cert -ca=true -duration=$(GOGS_CERT_DURATION) -host=$(GOGS_HTTP_DOMAIN)"

config-create:
	@cp $(CONFIG).dist $(CONFIG)

config-write:
	@docker cp $(CONFIG) $(shell docker-compose ps -q gogsapp):/data/gogs/conf/app.ini
	@docker-compose restart gogsapp

config-read:
	@docker cp $(shell docker-compose ps -q gogsapp):/data/gogs/conf/app.ini $(shell pwd)/etc/app.ini
