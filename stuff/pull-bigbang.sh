#!/usr/bin/env bash
clear
echo START
echo
echo Pulling images...
for image in `cat /home/adminlocal/altregistry/${1}`; do echo pulling image: $image; nerdctl pull $image -u cantrellr -p repo1-dso-mil1MDp98mtyyd1PEENzjdR; done
echo
echo ---
echo
echo Tagging images...
for image in `cat /home/adminlocal/altregistry/${1}`; do echo tagging image: `echo $image | sed -E 's#^[^/]+/#kuberegistry.dev.kube/library/#'`; nerdctl tag  $image `echo $image | sed -E 's#^[^/]+/#kuberegistry.dev.kube/library/#'`; done
echo
echo ---
echo
echo DONE
echo
echo
