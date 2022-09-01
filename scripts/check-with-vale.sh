#!/bin/bash

set -e

# list of *.adoc files excluding files in /rest_api, generated files, and deleted files
FILES=$(git diff --name-only HEAD~1 HEAD --diff-filter=d "*.adoc" ':(exclude)rest_api/*' ':(exclude)modules/example-content.adoc' ':(exclude)modules/oc-adm-by-example-content.adoc')

if [ -n "${FILES}" ] ;
    then
        echo "Validating language usage in added or modified asciidoc files with $(vale -v)"
        echo ""
        echo "==============================================================================================================================="
        echo "Read about the error terms that cause the build to fail at https://redhat-documentation.github.io/vale-at-red-hat/docs/reference-guide/termserrors/"
        echo "==============================================================================================================================="
        echo ""
        #clean out conditional markup
        sed -i -e 's/ifdef::.*\|ifndef::.*\|ifeval::.*\|endif::.*/ /' ${FILES}
        vale ${FILES} --minAlertLevel=error --glob='*.adoc' --no-exit
        echo ""
        if [ "$TRAVIS" = true ] ; then
            set -x
            #run vale again, and this time send to pipedream
            PR_DATA=''
            if [ "$1" == false ] ; then
                PR_DATA='{"PR": [{"Number": "None", "SHA": "None"}],'
            else
                PR_DATA='{"PR": [{"Number": "'"$1"'", "SHA": "'"$2"'"}]',
            fi
            echo "${PR_DATA}" > vale_errors.json
            ERROR_DATA=$(vale ${FILES} --minAlertLevel=error --glob='*.adoc' --output=JSON --no-exit)
            echo "${ERROR_DATA:1}" >> vale_errors.json
            curl -H "Content-Type: text/json" --data "@vale_errors.json" https://eox4isrzuh8pnai.m.pipedream.net
        fi
    else
        echo "No asciidoc files added or modified."
fi