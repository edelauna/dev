#!/bin/bash
# Colours - all bold
export GREEN="\033[1;32m"
export YELLOW="\033[1;33m"
export ORANGE="\033[1;33m"
export RED="\033[1;31m"
export BLUE="\033[1;34m"
export MAGENTA="\033[1;35m"
export NO_COLOUR="\033[0m"

COLOURS=("$GREEN" "$YELLOW" "$ORANGE" "$RED" "$BLUE" "$MAGENTA")

size=${#COLOURS[@]}
index=$((RANDOM % size))
REPOC="${COLOURS[$index]}${REPO^^}${NO_COLOUR}:::"

REPO_SETUP_PATH="/home/dev/.${REPO}setup"
echo -e "⏱⏱⏱  STATUS: $REPOC Initiatizing at: $REPO_SETUP_PATH  ⏱⏱⏱"

echo -e "${RED}=======================================\n${NO_COLOUR}\
${RED}===  ${NO_COLOUR}Please Wait for Ready Message  ${RED}===\n${NO_COLOUR}\
${RED}===  ${NO_COLOUR}Before Attaching to Container  ${RED}===\n${NO_COLOUR}\
${RED}=======================================${NO_COLOUR}"

# Pull in installed files
source /home/dev/.profile

# $1 Should be the version of rails to install
install_and_use_ruby() {
    echo -e "⏱⏱⏱  STATUS: $REPOC Ruby v$1 Initiazing  ⏱⏱⏱"
    rbenv install -s "$1" >/dev/null
    rbenv local "$1"
}

### Not sure I need this.
## Thinks it run automatically...
gpg_run() {
    local gpg_conf_path="/home/dev/.gnupg/gpg-agent.conf"
    if [ -f .gnupg/gpg-agent.conf ]; then
        echo -e "⏱⏱⏱  STATUS: $REPOC Starting GPG-Agent ⏱⏱⏱"
        gpg-connect-agent reloadagent /bye >/dev/null 2>&1

        ## Setup automated passphrases for gpg via gpg-agent
        local gpg_passphrase_path="/run/secrets/gpg_passphrase"
        if [ -f "$gpg_passphrase_path" ]; then
            local parsed_key
            parsed_key=$(gpg --with-colons --import-options show-only --import /run/secrets/gpg_private_key | cut -d: -f 10)
            local private_keygrip
            private_keygrip=$(echo "$parsed_key" | awk 'FNR == 3 {print}')
            /usr/lib/gnupg2/gpg-preset-passphrase -c "$private_keygrip" <"$gpg_passphrase_path"
        else
            echo -e "⏱⏱⏱  STATUS: $REPOC Configuring GPG::Unable to import private key ⏱⏱⏱"
            echo -e "⏱⏱⏱  STATUS: $REPOC Configuring GPG::Need to Manually setup GPG ⏱⏱⏱"
        fi
        echo -e "⏱⏱⏱  STATUS: $REPOC GPG-Agent Reloaded ⏱⏱⏱"
    fi
}

gpg_setup() {
    # Check if gpg_conf exists - if not configure for promptless
    local gpg_conf_path="/home/dev/.gnupg/gpg-agent.conf"

    # Startup gpg
    gpg --list-keys >/dev/null 2>&1

    if [ ! -f "$gpg_conf_path" ]; then
        echo -e "⏱⏱⏱  STATUS: $REPOC Configuring GPG ⏱⏱⏱"
        cat >"$gpg_conf_path" <<-EOM
				allow-preset-passphrase
				batch
EOM

        echo -e "GPG_TTY=$(tty)\nexport GPG_TTY" >>/home/dev/.zshrc

        ## Restart gpg-agent after creating config
        gpg_run

        ## Import private key now that passphrase is preset
        gpg --import --batch /run/secrets/gpg_private_key >/dev/null 2>&1

        local parsed_key
        parsed_key=$(gpg --with-colons --import-options show-only --import /run/secrets/gpg_private_key | cut -d: -f 10)
        local private_keygrip
        private_keygrip=$(echo "$parsed_key" | awk 'FNR == 3 {print}')
        local signingKey
        signingKey=$(echo "$parsed_key" | awk 'FNR == 2 {print}')
        local useremail
        useremail=$(echo "$parsed_key" | awk 'FNR == 4 {print}' | sed -e 's/.*<\(.*\)>.*/\1/')
        local username
        username=$(echo "$parsed_key" | awk 'FNR == 4 {print}' | sed 's/[\(|<].*//')

        git config --global user.signingkey "$signingKey"
        git config --global commit.gpgsign true
        git config --global user.email "$useremail"
        git config --global user.name "$username"

        # Add a alias to rehydrate cache
        cat >>/home/dev/.alias <<-EOM
	    alias 'gpg-up'="gpg-connect-agent reloadagent /bye && \
        /usr/lib/gnupg2/gpg-preset-passphrase -c $private_keygrip < /run/secrets/gpg_passphrase"
EOM
    fi
}

### Pre-req: Function must be called from repo working directory
default_ruby_setup() {

    install_and_use_ruby "2.7.4"

    # VSCODE specific gems for debugging
    gem install solargraph ruby-debug-ide debase rubocop

    solargraph bundle
}

default_entry() {

    # Some dev setup
    echo -e "⏱⏱⏱  STATUS: $REPOC File Sync Initiazing ⏱⏱⏱"
    sudo chown -R dev:dev /home/dev

    # Check if dev user has been setup - if not run shared-setup
    if [ ! -f /home/dev/.setup ]; then
        cd /home/dev/ || exit 1
        mkdir -p ".ssh"

        echo -e "⏱⏱⏱  STATUS: $REPOC SSH and GPG Initiazing ⏱⏱⏱"
        ## SSH setup
        chmod 700 .ssh
        cp /run/secrets/id_rsa .ssh/id_rsa
        chmod 600 .ssh/id_rsa
        ssh-keygen -y -f .ssh/id_rsa >.ssh/id_rsa.pub
        cat .ssh/id_rsa.pub >.ssh/authorized_keys
        chmod 644 .ssh/id_rsa.pub .ssh/authorized_keys

        ## Setup gpg if private key found.
        [ -f /run/secrets/gpg_private_key ] && gpg_setup

        # Update .zlogin to move immediately to proj dir o login
        echo "cd /home/dev/${REPO}" >>.zlogin

        touch .setup

        echo -e "⏱⏱⏱  STATUS: $REPOC Initializing Project Specific Dependancies  ⏱⏱⏱"
    fi
}

# This function allows for specificying an environment variable in
# the docker-compose file, which must in _ENVAR. The function
# will look for those functions and then export a environment
# variable without the _ENVAR portion and reading contents
# from a secret (which must be the value of the _ENVAR
# environment variable).
# Todo: tests if this works with vscode terminal setup
export_runtime_envvars() {
    env | grep ".*_ENVAR.*" | while IFS= read -r line; do
        secret=${line#*=}
        new_environment_variable=${line%%_WS_ENVAR*}
        echo "export ${new_environment_variable}=\$(cat /run/secrets/${secret})" >>/home/dev/.profile
    done
}

fin() {
    echo -e "⏱⏱⏱  STATUS: $REPOC Starting SSH Server  ⏱⏱⏱"
    gpg_run
    # Start SSH to be able to move between containers
    sudo service ssh restart
    # echo -e "[${GREEN}✓${NO_COLOUR}] STATUS: $REPOC READY!"
}
