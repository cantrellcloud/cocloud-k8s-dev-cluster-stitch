# Upgrade TKG Service from a Private Registry

https://www.vmware.com/go/supervisor-service

## Install Carvel
The system uses the Carvel packaging system. For more information about the Carvel imgpkg utility, see https://carvel.dev/imgpkg/docs/v0.42.x/install/.
Install the Carvel imgpkg utility.
wget -O- https://carvel.dev/install.sh > install.sh
sudo bash install.sh
Verify Carvel installation.
imgpkg version

## Generate the TKG Service Binary Package
Generate the TKG Service binary package by downloading the TKG Service definition YAML from the public site and creating the binary tar file.
Download the TKG Service definition YAML from the public site.
https://www.vmware.com/go/supervisor-service
For example, if you want to upgrade from TKG Service 3.0 to TKG Service 3.1, download the TKG Service 3.1 YAML.
Open the TKG Service YAML and get the image path for the package.
For example, for TKG Service 3.1 it is the following.
projects.packages.broadcom.com/tanzu/iaas/tkg-service/3.1.0/tkg-service:3.1.0
Which can be located in the YAML as follows:
```text
...
template:
    spec:
      fetch:
      - imgpkgBundle:
          image: projects.packages.broadcom.com/tanzu/iaas/tkg-service/3.1.0/tkg-service:3.1.0
As a convenience, consider creating an environment variable for the image path named TKGS_REPO_PATH or similar.
export TKGS_REPO_PATH="projects.packages.broadcom.com/tanzu/iaas/tkg-service/3.1.0/tkg-service:3.1.0"
Verify the environment variable:
printenv TKGS_REPO_PATH

##Generate a tar binary of the imgpkg bundle.
imgpkg copy -b ${TKGS_REPO_PATH} --to-tar tkg-service-v3.1.0.tar --cosign-signatures
Or, if you did not create the environment variable, use the following command.
imgpkg copy -b projects.packages.broadcom.com/tanzu/iaas/tkg-service/3.1.0/tkg-service:3.1.0 --to-tar tkg-service-v3.1.0.tar --cosign-signatures
To relocate the images, you must use the copy command and not the push and pull commands because they do not pull down all referenced images.
Verify success.
copy | exporting 31 images...
copy | will export projects.packages.broadcom.com/tanzu/iaas/tkg-service/3.1.0/tkg-service@sha256:02ffc87c3ebd2f8eed545f405e05443feb9b6675d                           7835a4d30bb8a939e54dcb9
...
copy | exported 31 images
copy | writing layers...
copy | done: file 'manifest.json' (71.384µs)
copy | done: file 'sha256-0f8b424aa0b96c1c388a5fd4d90735604459256336853082afb61733438872b5.tar.gz' (32.162µs)

Succeeded
Verify the local copy of the binary package tkg-service-v3.1.0.tar.
```

## Pull packages from VMware

imgpkg copy -b \
  projects.packages.broadcom.com/vsphere/iaas/tkg-service/3.3.2/tkg-service:3.3.3 \
  --to-tar tkg-service-3.3.3.tar \
  --cosign-signatures

imgpkg copy -b \
  projects.packages.broadcom.com/vsphere/iaas/tkg-service/3.3.2/tkg-service:3.3.2 \
  --to-tar tkg-service-3.3.2.tar \
  --cosign-signatures

imgpkg copy -b \
  projects.packages.broadcom.com/vsphere/iaas/tkg-service/3.3.1/tkg-service:3.3.1 \
  --to-tar tkg-service-3.3.1.tar \
  --cosign-signatures

imgpkg copy -b \
  projects.packages.broadcom.com/vsphere/iaas/tkg-service/3.3.0/tkg-service:3.3.0 \
  --to-tar tkg-service-3.3.0.tar \
  --cosign-signatures

imgpkg copy -b \
  projects.packages.broadcom.com/vsphere/iaas/tkg-service/3.2.0/tkg-service:3.2.0 \
  --to-tar tkg-service-3.2.0.tar \
  --cosign-signatures

imgpkg copy -b \
  projects.packages.broadcom.com/vcf_cci_service/cci-supervisor-service-package:v1.0.2 \
  --to-tar cci-supervisor-service-package-v1.0.2.tar \
  --cosign-signatures

imgpkg copy -b \
  projects.packages.broadcom.com/tkg/packages/standard/contour:v1.28.2_vmware.1-tkg.1 \
  --to-tar contour-v1.28.2_vmware.1-tkg.1.tar \
  --cosign-signatures

imgpkg copy -b \
  projects.registry.vmware.com/vsphere/ca-clusterissuer-bundle:v0.0.2 \
  --to-tar ca-clusterissuer-bundle-v0.0.2.tar \
  --cosign-signatures

imgpkg copy -b \
  projects.packages.broadcom.com/tkg/packages/standard/harbor:v2.11.2+vmware.1-tkg.2 \
  --to-tar harbor-v2.11.2+vmware.1-tkg.2.tar \
  --cosign-signatures

imgpkg copy -b \
  projects.packages.broadcom.com/tkg/packages/standard/harbor:v2.9.1_vmware.1-tkg.1 \
  --to-tar harbor-v2.9.1_vmware.1-tkg.1.tar \
  --cosign-signatures

# Push packages to registry

imgpkg copy \
  --tar tkg-service-3.3.3.tar \
  --to-repo kuberegistry.dev.kube/tkgs/tkg-service \
  --cosign-signatures \
  --registry-username admin \
  --registry-password 'ZAQwsx!@#123' \
  --registry-ca-cert-path kuberegistry-chain.crt

imgpkg copy \
  --tar tkg-service-3.2.0.tar \
  --to-repo kuberegistry.dev.kube/tkgs/tkg-service \
  --cosign-signatures \
  --registry-username admin \
  --registry-password 'ZAQwsx!@#123' \
  --registry-ca-cert-path kuberegistry-chain.crt

imgpkg copy \
  --tar tkg-service-3.3.0.tar \
  --to-repo kuberegistry.dev.kube/tkgs/tkg-service \
  --cosign-signatures \
  --registry-username admin \
  --registry-password 'ZAQwsx!@#123' \
  --registry-ca-cert-path kuberegistry-chain.crt

imgpkg copy \
  --tar tkg-service-3.3.1.tar \
  --to-repo kuberegistry.dev.kube/tkgs/tkg-service \
  --cosign-signatures \
  --registry-username admin \
  --registry-password 'ZAQwsx!@#123' \
  --registry-ca-cert-path kuberegistry-chain.crt

imgpkg copy \
  --tar tkg-service-3.3.2.tar \
  --to-repo kuberegistry.dev.kube/tkgs/tkg-service \
  --cosign-signatures \
  --registry-username admin \
  --registry-password 'ZAQwsx!@#123' \
  --registry-ca-cert-path kuberegistry-chain.crt

imgpkg copy \
  --tar cci-supervisor-service-package-v1.0.2.tar \
  --to-repo kuberegistry.dev.kube/tanzu/packages/cci-supervisor-service-package \
  --cosign-signatures \
  --registry-username admin \
  --registry-password 'ZAQwsx!@#123' \
  --registry-ca-cert-path kuberegistry-chain.crt

imgpkg copy \
  --tar contour-v1.28.2_vmware.1-tkg.1.tar \
  --to-repo kuberegistry.dev.kube/tanzu/packages/contour \
  --cosign-signatures \
  --registry-username admin \
  --registry-password 'ZAQwsx!@#123' \
  --registry-ca-cert-path kuberegistry-chain.crt

imgpkg copy \
  --tar contour-v1.29.3_vmware.1-tkg.1.tar \
  --to-repo kuberegistry.dev.kube/tanzu/packages/contour \
  --cosign-signatures \
  --registry-username admin \
  --registry-password 'ZAQwsx!@#123' \
  --registry-ca-cert-path kuberegistry-chain.crt

imgpkg copy \
  --tar ca-clusterissuer-bundle-v0.0.2.tar \
  --to-repo kuberegistry.dev.kube/tanzu/packages/ca-clusterissuer-bundle \
  --cosign-signatures \
  --registry-username admin \
  --registry-password 'ZAQwsx!@#123' \
  --registry-ca-cert-path kuberegistry-chain.crt

imgpkg copy \
  --tar harbor-v2.9.1_vmware.1-tkg.1.tar \
  --to-repo kuberegistry.dev.kube/tanzu/packages/harbor \
  --cosign-signatures \
  --registry-username admin \
  --registry-password 'ZAQwsx!@#123' \
  --registry-ca-cert-path kuberegistry-chain.crt

imgpkg copy \
  --tar harbor-v2.11.2+vmware.1-tkg.2.tar \
  --to-repo kuberegistry.dev.kube/tanzu/packages/harbor \
  --cosign-signatures \
  --registry-username admin \
  --registry-password 'ZAQwsx!@#123' \
  --registry-ca-cert-path kuberegistry-chain.crt
