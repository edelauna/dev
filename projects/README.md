# PROJECTS/README
Place for repos to live on the file system. The docker containers are running rsync and looking for file changes, than reflecting those changes here.

Navigate to /src and git clone <repo>.

Note: When a container is docker-compose up sync is from host to container, while container is running sync is then one way from container to here... avoid making changes here... basically like a backup for the containers.