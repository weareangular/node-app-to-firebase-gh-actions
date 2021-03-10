# GitHub Actions for Firebase

This Action for [firebae](https://firebase.google.com/) transform `Typescript Node.js` projects into `Firebase functions` to be deployed.

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

- Make sure that the scripts section of your project's **`package.json`** contains the **`build`** command that are necessary to deploy in firebase.
- Make sure all the executable code for your application is inside the **`src`** folder.

## Inputs

- `--h` - Show help message
- `--deploy-function [DEFAULT_APP_NAME] [DEFAULT_APP_FILENAME] [PROJECT_ID]` - deploy Typescript Node.js app on firebase as function.
  - `[DEFAULT_APP_NAME]` - variable name express, `app` by default.
  - `[DEFAULT_APP_FILENAME]` - name of the file that contains the express variable, `app.ts` by default (If you want to define this variable, you must define the `DEFAULT_APP_NAME` variable).
  - `[PROJECT_NAME]` - name of the function to be displayed (If you want to define this variable, you must define the `DEFAULT_APP_NAME` and `DEFAULT_APP_FILENAME` variables).

## Environment variables

- `FIREBASE_TOKEN` - **Required**. The token to use for authentication.
- `PROJECT_ID` - **Required**. Name of the firebase project where the function should be deployed.
- `RUNTIME_OPTIONS` - Optional. firebase runtime options, see [set runtime options](https://firebase.google.com/docs/functions/manage-functions#set_runtime_options) and [RUNTIME_OPTIONS](#example-runtime_options-default-options) for example.
- `FUNCTION_ENV` - Optional. environment variables of the function, see [FUNCTION_ENV](#example-function_env) for example.

## Examples

### Example of project structure

```bash
./test/test-app
├── .eslintrc
├── package.json
├── package-lock.json
├── .prettierrc
├── src
│   └── server.ts
└── tsconfig.json
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
          args: --deploy-function "{{ secrets.DEFAULT_APP_NAME }}" "{{ secrets.DEFAULT_APP_FILENAME}}" "{{ secrets.PROJECT_NAME }}";
        env:
          FIREBASE_TOKEN: ${{ secrets.FIREBASE_TOKEN }}
          PROJECT_ID: ${{ secrets.FIREBASE_PROJECT_ID }}
          RUNTIME_OPTIONS: ${{ secrets.RUNTIME_OPTIONS }}
          FUNCTION_ENV: ${{ secrets.FUNCTION_ENV }}
```
