#!/bin/bash

set -e

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
. ./scripts/commons4gradle.sh
perl -pe "s/^VERSION_NAME.*/VERSION_NAME=$VERSION/g" -i gradle.properties
replaceOSSbyBintrayRepository "*.gradle"
replaceOSSbyBintrayRepository "gradle/*.gradle"

# TODO: Remove when releasing 0.11.0
cp $BASEDIR/arrow-master/gradle/apidoc-creation.gradle $BASEDIR/arrow/doc-conf.gradle

# TODO: Refactor when releasing 0.11.0
for repository in $(cat $BASEDIR/arrow/lists/libs.txt); do
    cd $BASEDIR/$repository
    git checkout .
    git checkout $(git tag -l --sort=version:refname ${VERSION}* | tail -1)
    replaceGlobalPropertiesbyLocalConf gradle.properties
    if [ -f arrow-docs/build.gradle ]; then
        replaceOSSbyBintrayRepository arrow-docs/build.gradle
    fi
    addArrowDocs $BASEDIR/$repository/settings.gradle
    $BASEDIR/arrow-master/scripts/project-assemble.sh $repository
    $BASEDIR/arrow-master/scripts/project-run-dokka.sh $repository
    $BASEDIR/arrow-master/scripts/project-run-ank.sh $repository
    $BASEDIR/arrow-master/scripts/project-locate-doc.sh $repository
done
