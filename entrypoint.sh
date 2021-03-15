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
    --deploy-function [DEFAULT_APP_NAME] [DEFAULT_APP_FILENAME] [FUNCTION_NAME]  deploy Typescript Node.js app on firebase as function
                                                                                [DEFAULT_APP_NAME] => variable name express, 'app' by default.
                                                                                [DEFAULT_APP_FILENAME] => name of the file that contains the express variable, 'app.ts' by default (if you want to define this variable you must define the previous ones).
                                                                                [FUNCTION_NAME] => name of the function to be displayed (if you want to define this variable you must define the previous ones).
    --deploy-ssr [SITE_ID] [FUNCTION_NAME]                                          deploy Nextjs app on firebase.
                                                                                [SITE_ID] => is used to construct the Firebase-provisioned default subdomains for the site.
                                                                                [FUNCTION_NAME] => name of the function to be displayed (if you want to define this variable you must define the previous ones).
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
    [[ -z $(echo $RUNTIME_OPTIONS | jq -r '.runtime') ]] \
        && { RUNTIME="nodejs12"; } \
        || { RUNTIME="$(echo $RUNTIME_OPTIONS | jq -r '.runtime')"; }
    [[ -z $(echo $RUNTIME_OPTIONS | jq -r '.region') ]] \
        && { REGION="us-central1"; } \
        || { REGION="$(echo $RUNTIME_OPTIONS | jq -r '.region')"; }
    [[ -z $(echo $RUNTIME_OPTIONS | jq -r '.memory') ]] \
        && { MEMORY="128MB"; } \
        || { MEMORY="$(echo $RUNTIME_OPTIONS | jq -r '.memory')"; }
    [[ -z $(echo $RUNTIME_OPTIONS | jq -r '.timeoutSeconds') ]] \
        && { TIMEOUT="300"; } \
        || { TIMEOUT="$(echo $RUNTIME_OPTIONS | jq -r '.timeoutSeconds')"; }
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
getfunctionname(){
    [[ -z $functionname ]] \
    && { functionname=$(cat $dirpackagejson | jq -r '.name' | sed -E 's/[^[:alnum:]]+//g'); } \
    || { functionname=$(echo "${functionname}" | sed -E 's/[^[:alnum:]]+//g'); }
    return 0
}
#===================================
setfirebaseproject(){
    [[ ! $(echo $PWD) == $dirproject ]] \
        && { cd $dirproject; firebase use --add "$PROJECT_ID"; }
    return 0
}
#===================================
setenvfirebasefunction(){
    [[ -n $(echo $FUNCTION_ENV) ]] \
        && { firebase functions:config:set env="${FUNCTION_ENV}" ; }
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
#==========DEPLOYFUNCTION===========
#===================================
checkbuilddir(){
    [[ ! $(cat ${dirtsconfigjson} | jq -r "${jqfieldtsconfigjson}") == "${outDir}" ]] \
        && { sed -i -- "s~$(cat ${dirtsconfigjson} | jq -r "${jqfieldtsconfigjson}")~${outDir}~g" "${dirtsconfigjson}"; }
    [[ ! $(cat ${dirpackagejson} | jq -r "${jqfieldpkgjson}") == "${outDirmain}" ]] \
        && { sed -i -- "s~$(cat ${dirpackagejson} | jq -r "${jqfieldpkgjson}")~${outDirmain}~g" "${dirpackagejson}"; }
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
firstlayerfunction(){
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
secondlayerfunction(){
    [[ ! $(echo $PWD) == $dirfirstlayer ]] \
        && { cd $dirfirstlayer; }
    createfolder "${secondlayerfoldername}"
    checkbuilddir
    files=$(ls -p ${dirnodejsproject} | grep -v /)
    for filename in ${files}; do
        copyfile "${dirnodejsproject}/${filename}"
    done
    npm i $npmfirebaseprojectdependencies && echo ""
    return 0
}
#===================================
thirdlayerfunction(){
    [[ ! $(echo $PWD) == $dirsecondlayer ]] \
        && { cd $dirsecondlayer; }
    createfolder "${thirdlayerfoldername}"
    getfunctionname
    createfile "${filenameindexts}" "${fileindextscontent//%3/$functionname}"
    copyfolderelements "${dirsrcnodejsproject}" "${dirthirdlayer}"
    return 0
}
#===================================
fourthlayerfunction(){
    [[ ! $(echo $PWD) == $dirthirdlayer ]] \
        && { cd $dirthirdlayer; }
    deletelistenport 
    checkexportapp 
    return 0
}
#===================================
deployfunction(){
    setfirebaseproject
    setenvfirebasefunction
    firebase deploy --only functions:$functionname
    return 0
}
#===================================
createfirebasefunction(){
    echo "===> projectlayer"
    projectlayer
    echo "===> firstlayer"
    firstlayerfunction
    echo "===> secondlayer"
    secondlayerfunction
    echo "===> thirdlayer"
    thirdlayerfunction
    echo "===> fourthlayer"
    fourthlayerfunction
    echo "===> deploy"
    deployfunction
    return 0
}
#===================================
#=============DEPLOYSSR=============
#===================================
rebornpackagessr(){
    package=$(cat "${dirpackagejson}" | jq "$jqfiltersetmain")
    echo $package > "${dirpackagejson}"
    npm i $npmfirebaseprojectdependencies
    return 0
}
#===================================
checkfirebasesite(){
    [[ -n $(firebase hosting:channel:list --site "${siteid}" | grep Error) ]] && { firebase hosting:sites:create $siteid; }
    return 0
}
#===================================
firstlayerssr(){
    [[ ! $(echo $PWD) == $dirproject ]] \
        && { cd $dirproject; }
    [[ -d $firstlayerfoldername ]] \
        && rm -r $firstlayerfoldername
    createfolder "${foldernamesrc}"
    createfolder "${foldernamepublic}"
    files=$(ls -p ${dirnodejsproject} | grep -v /)
    for filename in ${files}; do
        copyfile "${dirnodejsproject}/${filename}"
    done
    getfunctionname
    createfile "${filenamefirebasejson}" "${firebasejsoncontent//%2/$functionname}"
    createfile "${filenamefirebaserc}" "${firebaserccontent}"
    createfile "${filenamefirebasefunctionsjs}" "${firebasefunctionsjscontent//%1/$functionname}"
    rebornpackagessr
    return 0
}
#===================================
secondlayerssr(){
    [[ ! $(echo $PWD) == $dirpublicfolder ]] \
        && { cd $dirpublicfolder; }
    copyfolderelements "${dirpublicnodejsproject}"
    [[ ! $(echo $PWD) == $dirsrcfolder ]] \
        && { cd $dirsrcfolder; }
    copyfolderelements "${dirsrcnodejsproject}"
    createfile "${filenamenextconfigjs}" "${filenextconfigjscontent}"
}
#===================================
deployssr(){
    setfirebaseproject
    checkfirebasesite
    setenvfirebasefunction
    firebase deploy --only functions:"${functionname}",hosting:"${siteid}"
    return 0
}
#===================================
createfirebasessr(){
    echo "===> projectlayer"
    projectlayer
    echo "===> firstlayer"
    firstlayerssr
    echo "===> secondlayer"
    secondlayerssr
    echo "===> deploy"
    deployssr
    return 0
}
#===================================
#===========LOADSTRINGS=============
#===================================
loadstringsfunction(){

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
    firebasejsoncontent='{"functions":{"predeploy":["npm --prefix \\"$RESOURCE_DIR\\" run build"],"source":"functions","runtime":"%1"}}'
    filenamefirebaserc=".firebaserc"
    firebaserccontent='{"projects":{"default":"%1"}}'

    #==========secondlayer===============
    secondlayerfoldername="src"
    dirsecondlayer="%1/%2"
    dirpackagejson="%1/package.json"
    npmfirebaseprojectdependencies="firebase-functions firebase-admin"
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
changestringsfunction(){
    
    #===========projectlayer===============
    dirproject=${dirproject//%1/$(echo $PWD)}
    dirproject=${dirproject//%2/$projectfoldername}

    #===========firstlayer===============
    dirfirstlayer=${dirfirstlayer//%1/$dirproject}
    dirfirstlayer=${dirfirstlayer//%2/$firstlayerfoldername}
    firebasejsoncontent=${firebasejsoncontent//%1/$RUNTIME}
    firebaserccontent=${firebaserccontent//%1/$PROJECT_ID}

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
loadstringsssr(){

    #==========nodejsproject==============
    dirnodejsproject="/github/workspace"
    dirsrcnodejsproject="${dirnodejsproject}/src"
    dirpublicnodejsproject="${dirnodejsproject}/public"

    #===========projectlayer===============
    projectfoldername="firebase-app"
    dirproject="%1/%2"

    #===========firstlayer===============
    foldernamesrc="src"
    dirsrcfolder="%1/%2"
    foldernamepublic="public"
    dirpublicfolder="%1/%2"
    filenamefirebasefunctionsjs="firebaseFunctions.js"
    firebasefunctionsjscontent=$(cat << EOF
const { join } = require('path');
const functions = require('firebase-functions');
const { default: next } = require('next');

const isDev = process.env.NODE_ENV !== 'production';

const nextjsDistDir = join('src', require('./src/next.config.js').distDir);

const nextjsServer = next({
  dev: isDev,
  conf: {
    distDir: nextjsDistDir,
  },
});
const nextjsHandle = nextjsServer.getRequestHandler();

exports.%1 = functions
                        .region('%2')
                        .runWith({ memory: '%3', timeoutSeconds: %4 })
                        .https
                        .onRequest((req, res) => {
                            return nextjsServer.prepare().then(() => nextjsHandle(req, res))
                        });
EOF
)
    filenamefirebasejson="firebase.json"
    firebasejsoncontent='{"hosting":{"site":"%1","public":"public","ignore":["firebase.json","**/.*","**/node_modules/**"],"rewrites":[{"source":"**","function":"%2"}]},"functions":{"source":".","predeploy":["npm --prefix \\"$PROJECT_DIR\\" install","npm --prefix \\"$PROJECT_DIR\\" run build"],"runtime":"%3"}}'
    filenamefirebaserc=".firebaserc"
    firebaserccontent='{"projects":{"default":"%1"}}'
    dirpackagejson="%1/package.json"
    jqfiltersetmain='.main |= "%1"'
    npmfirebaseprojectdependencies="firebase-functions firebase-admin"

    #==========secondlayer===============
    filenamenextconfigjs="next.config.js"
    filenextconfigjscontent='module.exports={distDir:"../.next"};'

}
#===================================
changestringsssr(){

    #===========projectlayer===============
    dirproject=${dirproject//%1/$(echo $PWD)}
    dirproject=${dirproject//%2/$projectfoldername}

    #===========firstlayer===============
    dirsrcfolder=${dirsrcfolder//%1/$dirproject}
    dirsrcfolder=${dirsrcfolder//%2/$foldernamesrc}
    dirpublicfolder=${dirpublicfolder//%1/$dirproject}
    dirpublicfolder=${dirpublicfolder//%2/$foldernamepublic}
    firebasefunctionsjscontent=${firebasefunctionsjscontent//%2/$REGION}
    firebasefunctionsjscontent=${firebasefunctionsjscontent//%3/$MEMORY}
    firebasefunctionsjscontent=${firebasefunctionsjscontent//%4/$TIMEOUT}
    firebasejsoncontent=${firebasejsoncontent//%1/$siteid}
    firebasejsoncontent=${firebasejsoncontent//%3/$RUNTIME}
    firebaserccontent=${firebaserccontent//%1/$PROJECT_ID}
    dirpackagejson=${dirpackagejson//%1/$dirproject}
    jqfiltersetmain=${jqfiltersetmain//%1/$filenamefirebasefunctionsjs}

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
            [[ -z $4 ]] || { functionname=${4}; }
            init
            loadstringsfunction
            changestringsfunction
            createfirebasefunction
            exit 0
        ;;
        --deploy-ssr)
            [[ -z $2 ]] && { echo -e "\nYou must provide the siteid"; exit 126; } || { siteid=${2}; }
            [[ -z $3 ]] && { echo -e "\nYou must provide the name of the function"; exit 126; } || { functionname=${3}; }
            init
            loadstringsssr
            changestringsssr
            createfirebasessr
            exit 0
        ;;
        *)
            help
            exit 0
        ;;
    esac
    shift
done
