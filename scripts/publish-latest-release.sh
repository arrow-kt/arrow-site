#!/bin/bash

# Reason: it's not possible to sync all the directories because of 'docs/0.10', 'docs/next', etc.

set -e

cd _site/
for file in *; do
    if [ -f "$file" ]; then
        echo "Copying $file ..."
        echo "aws s3 cp $file s3://$S3_BUCKET/$file" >> $BASEDIR/logs/aws_sync.log
        #aws s3 cp $file s3://$S3_BUCKET/$file >> $BASEDIR/logs/aws_sync.log
        continue
    fi
    if [ "$file" != "docs" ]; then
        echo "Sync $file ..."
        echo "aws s3 sync $file s3://$S3_BUCKET/$file --delete" >> $BASEDIR/logs/aws_sync.log
        #aws s3 sync $file s3://$S3_BUCKET/$file --delete >> $BASEDIR/logs/aws_sync.log
        continue
    fi
    cd docs
    for docfile in *; do 
        if [ -f "$docfile" ]; then 
            echo "Copying $docfile ..."
            echo "aws s3 cp $docfile s3://$S3_BUCKET/docs/$docfile" >> $BASEDIR/logs/aws_sync.log
            #aws s3 cp $docfile s3://$S3_BUCKET/docs/$docfile >> $BASEDIR/logs/aws_sync.log
            continue
        fi
        echo "Sync $docfile ..."
        echo "aws s3 sync $docfile s3://$S3_BUCKET/docs/$docfile --delete" >> $BASEDIR/logs/aws_sync.log
        #aws s3 sync $docfile s3://$S3_BUCKET/docs/$docfile --delete >> $BASEDIR/logs/aws_sync.log
    done
done
