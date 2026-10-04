IMAGE   := floci-aws
NAME    := floci-aws
PORT    := 4566
UI_NAME := floci-ui
UI_PORT := 4500
NETWORK := floci
REGION  := ap-south-1

.PHONY: aws aws-down

aws:
	docker build -t $(IMAGE) .
	-docker rm -f $(NAME) $(UI_NAME) 2>/dev/null
	docker network inspect $(NETWORK) >/dev/null 2>&1 || docker network create $(NETWORK)
	docker run -d --name $(NAME) --network $(NETWORK) -p $(PORT):4566 \
		-u root --security-opt label=disable \
		-v /var/run/docker.sock:/var/run/docker.sock \
		$(IMAGE)
	docker run -d --name $(UI_NAME) --network $(NETWORK) -p $(UI_PORT):4500 \
		-e FLOCI_ENDPOINT=http://$(NAME):4566 -e AWS_REGION=$(REGION) \
		-e AWS_ACCESS_KEY_ID=test -e AWS_SECRET_ACCESS_KEY=test \
		floci/floci-ui:latest
	@echo "floci AWS endpoint: http://localhost:$(PORT)"
	@echo "floci UI:           http://localhost:$(UI_PORT)"

aws-down:
	-docker rm -f $(NAME) $(UI_NAME)
	-docker network rm $(NETWORK)
