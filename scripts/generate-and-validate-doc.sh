SHORT_VERSION=$(echo $version | cut -d. -f1-2)

cd $BASEDIR/arrow-site
git checkout .
cp sidebar/$SHORT_VERSION/* docs/_data/
sed -i "s/latest/$version/g" docs/_includes/_head-docs.html
./gradlew clean runAnk

cd $BASEDIR/arrow
git checkout .
git checkout $version
sed -i "s/^VERSION_NAME.*/VERSION_NAME=$version/g" gradle.properties
replaceOSSbyBintrayRepository generic-conf.gradle

# TODO: Remove when releasing 0.11.0
cp $BASEDIR/arrow-master/doc-conf.gradle $BASEDIR/arrow/

for repository in $(cat $BASEDIR/arrow/lists/libs.txt); do
    cd $BASEDIR/$repository
    git checkout .
    git checkout $version
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
