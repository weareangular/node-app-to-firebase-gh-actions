# GitHub Actions for Firebase

This Action for [firebase](https://firebase.google.com/) allows you to perform two actions, the first one transforms the projects from `Typescript Node.js` into` Firebase Functions` to be implemented and deployed, the second one deploys `Next.js` applications to `Firebase Functions and Hosting`.

<div align="center">
<img src="https://github.githubassets.com/images/modules/site/features/actions-icon-actions.svg" height="80"></img>
&nbsp;&nbsp;
&nbsp;&nbsp;
&nbsp;&nbsp;
&nbsp;&nbsp;
&nbsp;&nbsp;
&nbsp;&nbsp;
&nbsp;&nbsp;
&nbsp;&nbsp;
<img src="https://www.gstatic.com/devrel-devsite/prod/ve2b3219effe11173b4515247c51c6c16382b215fde591b8f8db0b6d41c561ba8/firebase/images/lockup.png" height="80"></img>
</div>

## Requirements

### Deploy as a Function

- Make sure that the scripts section of your project's **`package.json`** contains the **`build`** command that are necessary to deploy in firebase.
- Make sure all the executable code for your application is inside the **`src`** folder.

### Deploy Next.js project

- Make sure that the scripts section of your project's **`package.json`** contains the **`build`** command that are necessary to deploy in firebase.

## Inputs

- `--h` - Show help message
- `--deploy-function [DEFAULT_APP_NAME] [DEFAULT_APP_FILENAME] [FUNCTION_NAME]` - deploy Typescript Node.js app on firebase as function.
  - `[DEFAULT_APP_NAME]` - variable name express, `app` by default.
  - `[DEFAULT_APP_FILENAME]` - name of the file that contains the express variable, `app.ts` by default (If you want to define this variable, you must define the `DEFAULT_APP_NAME` variable).
  - `[FUNCTION_NAME]` - name of the function to be displayed (If you want to define this variable, you must define the `DEFAULT_APP_NAME` and `DEFAULT_APP_FILENAME` variables).
- `--deploy-ssr [SITE_ID] [FUNCTION_NAME]` - Deploy Nextjs app on firebase.
  - `[SITE_ID]` - is used to construct the Firebase-provisioned default subdomains for the site (if it does not exist, it is created).
  - `[FUNCTION_NAME]` - name of the function to be displayed (if you want to define this variable you must define the `[SITE_ID]`).

## Environment variables

- `FIREBASE_TOKEN` - **Required**. The token to use for authentication.
- `PROJECT_ID` - **Required**. Name of the firebase project where the function should be deployed.
- `RUNTIME_OPTIONS` - Optional. firebase runtime options, see [set runtime options](https://firebase.google.com/docs/functions/manage-functions#set_runtime_options) and [RUNTIME_OPTIONS](#example-runtime_options-default-options) for example.
- `FUNCTION_ENV` - Optional. environment variables of the function, see [FUNCTION_ENV](#example-function_env) for example.

## Examples

### Example of project structure

#### Deploy as a Function

```shell
./test/test-app-function
├── .eslintrc
├── package.json
├── package-lock.json
├── .prettierrc
├── src
│   └── server.ts
└── tsconfig.json
```

#### Deploy Next.js project

```shell
./test/test-app-ssr
├── package.json
├── package-lock.json
├── public
│   └── assets
│       └── success.jpg
└── src
    └── pages
        ├── index.js
        └── register
            └── index.js
```

### Example RUNTIME_OPTIONS (Default options)

```json
{
  "runtime": "nodejs12",
  "region": "us-central1",
  "memory": "256MB",
  "timeoutSeconds": 300
}
```

### Example FUNCTION_ENV

```json
{
  "config": {
    "host": "domain",
    "key": "SECRET_KEY",
    "pass": "SECRET_PASS"
  }
}
```

### Example of the .yaml file

#### Deploy as a Function

To authenticate with Firebase and deploy the project to Firebase as a function:

```yaml
name: Build and deploy function to Firebase
on:
  push:
    branches:
      - branch

jobs:
  build:
    name: Build
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: weareangular/node-app-to-firebase-gh-actions@dev
        with:
          args: --deploy-function "{{ secrets.DEFAULT_APP_NAME }}" "{{ secrets.DEFAULT_APP_FILENAME}}" "{{ secrets.FUNCTION_NAME }}";
        env:
          FIREBASE_TOKEN: ${{ secrets.FIREBASE_TOKEN }}
          PROJECT_ID: ${{ secrets.FIREBASE_PROJECT_ID }}
          RUNTIME_OPTIONS: ${{ secrets.RUNTIME_OPTIONS }}
          FUNCTION_ENV: ${{ secrets.FUNCTION_ENV }}
```

#### Deploy Next.js project

To authenticate with Firebase and deploy the Next.js project to Firebase:

```yaml
name: Build and deploy function to Firebase
on:
  push:
    branches:
      - branch

jobs:
  build:
    name: Build
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: weareangular/node-app-to-firebase-gh-actions@dev
        with:
          args: --deploy-ssr "{{ secrets.SITE_ID }}" "{{ secrets.FUNCTION_NAME }}";
        env:
          FIREBASE_TOKEN: ${{ secrets.FIREBASE_TOKEN }}
          PROJECT_ID: ${{ secrets.FIREBASE_PROJECT_ID }}
          RUNTIME_OPTIONS: ${{ secrets.RUNTIME_OPTIONS }}
          FUNCTION_ENV: ${{ secrets.FUNCTION_ENV }}
```
