# Install brew: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"`
# Edit your `hosts`
# Install git: `brew install git`
# ssh-keygen -t ed25519 -b 4096 -f ~/.ssh/mahmee_bitbucket`
# Copy to clipboard `cat ~/.ssh/mahmee_bitbucket.pub | pbcopy`
# Add mahmee_bitbucket.pub to bitbucket: `open https://bitbucket.org/account/settings/ssh-keys/#add-key`
# Install Docker: `brew cask install docker`
# Start Docker `open -a Docker`
# Install mkcert: `brew install mkcert`
# Install mkcert CA: `mkcert -install`
# Clone this repo: `git clone git@bitbucket.org:mahmee/ci-cd.git mahmee.localhost`
# Go to the repo’s root folder: `cd ./mahmee.localhost`
# `chmod -R a+x docker/`
# `docker/init --new-cert`
# Copy DB dump file into `storage/dumps` folder
# `docker/db mahmee-sanitized-20??-??-??-??-??.sql.bz2`
# `docker/up`
# open https://mahmee.localhost https://network.mahmee.localhost
