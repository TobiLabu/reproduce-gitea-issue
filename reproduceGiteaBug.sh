#! /bin/bash

export USERNAME=username
export PASSWORD=password
export REPO_NAME=testrepo
export GITEA_CONTAINER_NAME=gitea
export GITEA_PORT=3000
export GITEA_URL=http://${GITEA_CONTAINER_NAME}:${GITEA_PORT}
export PROJECT_NAME=reproduce



# Spin up a fresh instance of Gitea with Postgres using Docker Compose (version is set in .env)
. .env
docker pull gitea/gitea:${GITEA_VERSION}-rootless
docker compose -p ${PROJECT_NAME} down -v
docker compose -p ${PROJECT_NAME} up --build -d --wait --wait-timeout 120

# Create a user for interacting with the new instance
export RUN_ON_STACK="docker compose -p ${PROJECT_NAME} exec -it "
${RUN_ON_STACK} gitea gitea admin user create --admin --username ${USERNAME} --password ${PASSWORD} --email admin@localhost.not

# Create an access token for later use
TOKEN=$(${RUN_ON_STACK} gitea gitea admin user generate-access-token --username ${USERNAME} --token-name tea --scopes all | cut -d':' -f2 | xargs | tr -d '\r' )

# On a client container run commands against the newly created instance of Gitea using plain Git and the CLI tool tea
${RUN_ON_STACK} client /bin/ash -c "
    # Create a repository with a dummy file
    mkdir /git/${REPO_NAME}
    cd /git/${REPO_NAME}
    git config --global init.defaultBranch main
    git config --global user.email 'notreal@fake.tld'
    git config --global user.name 'Fake Name'
    git init . 
    echo testcontent > testfile
    git add testfile
    git commit -m'Add testfile'
    git remote add origin http://${USERNAME}:${PASSWORD}@${GITEA_CONTAINER_NAME}:${GITEA_PORT}/${USERNAME}/${REPO_NAME}
    git push origin main

    # Use the previously generated token for further use with tea
    tea login add --token ${TOKEN} --name ${USERNAME} --url ${GITEA_URL}
    tea login default ${USERNAME}
    # On some runs tea reported the repo to be empty at this point, a short sleep should work around that issue
    sleep 2
    # Create a release in draft mode
    tea release create --login ${USERNAME} --repo ${USERNAME}/${REPO_NAME} --draft --title 'Test release (draft)' --tag draftReleaseTag --asset testfile
    # Create a release without draft flag set
    tea release create --login ${USERNAME} --repo ${USERNAME}/${REPO_NAME} --title 'Test release' --tag releaseTag --asset testfile
    tea release ls --login ${USERNAME} --repo ${USERNAME}/${REPO_NAME}
    # Try to download both assets
    curl http://${USERNAME}:${PASSWORD}@${GITEA_CONTAINER_NAME}:${GITEA_PORT}/${USERNAME}/${REPO_NAME}/releases/download/releaseTag/testfile
    curl http://${USERNAME}:${PASSWORD}@${GITEA_CONTAINER_NAME}:${GITEA_PORT}/${USERNAME}/${REPO_NAME}/releases/download/draftReleaseTag/testfile
    "
docker compose -p ${PROJECT_NAME} logs --no-log-prefix --no-color gitea > gitea-${GITEA_VERSION}.log