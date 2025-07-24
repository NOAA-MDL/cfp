#!/bin/bash
set -x
: echo 'this should be run as a user first to setup and check
the stage directory for correctness.
Then run it on a cron node as root to do a reall install
'

#a bit of a hack needed until the final deploy method is settled
#specify right here if this is a "final" deploy or a "staged" deploy
DEPLOY_TYPE=final
#DEPLOY_TYPE=stage


#try to make this reusable elsewhere
PRODUCT_NAME=cfp

INSTALL_USER=hpc-adm
INSTALL_GROUP=hpc-adm
INSTALL_GROUP_DOCS=hpc-adm

#run as local user into a stage dirctory or as root into final install
#since root can't do stuff needed on cron nodes we need
#do strip out the stage root from the distribution locations
#in the man and sample files.
STAGE_DIR=$(pwd)/stage
#stage root gets used to strip the stage dir off of the text locations
#in the man and README files
STAGE_ROOT=$STAGE_DIR
#load the module environment used for the build and
#query the versions of stuff to build the install path
#the two extra vars are needed to setup the env.sh file
#WHAT A HACK! this is just to deal with apps dir ro mode on login nodes
#and running from a cron node that does not have modules
if [ $DEPLOY_TYPE = "final" ];then
    if [ ! -d $STAGE_DIR ];then
        echo NOTHING STAGED.  ABORTING DEPLOY.
        exit
    fi
    unset STAGE_DIR #put it in the final location
    CURRENT_VERSION=$(cat current_version.txt)
    if [[ "$CURRENT_VERSION" =~ "-" ]];then
        echo Git tag must be on current commit.  ABORTING.
        exit
    fi
    PROGENV=$(cat progenv.txt)
    PROGENV_VERSION=$(cat progenv_version.txt)
else
    #now spiff things up before we send things out if not root
    ./clean.sh
    ./build.sh
    ./sample.sh
    #extract the current version from the last git tag in the branch
    CURRENT_VERSION=$(git describe --tags)
echo $CURRENT_VERSION
    CURRENT_VERSION=${CURRENT_VERSION%%-*} #strip off the git increment stuff
echo $CURRENT_VERSION
    PROGENV=$(source support/env.sh;module list -t | egrep "^intel/" | cut -d'-' -f2 | cut -d'/' -f1)
echo $PROGENV
    PROGENV_VERSION=$(source support/env.sh;module list -t | egrep "^intel/" | cut -d'-' -f2 | cut -d'/' -f2)
echo $PROGENV_VERSION
    echo $PROGENV > progenv.txt
    echo $PROGENV_VERSION > progenv_version.txt
    echo $CURRENT_VERSION > current_version.txt
fi

#this is all a bit of a mess becase there are multiple
#destinations for module files and samples
#THE ROOTS FOR THE INSTALL two main locations PROD and DOCS
PROD_DIR=$STAGE_DIR/apps/prod
DOCS_DIR=$STAGE_DIR/apps/docs/samples/intel


BASE_INSTALL=$PROD_DIR/$PRODUCT_NAME/$CURRENT_VERSION/$PROGENV/$PROGENV_VERSION

#based on all of that above, setup the final targets
TARGET_BIN=$BASE_INSTALL/bin
TARGET_MAN=$BASE_INSTALL/man/man1
#for completeness put two copies of the samples out there
TARGET_SAMPLES=$BASE_INSTALL/samples
TARGET_DOCS=$DOCS_DIR/${PRODUCT_NAME}-job
#THE MODULES ARE AT A HIGHER LEVEL
TARGET_MODULES=${PROD_DIR}/modules/$PRODUCT_NAME
TARGET_LMODULES=${PROD_DIR}/lmodules/core/$PRODUCT_NAME
#all the target variables are set
#up to this poing we have taken no actions

read junk

#NOW INSTALL EVERYTHING for clarity explicily create the directories
#instead of allowing install to do it below
install -d -o $INSTALL_USER -g $INSTALL_GROUP $TARGET_BIN
install -d -o $INSTALL_USER -g $INSTALL_GROUP $TARGET_MAN
install -d -o $INSTALL_USER -g $INSTALL_GROUP $TARGET_MODULES
install -d -o $INSTALL_USER -g $INSTALL_GROUP $TARGET_LMODULES
install -d -o $INSTALL_USER -g $INSTALL_GROUP $TARGET_SAMPLES
install -d -o $INSTALL_USER -g $INSTALL_GROUP_DOCS $TARGET_DOCS

install -p -m 755 -o $INSTALL_USER -g $INSTALL_GROUP ./bin/$PRODUCT_NAME $TARGET_BIN
#for completeness put two copies of the samples out there
install -p -m 755 -o $INSTALL_USER -g $INSTALL_GROUP ./sample/* $TARGET_SAMPLES
install -p -m 755 -o $INSTALL_USER -g $INSTALL_GROUP_DOCS ./sample/* $TARGET_DOCS

tmpfile=$(mktemp tmpfile.XXXXXX)
sed -e "s@EXAMPLES_DIR_PLACEHOLDER@${TARGET_DOCS#$STAGE_ROOT}@" ./support/${PRODUCT_NAME}.1 > $tmpfile 
install -p -m 744 -o $INSTALL_USER -g $INSTALL_GROUP $tmpfile $TARGET_MAN/${PRODUCT_NAME}.1


#trim the tail off of the man dir for use in the module file
TARGET_MAN=${TARGET_MAN%/man1}
sed -e "s@DOCS_PLACEHOLDER@${TARGET_DOCS#$STAGE_ROOT}@g" \
    -e "s@MAN_PLACEHOLDER@${TARGET_MAN#$STAGE_ROOT}@g" \
    -e "s@BIN_PLACEHOLDER@${TARGET_BIN#$STAGE_ROOT}@g" ./support/module_template > $tmpfile
install -p -m 755 -o $INSTALL_USER -b $NSTALLL_GROUP $tmpfile $TARGET_MODULES/$CURRENT_VERSION
install -p -m 755 -o $INSTALL_USER -b $NSTALLL_GROUP $tmpfile $TARGET_LMODULES/$CURRENT_VERSION
rm -f $tmpfile

