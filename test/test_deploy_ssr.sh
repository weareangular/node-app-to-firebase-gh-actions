#!bin/bash 
#
#===================================
getAPI(){
    [[ -n $(grep TOKEN .env | cut -d '=' -f 2-) ]] && { TOKEN=$(grep TOKEN .env | cut -d '=' -f2); } || { echo -e "\nEither TOKEN is required to run test the firebase cli"; exit 162; }
    [[ -n $(grep PROJECT_ID .env | cut -d '=' -f 2-) ]] && { PROJECT_ID=$(grep PROJECT_ID .env | cut -d '=' -f2); } || { echo -e "\nEither PROJECT_ID is required to run test the firebase cli"; exit 162; }
    [[ -n $(grep RUNTIME_OPTIONS .env | cut -d '=' -f 2-) ]] && { RUNTIME_OPTIONS=$(grep RUNTIME_OPTIONS .env | cut -d '=' -f2); }
    [[ -n $(grep FUNCTION_ENV .env | cut -d '=' -f 2-) ]] && { FUNCTION_ENV=$(grep FUNCTION_ENV .env | cut -d '=' -f2); }
    [[ -z $1 ]] \
        && { echo -e "\nEither SITE_ID is required"; exit 126; }
    [[ -z $2 ]] \
        && { echo -e "\nEither FUNCTION_NAME is required"; exit 126; }
    return 0
}
#===================================
deleteimageifexist(){
    [[ -n $( docker images | grep wrap-firebase ) ]] && docker rmi wrap-firebase:1.0 
}
#===================================
buildockerdimage(){
    docker build -t wrap-firebase:1.0 . 
}
#===================================
rundockerimage(){
    tput setaf 6
    echo -e "\nTESTING DOCKER IMAGE WITH '--deploy-function' FLAG"
    tput sgr0
    DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )
    [[ -n $( docker images | grep wrap-firebase ) ]] \
        && { docker run -it -v "${DIR}/test-app-ssr":"/github/workspace" -e "FUNCTION_ENV=$FUNCTION_ENV" -e "RUNTIME_OPTIONS=$RUNTIME_OPTIONS" -e "PROJECT_ID=$PROJECT_ID" -e "FIREBASE_TOKEN=$FIREBASE_TOKEN" --rm wrap-firebase:1.0 --deploy-ssr "${1}" "${2}"; }
        || { echo "ERROR! no existe el docker"; exit 1; }
}
#===================================
run(){
    getAPI
    deleteimageifexist
    buildockerdimage
    rundockerimage
}
#===================================
run
