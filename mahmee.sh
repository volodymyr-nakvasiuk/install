#!/bin/bash
set -e

# Reset
Color_Off='\033[0m' # Text Reset

# Regular Colors
Black='\033[0;30m'  # Black
Red='\033[0;31m'    # Red
Green='\033[0;32m'  # Green
Yellow='\033[0;33m' # Yellow
Blue='\033[0;34m'   # Blue
Purple='\033[0;35m' # Purple
Cyan='\033[0;36m'   # Cyan
White='\033[0;37m'  # White

abort() {
    echo -e "$Purple$1$Color_Off\n" >&2
    exit 1
}

logProcess() {
    echo -e "$Cyan$1...$Color_Off"

    if [[ ! -z "$2" ]]; then
        echo -e "$Cyan$2:$Color_Off"
        read -n 1 -s -r -p "Press any key to continue..."
    fi

    echo -e ""
}

logSkipped() {
    echo -e "$Green$1.$Color_Off\n"
}

osNotSupported() {
    abort "Current script works only on Mac OS.\n$Green$1"
}

getOS() {
    case "$(uname -sr)" in
    Linux*icrosoft*) echo WSL ;;
    Linux*) echo Linux ;;
    Darwin*) echo Mac ;;
    CYGWIN* | MINGW* | MINGW32* | MSYS*) echo Windows ;;
    *) echo UNKNOWN ;;
    esac
}

installHomeBrew() {
    if ! command -v brew &>/dev/null; then
        logProcess "Installing HomeBrew" "Please, follow the instructions"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
    else
        logSkipped "HomeBrew already installed"
    fi

    logProcess "Updating HomeBrew"
    brew update
}

installGit() {
    if ! command -v git &>/dev/null; then
        logProcess "Installing Git"
        brew install git
    else
        logSkipped "Git already installed"
    fi
}

installDockerMac() {
    if ! command -v docker &>/dev/null; then
        logProcess "Installing Docker" "Please, follow the instructions"
        brew cask install docker

        runDockerGuiMac
    else
        logSkipped "Docker already installed"
    fi
}

runDockerGuiMac() {
    logProcess "Please return to this terminal after" "Opening Docker GUI"
    open -a Docker
}

installMkCert() {
    if ! command -v mkcert &>/dev/null; then
        logProcess "Installing MkCert"
        brew install mkcert
    else
        logSkipped "MkCert already installed"
    fi

    mkcert -install
}

installSshKeys() {
    echo -e "\n"
    if [ -f ~/.ssh/mahmee_bitbucket ]; then
        if [ -f ~/.ssh/mahmee_bitbucket.pub ]; then
            logSkipped "SSH keys already exists"
        else
            logProcess "Generate public SSH key"
            ssh-keygen -y -f ~/.ssh/mahmee_bitbucket >~/.ssh/mahmee_bitbucket.pub
        fi
    else
        logProcess "Generating new SSH keys"
        ssh-keygen -t ed25519 -b 4096 -f ~/.ssh/mahmee_bitbucket
        chmod 0600 ~/.ssh/mahmee_bitbucket
    fi

    echo "Your public key:"
    cat ~/.ssh/mahmee_bitbucket.pub
    echo ""

    if [[ ! -z $1 ]]; then
        # ssh -o "IdentitiesOnly=yes" -i ~/.ssh/mahmee_bitbucket -t git@bitbucket.org
        read -p "Did you already add this key to Bitbucket? (y/n)[n] " yn

        case $yn in
        y) logSkipped "Public SSH key already added to Bitbucket" ;;
        *) "$1" ;;
        esac
    fi
}

addSshPublicKeyMac() {
    cat ~/.ssh/mahmee_bitbucket.pub | pbcopy
    logProcess "Public key copied to Clipboard" "On Bitbucket, press 'Add Key', paste public key and save"
    open https://bitbucket.org/account/settings/ssh-keys/
}

installMahmee() {
    PROJECT_FOLDER="mahmee.localhost"

    read -p "Specify folder to clone \`$PROJECT_FOLDER\` into? [~/www/] " folder
    if [ -z $folder]; then
        folder="~/www/"
    fi

    # Add trailing slash if needed
    length=${#folder}
    last_char=${folder:length-1:1}
    [[ $last_char != "/" ]] && folder="$folder/"
    :

    if [ -d "$folder$PROJECT_FOLDER" ]; then
        logSkipped "$folder$PROJECT_FOLDER already exists"
        cd $folder$PROJECT_FOLDER
    else
        logProcess "Creating \`$folder\` if not exist"
        mkdir -p $folder
        cd $folder

        logProcess "Cloning docker configs repo"
        git clone git@bitbucket.org:mahmee/ci-cd.git mahmee.localhost
        cd ./mahmee.localhost
    fi

    # Loading product variables
    if [ -f ./config ]; then
        . ./config
    fi

    # Making scripts executable (just in case)
    chmod -R a+x $BIN_FOLDER/

    logProcess "Cloning all services repos"
    $BIN_FOLDER/checkout -b master

    logProcess "This process make take up to 20 minutes" "Downloading docker images, service's sources and libraries"
    $BIN_FOLDER/init --new-cert

    logProcess "Notice: there should be DB structure and data for correct work"
    while true; do
        read -p "If you want to create DB, pls, specify full path to dump file [skip] " path

        if [[ -z $path || $path == "skip" ]]; then
            logSkipped "
DB wasn't (re)created from dump
You can load your dump later by coping it to \`storage/dumps\` folder
And run docker/db {dumpFileName}
Example: \`docker/db mahmee-sanitized-2023-02-30-23-02.sql.bz2\`"
            break
        else
            if [ -f $path ]; then
                logProcess "Extracting dump"

                # Copy DB dump file into `storage/dumps` folder
                cp $path storage/dumps
                dumpFile=$(basename -- "$path")

                # Run dump load command
                docker/db $dumpFile

                break
            else
                echo -e "Dump file not found in $path. If you want to skip, just press enter:"
            fi
        fi
    done

    # Adding hosts to /etc/hosts
    for host in "${ALL_HOSTS[@]}"; do
        if grep -q "127.0.0.1 $host" /etc/hosts; then
            logSkipped "\`$host\` exists in /etc/hosts"
        else
            logProcess "Adding \`$host\` to /etc/hosts"
            echo "127.0.0.1 $host" >>/etc/hosts
        fi
    done

    logProcess "Starting Docker"
    docker/up
}

forWSL() {
    # TODO:
    # Check docker installed (if no: abort and ask to install)
    # Check mkcert installed (if no: abort and ask to install)
    # Add alias for mkcert
    # Check git installation with `apt`
    # installSshKeys
    # addSshPublicKeyWsl
    echo -e "Detected WSL\n"
    osNotSupported "Follow the instruction from https://bitbucket.org/mahmee/ci-cd/src/master/README.md"
}

forLinux() {
    echo -e "Detected Linux\n"
    osNotSupported "Follow the instruction from https://bitbucket.org/mahmee/ci-cd/src/master/README.md"
}

forMac() {
    installHomeBrew
    installDockerMac
    installMkCert
    installGit
    installSshKeys addSshPublicKeyMac

    installMahmee

    open "https://$URL_PATIENTS" "https://$URL_PROVIDERS"
}

forWindows() {
    # TODO: Ask to do preparation for Windows and use WSL
    echo -e "Detected Windows\n"
    osNotSupported "Follow the instruction from https://bitbucket.org/mahmee/ci-cd/src/master/README.md"
}

forUNKNOWN() {
    osNotSupported "Unknown OS"
}

"for$(getOS)"
