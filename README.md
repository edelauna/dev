# Portable Local Dev Environment

Playing around with a docker local development setup.

## How to Use

`Dockerfile-dev` is actually setup as an image to remote into (via SSH, or VSCode Remote Development Plugin), currently it's setup for the following types of development:
* Ruby
* JS
* Rust

`docker-compose.yml` can be used to network together differant apps, for example add a postgres or redis image.

`.secrets/` folder is where you can put ssh and gpg keys for working with github.

`bin/` folder is where docker-entrypoint and docker-setup scripts go for custom logic required. Also includes a binary `simplesync` which faciliates data syncing between container and host system. 

`.zshrc` is a file to use some zsh plugins, and customize the shell prompt while in the container.

`projects/` folder is where the files from within docker are synced to.
