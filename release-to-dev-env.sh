#!/usr/bin/env bash

repository=""
tag="latest"
docker_compose_path="/home/services/$repository/"
docker_compose_file="docker-compose.yml"
base_url="012345678910.dkr.ecr.eu-west-1.amazonaws.com"
image=""

prev_id=""
next_id=""

should_restart_docker="0"

usage="$(basename "$0") [-h] [-r|--repository <REPOSITORY_NAME>] [-p|--path <DOCKER_COMPOSE_PATH>] [-t|--tag <TAG>] [-f|--file <DOCKER_COMPOSE_FILE>] [-b|--base <BASE_URL>]

where:
    -h  show this help text
    -r  the name of the repository to download (example: notification-service)
    -p  the path of the docker-compose (default: /home/services/$repository/)
    -f  the docker-compose file name (default: docker-compose.yml)
    -t  the tag you want to download (example: v1.0.0, default: latest)
    -b  the base registry (default: 012345678910.dkr.ecr.eu-west-1.amazonaws.com)
    "
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -r|--repository) repository="$2"; shift ;;
        -p|--path) docker_compose_path="$2"; shift ;;
        -t|--tag) tag="$2"; shift ;;
        -f|--file) docker_compose_file="$2"; shift ;;
        -b|--base) base_url="$2"; shift ;;
        -h|--help) echo "$usage" >&2; exit 1 ;;
        *) printf "illegal option: -%s\n" "$OPTARG" >&2;echo "$usage" >&2;exit 1;;
    esac
    shift
done

if [ "$repository" == "" ];
then
  echo "$usage" >&2;exit 1;
  exit;
fi

download_images () {
  repos=$(echo $repository | tr "," "\n")

  for repo in $repos
  do
    local image="$base_url/$repo:$tag";

    echo "Downloading image... $image";

    prev_id=$(docker inspect --format {{.Id}} $image)

    docker pull $image;

    next_id=$(docker inspect --format {{.Id}} $image)

    if [ "$prev_id" != "$next_id" ]
    then
      update_local_version "$repo";
      should_restart_docker="1";
    fi
  done

  if [ "$should_restart_docker" == "1" ]
  then
    restart_docker;
  fi
}

update_local_version () {
  local repo="$1";

  echo "Update docker compose file for $repo";

  sed -i --expression "s@$base_url/$repo:.*@$base_url\/$repo:$tag@" $docker_compose_path/$docker_compose_file;
}

restart_docker () {
  echo "Restart docker compose";

  $(docker-compose -f $docker_compose_path/$docker_compose_file up -d --force-recreate);
}

send_version () {                                                                                                                                                                   
  echo "Sending version to OpenSearch";                                                                                                                                             
                                                                                                                                                                                    
  $(docker exec --workdir /app notification-service /bin/sh -c 'printf "CURRENT_VERSION_IS %s\n"  "$(printenv VERSION)" >> /proc/1/fd/1');                                             
                  }  
download_images;
