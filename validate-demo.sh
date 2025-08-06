set -x
crossplane render examples/network-xr.yaml apis/pat/composition.yaml examples/functions.yaml --include-full-xr | crossplane beta validate validate -
