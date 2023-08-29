include etc/environment.sh

sgroups: sgroups.package sgroups.deploy
sgroups.package:
	sam package -t ${SGROUPS_TEMPLATE} --output-template-file ${SGROUPS_OUTPUT} --s3-bucket ${S3BUCKET} --s3-prefix ${SGROUPS_STACK}
sgroups.deploy:
	sam deploy -t ${SGROUPS_OUTPUT} --stack-name ${SGROUPS_STACK} --parameter-overrides ${SGROUPS_PARAMS} --capabilities CAPABILITY_NAMED_IAM

hostedzone: hostedzone.package hostedzone.deploy
hostedzone.package:
	sam package -t ${R53_HOSTEDZONE_TEMPLATE} --output-template-file ${R53_HOSTEDZONE_OUTPUT} --s3-bucket ${S3BUCKET} --s3-prefix ${R53_HOSTEDZONE_STACK}
hostedzone.deploy:
	sam deploy -t ${R53_HOSTEDZONE_OUTPUT} --stack-name ${R53_HOSTEDZONE_STACK} --parameter-overrides ${R53_HOSTEDZONE_PARAMS} --capabilities CAPABILITY_NAMED_IAM

acm: acm.package acm.deploy
acm.package:
	sam package -t ${ACM_TEMPLATE} --output-template-file ${ACM_OUTPUT} --s3-bucket ${S3BUCKET} --s3-prefix ${ACM_STACK}
acm.deploy:
	sam deploy -t ${ACM_OUTPUT} --stack-name ${ACM_STACK} --parameter-overrides ${ACM_PARAMS} --capabilities CAPABILITY_NAMED_IAM

listener: listener.package listener.deploy
listener.package:
	sam package -t ${LISTENER_TEMPLATE} --output-template-file ${LISTENER_OUTPUT} --s3-bucket ${S3BUCKET} --s3-prefix ${LISTENER_STACK}
listener.deploy:
	sam deploy -t ${LISTENER_OUTPUT} --stack-name ${LISTENER_STACK} --parameter-overrides ${LISTENER_PARAMS} --capabilities CAPABILITY_NAMED_IAM

lattice: lattice.package lattice.deploy
lattice.package:
	sam package -t ${LATTICE_TEMPLATE} --output-template-file ${LATTICE_OUTPUT} --s3-bucket ${S3BUCKET} --s3-prefix ${LATTICE_STACK}
lattice.deploy:
	sam deploy -t ${LATTICE_OUTPUT} --stack-name ${LATTICE_STACK} --parameter-overrides ${LATTICE_PARAMS} --capabilities CAPABILITY_NAMED_IAM

alias: alias.package alias.deploy
alias.package:
	sam package -t ${R53_ALIAS_TEMPLATE} --output-template-file ${R53_ALIAS_OUTPUT} --s3-bucket ${S3BUCKET} --s3-prefix ${R53_ALIAS_STACK}
alias.deploy:
	sam deploy -t ${R53_ALIAS_OUTPUT} --stack-name ${R53_ALIAS_STACK} --parameter-overrides ${R53_ALIAS_PARAMS} --capabilities CAPABILITY_NAMED_IAM

client: client.build client.package client.deploy
client.build:
	sam build -t ${CLIENT_TEMPLATE} --parameter-overrides ${CLIENT_PARAMS} --build-dir build --use-container --skip-pull-image
client.package:
	sam package -t build/template.yaml --output-template-file ${CLIENT_OUTPUT} --s3-bucket ${S3BUCKET} --s3-prefix ${CLIENT_STACK}
client.deploy:
	sam deploy -t ${CLIENT_OUTPUT} --stack-name ${CLIENT_STACK} --parameter-overrides ${CLIENT_PARAMS} --capabilities CAPABILITY_NAMED_IAM

listener.local:
	sam local invoke -t ${LISTENER_TEMPLATE} --parameter-overrides ${LISTENER_PARAMS} --env-vars etc/envvars.json -e etc/event.json Fn | jq
client.local:
	sam local invoke -t build/template.yaml --parameter-overrides ${CLIENT_PARAMS} --env-vars etc/envvars.json -e etc/event.json Fn | jq
lambda.invoke.sync:
	aws --profile ${PROFILE} lambda invoke --function-name ${O_FN} --invocation-type RequestResponse --payload file://etc/event.json --cli-binary-format raw-in-base64-out --log-type Tail tmp/fn.json | jq "." > tmp/response.json
	cat tmp/response.json | jq -r ".LogResult" | base64 --decode
	cat tmp/fn.json | jq
lambda.invoke.async:
	aws --profile ${PROFILE} lambda invoke --function-name ${O_FN} --invocation-type Event --payload file://etc/event.json --cli-binary-format raw-in-base64-out --log-type Tail tmp/fn.json | jq "."
