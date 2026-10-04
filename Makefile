IMAGE := floci-aws
NAME  := floci-aws
PORT  := 4566

.PHONY: aws aws-down

aws:
	docker build -t $(IMAGE) .
	-docker rm -f $(NAME) 2>/dev/null
	docker run -d --name $(NAME) -p $(PORT):4566 $(IMAGE)
	@echo "floci AWS endpoint: http://localhost:$(PORT)"

aws-down:
	docker rm -f $(NAME)
