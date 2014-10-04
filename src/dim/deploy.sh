#!/bin/bash
set -e

DEV_DIR=/srv/html/dim_dev
STAGE_DIR=/srv/html/dim_stage
PROD_DIR=/srv/html/dim

DIM_SITE_REPO=https://github.com/parente/dim-site.git
DIM_GAME_REPO=https://github.com/parente/dim-game.git

function usage() {
    cat <<-EOT
Manage DIM deployment.

usage $0 [dev|stage|prod] [dim-site tag/branch] [dim-game tag/branch]

EOT
}

function deploy() {
    local site_branch=$1
    local game_branch=$2
    local deploy_dir=$3

    # clear dir of all but hidden files
    if [ "$(ls $deploy_dir)" ]; then
	   rm -r "$deploy_dir"/*
	   echo "==> Cleared $deploy_dir"
    fi

    # build working directory
    local dirty_dir=$(mktemp -d)
    echo "==> Created $dirty_dir"

    # clone site into dirty directory
    cd $dirty_dir
    git clone --depth=1 $DIM_SITE_REPO dim-site
    echo "==> Cloned $DIM_SITE_REPO"

    # export archive of site to dev dir
    cd dim-site
    git archive $site_branch | tar -x -C "$deploy_dir"
    echo "==> Archived $site_branch to $deploy_dir"

    # clone game into dirty directory
    cd $dirty_dir
    git clone $DIM_GAME_REPO dim-game
    echo "==> Cloned $DIM_GAME_REPO"

    # build game in dirty directory
    cd dim-game/dev
    git checkout $game_branch
    bash build.sh $game_branch
    echo "==> Built $game_branch tag/branch"

    # move game build into deploy directory
    mv ../webapp.build "$deploy_dir/webapp"
    echo "==> Moved game build to $deploy_dir"

    # save version info to hidden file
    echo "site=$site_branch game=$game_branch" > "$deploy_dir/.version"

    # fix permissions
    chgrp -R www-data "$deploy_dir"
    chmod -R go-w "$deploy_dir"

    # clean up the working directory
    rm -rf $dirty_dir
    echo "==> Removed $dirty_dir"
}

function dev() {
    echo "==> Deploying to development area"
    deploy master master $DEV_DIR
    echo "==> SUCCESS"
    cat "$DEV_DIR/.version"
}

function stage() {
    echo "==> Deploying to staging area"
    if [ -z "$1" -o -z "$2" ]; then
    	echo "==> ERROR: must specify site and game tag/branch"
        usage
    	exit 1
    fi
    deploy $1 $2 $STAGE_DIR
    echo "==> SUCCESS"
    cat "$STAGE_DIR/.version"
}

function prod() {
    echo "==> Deploying to production"
    if [ ! -f "$STAGE_DIR/.version" ]; then
    	echo "==> ERROR: must stage before deploying to production"
    	exit 2
    fi

    # clear prod dir of all but hidden files
    if [ "$(ls $PROD_DIR)" ]; then
    	rm -r "$PROD_DIR"/*
    	echo "==> Cleared $PROD_DIR"
    fi

    # copy staging area to production area
    cp -r "$STAGE_DIR"/* "$PROD_DIR/"
    cp "$STAGE_DIR/.version" "$PROD_DIR/"
    echo "==> Copied staging area to production"

    echo "==> SUCCESS"
    cat "$PROD_DIR/.version"
}

if [ "$1" == "dev" ]; then
    dev
elif [ "$1" == "stage" ]; then
    stage $2 $3
elif [ "$1" == "prod" ]; then
    prod
else
    usage
    exit 1
fi
