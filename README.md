# release-script-dev-env

Script that pulling the docker image id from ECR and if it's different form the local image ID, it restarting docker-compose and sending the version to the Opensearch.
There is an alert on OpenSearch that rune every minute and searching for the "CURRENT_VERSION_IS" string.
