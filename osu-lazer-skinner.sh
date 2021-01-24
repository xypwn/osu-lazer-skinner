#!/usr/bin/env sh
###
# Variables
###
# Disable dotnet telemetry spook
export DOTNET_CLI_TELEMETRY_OPTOUT=1

OSU_REPO='https://github.com/ppy/osu'
OSU_RESOURCES_REPO='https://github.com/ppy/osu-resources'

INTERNAL_FILE_DIR='internal_files'
SKIN_BACKUP_DIR="$INTERNAL_FILE_DIR/legacy_skin_backup"
SKIN_TMP_DIR="$INTERNAL_FILE_DIR/skin_tmp_files"

###
# Functions
###
msg() {
    echo -e "\e[32;1m>>> $@\e[m"
}

msg_err() {
    echo -e "\e[31;1m>>> $@\e[m"
}

die() {
    msg_err "An error occurred while \e[3m$CURR_ACTION"
    exit 1
}

usage() {
    echo "sh osu-lazer-skinner.sh <OPTION> [SKIN FILE]
Basic Options:
    download                -  Download and prepare osu source files
    apply_skin <SKIN FILE>  -  Apply a skin to the downloaded source code
    build                   -  Build osu from the source code that has already been downloaded
    install                 -  Install osu (after running with all)
    uninstall               -  Uninstall osu (if it's already installed)
    restore                 -  Restore default skin
    clean                   -  Clean temporary build files
    clean_full              -  Clean all osu files, including those downloaded"
}

clean() {
    CURR_ACTION="cleaning build files"
    rm -rf osu-resources/osu.Game.Resources/obj/* \
	osu-resources/osu.Game.Resources/bin/* \
	osu/osu.Desktop/bin/* \
	osu/osu.Desktop/obj/* \
	osu/compiled
}

clean_full() {
    CURR_ACTION="cleaning all downloaded files"
    rm -rf osu/
    rm -rf osu-resources/
    rm -rf "$INTERNAL_FILE_DIR"
}

download_osu() {
    CURR_ACTION="downloading osu"
    git clone "$OSU_REPO"
}

download_osu_resources() {
    CURR_ACTION="downloading osu-resources"
    git clone "$OSU_RESOURCES_REPO"
}

prepare() {
    CURR_ACTION="preparing resources"
    pushd osu/
    # Use local resources, instead of those fetched through NuGet
    CSPROJ="osu.Game/osu.Game.csproj"
    SLN="osu.sln"
    dotnet remove $CSPROJ package ppy.osu.Game.Resources;
    dotnet sln $SLN add ../osu-resources/osu.Game.Resources/osu.Game.Resources.csproj
    dotnet add $CSPROJ reference ../osu-resources/osu.Game.Resources/osu.Game.Resources.csproj
    popd
}

backup_default_skin() {
    CURR_ACTION="backing up the default skin"
    rm -rf "$SKIN_BACKUP_DIR/"
    mkdir -p "$SKIN_BACKUP_DIR/"
    mv osu-resources/osu.Game.Resources/Skins/Legacy/* "$SKIN_BACKUP_DIR/"
}

apply_skin() {
    CURR_ACTION="applying the skin"
    local SKIN_FILE="$1"
    # Delete previous skin from game files
    rm -rf osu-resources/osu.Game.Resources/Skins/Legacy/*

    rm -rf "$SKIN_TMP_DIR/"
    mkdir -p "$SKIN_TMP_DIR/"
    bsdtar -xf "$SKIN_FILE" -C "$SKIN_TMP_DIR/"
    find "$SKIN_TMP_DIR/" -type f -exec mv {} osu-resources/osu.Game.Resources/Skins/Legacy/ \;
}

build() {
    CURR_ACTION="building"
    pushd osu/
    # Start build
    dotnet publish osu.Desktop \
	--no-self-contained --configuration Release \
	--runtime $(dotnet --info | grep 'RID' | cut -d ':' -f 2 | tr -d ' ') \
	--output compiled
    popd
}

restore() {
    CURR_ACTION="restoring the default skin"
    # Delete previous skin from game files
    rm -rf osu-resources/osu.Game.Resources/Skins/Legacy/*

    cp -r $SKIN_BACKUP_DIR/* osu-resources/osu.Game.Resources/Skins/Legacy/
}

###
# Functions associated with command line options
###
opt_install() {
    [ ! "$USER" = "root" ] && msg_err "Please run install as root" && exit 1
    msg "Installing osu..."
    # Launcher script
    install -Dm755 osu-lazer.sh /usr/bin/osu-lazer
    # Icon
    install -Dm644 osu/assets/lazer.png /usr/share/pixmaps/osu-lazer.png
    # Desktop entry
    install -Dm644 osu-lazer.desktop /usr/share/applications/osu-lazer.desktop
    # Libraries
    pushd osu/compiled
    find . -type f -exec install -Dm644 "{}" "/usr/lib/osu-lazer/{}" \;
    popd
}

opt_uninstall() {
    [ ! "$USER" = "root" ] && msg_err "Please run uninstall as root" && exit 1
    msg "Uninstalling osu..."
    rm /usr/bin/osu-lazer
    rm /usr/share/pixmaps/osu-lazer.png
    rm /usr/share/applications/osu-lazer.desktop
    rm -rf /usr/lib/osu-lazer
}

opt_clean() {
    msg "Cleaning temporary build files..."
    clean || die
}

opt_clean_full() {
    msg "Cleaning all downloaded files..."
    clean_full || die
}

opt_download() {
    if [ ! -d osu/ ]; then
	msg "Downloading osu..."
	download_osu || die
    else
	msg "Already downloaded osu"
    fi

    if [ ! -d osu-resources/ ]; then
	msg "Downloading osu-resources..."
	download_osu_resources || die
	msg "Preparing project to use local resources..."
	prepare || die
	msg "Backing up default classic skin..."
	backup_default_skin || die
    else
	msg "Already downloaded osu-resources"
    fi
}

opt_apply_skin() {
    local SKIN_FILE="$1"
    [ ! -f "$SKIN_FILE" ] && msg_err "Skin file \e[m'$SKIN_FILE'\e[31;1m does not exist" && exit 1
    msg "Applying skin: \e[m$(basename "$SKIN_FILE")"
    apply_skin "$1" || die
    msg "The osu classic skin has now been replaced with the selected skin"
}

opt_build() {
    msg "Cleaning previous build files"
    clean || die
    msg "Building osu"
    build || die
}

opt_restore() {
    msg "Restoring original classic skin"
    restore || die
}

###
# Main script
###
# TODO: Fix path for absolute paths
ORIG_WORKING_DIR="$PWD"

# Make the working directory equivalent to the script directory
cd "$(dirname "$0")"

# Define command line options
OPTION="$1"
OPTION_SKIN="$2"
# Make path relative to the original working directory
[ ! "${OPTION_SKIN::1}" = "/" ] &&
    OPTION_SKIN_PATH="$ORIG_WORKING_DIR/$OPTION_SKIN" ||
    OPTION_SKIN_PATH="$OPTION_SKIN"
# Parse arguments
case "$OPTION" in
    --help|-h|help)
	usage
	;;
    download)
	opt_download
	;;
    apply_skin)
	[ -z "$OPTION_SKIN" ] && msg_err "Please specify a skin to apply" && exit 1
	opt_apply_skin "$OPTION_SKIN_PATH"
	;;
    build)
	opt_build
	;;
    install)
	opt_install
	;;
    uninstall)
	opt_uninstall
	;;
    restore)
	opt_restore
	;;
    clean)
	opt_clean
	;;
    clean_full)
	opt_clean_full
	;;

    *)
	usage
	exit 1
	;;
esac
