# Research helm chart release -devel

This repo was a quick way to research helm's behavior when working with development charts.

To create this project i followed the tutorial [here](https://medium.com/@mattiaperi/create-a-public-helm-chart-repository-with-github-pages-49b180dbb417)

## Process

1. Used `helm create kyle` to create a base chart `kyle/`  which includes sample chart components (templates and values)
2. Ran `helm package kyle`
   1. Updated the chart.yaml with `version: 0.1.0-devel` and packaged again.
   2. Did above but with `version: 0.1.0-rc1`
3. Created index.yaml with `helm repo index --url https://moosecanswim.github.io/helm-chart-repo/ .`
4. In github settings enabled a github page based on the root directory of the master branch
5. Added the remote helm repo we just published to the my local helm repo list with `helm repo add kyle https://moosecanswim.github.io/helm-chart-repo`
   1. make sure it works with `helm search kyle`
6. Test without specifying version `helm install test kyle/kyle -n test`
   1. This installs the `kyle-0.1.0` chart
7. Test install a development version: `helm install test-devel --version 0.1.0-devel kyle/kyle -n test --devel`
   1. This installs the `kyle-0.1.0-devel` chart

## Scripts

`update-version-suffix.sh`: this script will accept two inputs:

- Current is the current pre-release version
- Next: the new pre-release version suffix
  
The script will go through and find all Chart.yaml files and if the current pre-release is there will replace it with the next pre-release version

ex: `./update-version-suffix.sh 0 1` will replace all versions with `-0` with `-1`

> *NOTE: this will remove comments in the Chart.yaml file*

TODO: update this to work with dependencies versions in parent charts.  make this increment automatically based on current pre-release.

## Conclusions

This means we can use helm's built in development management tools to differentiate between current release artifacts and the development versions (differentiated by the `-something`) while hosting artifacts in the same helm repo.

If we have helm charts in a repo we can use ci to publish charts from multiple branches.  If we have a production branch `prod-1.3` and a development branch `prod-1.4` where ci published charts based on branch name `prod-*` then all we need to do to ensure a `helm install` commands to will not use prod-1.4 charts while in development is to add `-something` as a prefix to the chart.yaml version.
