#!/bin/bash

set -e
. $BASEDIR/arrow/scripts/commons4gradle.sh

echo "For version: $VERSION ..."
SHORT_VERSION=$(echo $VERSION | cut -d. -f1-2)

cd $BASEDIR/arrow-site
git checkout .
cp sidebar/$SHORT_VERSION/* docs/_data/
perl -pe "s/latest/$VERSION/g" -i docs/_includes/_head-docs.html
./gradlew clean runAnk

cd $BASEDIR/arrow
git checkout .
git checkout $VERSION
perl -pe "s/^VERSION_NAME.*/VERSION_NAME=$VERSION/g" -i gradle.properties
replaceOSSbyBintrayRepository generic-conf.gradle

for repository in $(cat $BASEDIR/arrow/lists/libs.txt); do
    cd $BASEDIR/$repository
    git checkout .
    git checkout $VERSION
    replaceGlobalPropertiesbyLocalConf gradle.properties
    if [ -f arrow-docs/build.gradle ]; then
        replaceOSSbyBintrayRepository arrow-docs/build.gradle
    fi
    addArrowDocs $BASEDIR/$repository/settings.gradle
    $BASEDIR/arrow/scripts/project-assemble.sh $repository
    $BASEDIR/arrow/scripts/project-run-dokka.sh $repository
    $BASEDIR/arrow/scripts/project-run-ank.sh $repository
    $BASEDIR/arrow/scripts/project-locate-doc.sh $repository
done
