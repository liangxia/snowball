#!/bin/bash

find . -name '*.test_run.yaml' -exec bash -c '
  function SearchAndAddTag() {
    if [ $# -ne 3 ] ; then
      echo "Expect 3 params for function SearchAndAddTag, but got $#"
      exit 1
    fi

    filePath="$1"
    tagReg="$2"
    tagAdd="$3"

    if ! grep -q -- "$tagReg" "$filePath" ; then
      echo -e "We will add tag $tagAdd, for file $filePath"
      sed -i "/cucumber_upgrade_tags/s%\"% and ${tagAdd}\"%4" "$filePath"
    fi
  }

  for filePath ; do
    if grep -q cucumber_upgrade_tags "$filePath" ; then
      iupi="false"
      iaas="false"
      fips="false"
      proxy="false"
      network="false"

      filename="$(basename "$filePath")"
      case "${filename,,}" in
        *ipi*)
          tagSuffix="ipi"
          iupi="true"
        ;;&
        *upi*)
          tagSuffix="upi"
          iupi="true"
        ;;&
        *aws*)
          tagPrefix="aws"
          iaas="true"
        ;;&
        *azure*)
          tagPrefix="azure"
          iaas="true"
        ;;&
        *baremetal*)
          tagPrefix="baremetal"
          iaas="true"
        ;;&
        *gcp*)
          tagPrefix="gcp"
          iaas="true"
        ;;&
        *osp*)
          tagPrefix="openstack"
          iaas="true"
        ;;&
        *vsphere*)
          tagPrefix="vsphere"
          iaas="true"
        ;;&
        *fips[\ ]on*)
          fips="true"
        ;;&
        *fips[\ ]off*|*no_fips*)
          fips="false"
        ;;&
        *http_proxy*|*https_proxy)
          proxy="true"
        ;;&
        *ovn*)
          network="true"
        ;;&
      esac

      if [[ "$iaas" == "true" && "$iupi" == "true" ]] ; then
        tag="@$tagPrefix-$tagSuffix"
        SearchAndAddTag "$filePath" "$tag" "$tag"
      fi

      if [[ "$fips" == "true" ]] ; then
        tagFips="@fips"
      else
        tagFips="not @fips"
      fi
      SearchAndAddTag "$filePath" "$tagFips" "$tagFips"

      if [[ "$proxy" == "true" ]] ; then
        tagProxy="@proxy"
        SearchAndAddTag "$filePath" "$tagProxy" "$tagProxy"
      fi

      tagNetwork="@network-"
      if [[ "$network" == "true" ]] ; then
        tagNetworkDefault="@network-ovnkubernetes"
      else
        tagNetworkDefault="@network-openshiftsdn"
      fi
      SearchAndAddTag "$filePath" "$tagNetwork" "$tagNetworkDefault"
      if grep -q -- "$tagNetwork" "$filePath" ; then
        if ! grep -q -- "$tagNetworkDefault" "$filePath" ; then
          echo -e "We will correct tag with $tagNetworkDefault, for file $filePath"
          sed -i -E "/cucumber_upgrade_tags/s%(not )?${tagNetwork}[a-z]+( and (not )?${tagNetwork}[a-z]+)?%$tagNetworkDefault%" "$filePath"
        fi
      fi
    fi
  done
' bash {} +
