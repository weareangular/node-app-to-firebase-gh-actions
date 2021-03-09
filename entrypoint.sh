#!/bin/bash
#
#===================================
set -e
#===================================
#==============HELP=================
#===================================
help() {
  cat << EOF
usage: $0 [OPTIONS]
    --h                                                                       Show this message 
    --deploy-function [DEFAULT_APP_NAME] [DEFAULT_APP_FILENAME] [PROJECT_ID] [REGION] [MEMORY] [TIMEOUT]  deploy Typescript Node.js app on firebase as function
                                                                                [DEFAULT_APP_NAME] => variable name express, 'app' by default.
                                                                                [DEFAULT_APP_FILENAME] => name of the file that contains the express variable, 'app.ts' by default (if you want to define this variable you must define the previous ones).
                                                                                [PROJECT_NAME] => name of the function to be displayed (if you want to define this variable you must define the previous ones).
EOF
}
#===================================
#==============INIT=================
#===================================
checkenvvariables(){  
    [[ -z $FIREBASE_TOKEN ]] \
        && { echo -e "\nEither FIREBASE_TOKEN is required to run commands with the firebase cli"; exit 126; }
    [[ -z $PROJECT_ID ]] \
        && { echo -e "\nEither PROJECT_ID is required"; exit 126; }
    [[ -z $REGION ]] \
        && { REGION="us-central1"; }
    [[ -z $MEMORY ]] \
        && { MEMORY="128MB"; }
    [[ -z $TIMEOUT ]] \
        && { TIMEOUT="300"; }
    return 0
}
#===================================
showinit(){
    echo -e "\nStarting Firebase Cli\n"
    return 0
}
#===================================
init(){
    showinit
    checkenvvariables
    return 0
}
#===================================
#============GENERAL================
#===================================
createfolder(){
    [[ -z $1 ]] \
        && { echo "you must provide a name to create the folder"; exit 126; } \
        || { [[ ! -d $1 ]] && { mkdir $1; return 0; } }
    return 0
}
#===================================
createfile(){
    [[ -z $1 ]] \
        && { echo "you must provide a name to create the file"; exit 126; } \
        || { [[ -z $2 ]] && { printf "" > $1; } || { printf "${2}" > $1; }; }
    return 0
}
#===================================
copyfolderelements(){
    [[ -z $1 ]] \
        && { echo "you must provide the name of the folder to copy"; exit 126; } \
        || { [[ -z $2 ]] && { cp -R $1/. .;} || { cp -R $1/. $2; }; }
    return 0
}
#===================================
copyfile(){
    [[ -z $1 ]] \
        && { echo "you must provide a name to copy the file"; exit 126; } \
        || { cp $1 .; }
    return 0
}
#===================================
#======DEPLOYNODEJSTYPESCRIPT=======
#===================================
checkbuilddir(){
    [[ ! $(cat ${dirtsconfigjson} | jq -r "${jqfieldtsconfigjson}") == "${outDir}" ]] \
        && { sed -i -- "s~$(cat ${dirtsconfigjson} | jq -r "${jqfieldtsconfigjson}")~${outDir}~g" "${dirtsconfigjson}"; }
    [[ ! $(cat ${dirpackagejson} | jq -r "${jqfieldpkgjson}") == "${outDirmain}" ]] \
        && { sed -i -- "s~$(cat ${dirpackagejson} | jq -r "${jqfieldpkgjson}")~${outDirmain}~g" "${dirpackagejson}"; }
    return 0
}
#===================================
rebornpackage(){
    package=$(cat "${dirpackagejson}" | jq --arg keys "$packagekeys" "$jqfilter")
    package=$(echo "${package}" | jq "$jqfilter2")
    echo $package > package.json
    return 0
}
#===================================
deletelistenport(){
    sed -i "${sedfilterport2}" ${dirdefaultexportfile}
    sed -zi "${sedfilterport}" ${dirdefaultexportfile}
    return 0
}
#===================================
checkexportapp(){
    [[ ! $(tail -1 $dirdefaultexportfile ) == $defaultexportstring ]] \
        && { echo -e $defaultexportstring >> $dirdefaultexportfile; }
    return 0
}
#===================================
getprojectname(){
    [[ -z $projectname ]] \
    && { projectname=$(cat $dirpackagejson | jq -r '.name' | sed -E 's/[^[:alnum:]]+//g'); } \
    || { projectname=$(echo "${projectname}" | sed -E 's/[^[:alnum:]]+//g'); }
    return 0
}
#===================================
setfirebaseproject(){
    [[ ! $(echo $PWD) == $dirproject ]] \
        && { cd $dirproject; firebase use --add "$PROJECT_ID"; }
    return 0
}
#===================================
projectlayer(){
    [[ ! -d $dirproject ]] \
        && { createfolder "${dirproject}"; }
    cd $dirproject
    return 0
}
#===================================
firstlayer(){
    [[ ! $(echo $PWD) == $dirproject ]] \
        && { cd $dirproject; }
    [[ -d $firstlayerfoldername ]] \
        && rm -r $firstlayerfoldername
    createfolder "${firstlayerfoldername}"
    createfile "${filenamefirebasejson}" "${firebasejsoncontent}"
    createfile "${filenamefirebaserc}" "${firebaserccontent}"
    return 0
}
#===================================
secondlayer(){
    [[ ! $(echo $PWD) == $dirfirstlayer ]] \
        && { cd $dirfirstlayer; }
    createfolder "${secondlayerfoldername}"
    checkbuilddir
    rebornpackage
    files=$(ls -al ${dirnodejsproject} | grep '^-' | awk -F: '{ print $2 }' | cut -d ' ' -f2 | sed "${sedfilterfiles}")
    for filename in ${files}; do
        copyfile "${dirnodejsproject}/${filename}"
    done
    npm i && echo ""
    return 0
}
#===================================
thirdlayer(){
    [[ ! $(echo $PWD) == $dirsecondlayer ]] \
        && { cd $dirsecondlayer; }
    createfolder "${thirdlayerfoldername}"
    getprojectname
    createfile "${filenameindexts}" "${fileindextscontent//%3/$projectname}"
    copyfolderelements "${dirsrcnodejsproject}" "${dirthirdlayer}"
    return 0
}
#===================================
fourthlayer(){
    [[ ! $(echo $PWD) == $dirthirdlayer ]] \
        && { cd $dirthirdlayer; }
    deletelistenport 
    checkexportapp 
    return 0
}
#===================================
deploynodejsts(){
    setfirebaseproject
    firebase deploy --only functions:$1
    return 0
}
#===================================
createfirebasefunction(){
    echo "===> projectlayer"
    projectlayer
    echo "===> firstlayer"
    firstlayer
    echo "===> secondlayer"
    secondlayer
    echo "===> thirdlayer"
    thirdlayer
    echo "===> fourthlayer"
    fourthlayer
    echo "===> deploynodejsts"
    deploynodejsts "${projectname}"
    return 0
}
#===================================
#===========LOADSTRINGS=============
#===================================
loadstrings(){

    #==========nodejsproject==============
    dirnodejsproject="/github/workspace"
    dirsrcnodejsproject="${dirnodejsproject}/src"

    #===========projectlayer===============
    projectfoldername="firebase-app"
    dirproject="%1/%2"

    #===========firstlayer===============
    firstlayerfoldername="functions"
    dirfirstlayer="%1/%2"
    filenamefirebasejson="firebase.json"
    firebasejsoncontent='{"functions":{"predeploy":["npm --prefix \\"$RESOURCE_DIR\\" run build"],"source":"functions","runtime":"nodejs12"}}'
    filenamefirebaserc=".firebaserc"
    firebaserccontent='{"projects":{"default":"somos-aurora"}}'

    #==========secondlayer===============
    secondlayerfoldername="src"
    dirsecondlayer="%1/%2"
    packagekeys="name-version-description-main-scripts-repository-keywords-author-license-bugs-homepage-devDependencies-dependencies"
    dirpackagejson="%1/package.json"
    jqfilter='def walk(f):. as $in | if type == "object" then reduce keys_unsorted[] as $key ( {}; . + { ($key):  ($in[$key]) } ) | f elif type == "array" then map( walk(f) ) | f else f end;walk(if type == "object" then with_entries(select( .key as $key | $keys | contains($key) )) else . end)'
    jqfilter2='.dependencies |= . + {"firebase-functions": "^3.13.2", "firebase-admin": "^9.5.0"}'
    sedfilterfiles='/package/d'
    outDir="./lib"
    jqfieldtsconfigjson='.compilerOptions.outDir'
    outDirmain="%1/index.js"
    jqfieldpkgjson='.main'
    dirtsconfigjson="%1/tsconfig.json"

    #==========thirdlayer===============
    thirdlayerfoldername="app"
    dirthirdlayer="%1/%2"
    filenameindexts="index.ts"
    fileindextscontent=$(cat << EOF
import * as functions from 'firebase-functions';
import %1 from './app/%2';

export const %3 = functions
                    .region('%4')
                    .runWith({ memory: '%5', timeoutSeconds: %6 })
                    .https
                    .onRequest(%1);
EOF
)

    #==========fourthlayer===============
    sedfilterport='s/%1.listen(.*);//g'
    sedfilterport2='/env.PORT/d;'
    defaultexportstring="export default %1;"

    return 0
}
#===================================
changestrings(){
    
    #===========projectlayer===============
    dirproject=${dirproject//%1/$(echo $PWD)}
    dirproject=${dirproject//%2/$projectfoldername}

    #===========firstlayer===============
    dirfirstlayer=${dirfirstlayer//%1/$dirproject}
    dirfirstlayer=${dirfirstlayer//%2/$firstlayerfoldername}

    #==========secondlayer===============
    dirsecondlayer=${dirsecondlayer//%1/$dirfirstlayer}
    dirsecondlayer=${dirsecondlayer//%2/$secondlayerfoldername}
    dirpackagejson=${dirpackagejson//%1/$dirnodejsproject}
    outDirmain=${outDirmain//%1/$outDir}
    dirtsconfigjson=${dirtsconfigjson//%1/$dirnodejsproject}

    #==========thirdlayer===============
    dirthirdlayer=${dirthirdlayer//%1/$dirsecondlayer}
    dirthirdlayer=${dirthirdlayer//%2/$thirdlayerfoldername}
    fileindextscontent=${fileindextscontent//%1/$appname}
    fileindextscontent=${fileindextscontent//%2/$(echo $appfilename | cut -d '.' -f1)}
    fileindextscontent=${fileindextscontent//%4/$REGION}
    fileindextscontent=${fileindextscontent//%5/$MEMORY}
    fileindextscontent=${fileindextscontent//%6/$TIMEOUT}

    #==========fourthlayer===============
    sedfilterport="${sedfilterport//%1/$appname}"
    dirdefaultexportfile="${dirthirdlayer}/%1"
    dirdefaultexportfile=${dirdefaultexportfile//%1/$appfilename}
    defaultexportstring=${defaultexportstring//%1/$appname}

    return 0
}
#===================================
#==========PARAMSANDARGS============
#===================================
while (( "$#" )); do
    case ${1} in
        --h)
            help
            exit 0
        ;;
        --deploy-function)
            [[ -z $2 ]] && { appname="app"; } || { appname=${2}; }
            [[ -z $3 ]] && { appfilename="app.ts"; } || { appfilename=${3}; }
            [[ -z $4 ]] || { projectname=${4}; }
            init
            loadstrings
            changestrings
            createfirebasefunction
            exit 0
        ;;
        *)
            help
            exit 0
        ;;
    esac
    shift
done
