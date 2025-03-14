import models.io.upbound.azure.network.v1beta1 as networkv1beta1
import models.io.upbound.azure.network.v1beta2 as networkv1beta2
import models.io.upbound.azure.v1alpha1 as azurev1alpha1
import models.io.upbound.azure.v1beta1 as azurev1beta1
import models.io.upbound.platform.azure.v1alpha1 as platformazurev1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1

# observed composite resource
oxr = platformazurev1alpha1.XNetwork{**option("params").oxr}
params = oxr.spec.parameters
# observed composed resources
_ocds = option("params").ocds
# desired composite resource
_dxr = option("params").dxr
# desired composed resources
dcds = option("params").dcds

_metadata = lambda name: str -> any {
    {
        name = name
        annotations = {"krm.kcl.dev/composition-resource-name" = name}
        labels = {"azure.platform.upbound.io/network-id" = params.id}
    }
}

# Helper function to add common spec fields
_add_common_spec_fields = lambda spec: any -> any {
    spec | {
        deletionPolicy = params.deletionPolicy
        providerConfigRef.name = params.providerConfigName
    }
}

_items = [
    # Resource Group
    azurev1beta1.ResourceGroup {
        metadata = _metadata("${params.id}-rg")
        spec = _add_common_spec_fields(azurev1beta1.AzureUpboundIoV1beta1ResourceGroupSpec {
            forProvider = {
                location = params.region
            }
        })
    }

    # Virtual Network
    networkv1beta2.VirtualNetwork {
        metadata = _metadata("${params.id}-vnet")
        spec = _add_common_spec_fields(networkv1beta2.NetworkAzureUpboundIoV1beta2VirtualNetworkSpec {
            forProvider = {
                location = params.region
                addressSpace = ["192.168.0.0/16"]
                resourceGroupNameSelector = {
                    matchControllerRef = True
                }
            }
        })
    }

    # Subnet
    networkv1beta2.Subnet {
        metadata = _metadata("${params.id}-sn")
        spec = _add_common_spec_fields(networkv1beta2.NetworkAzureUpboundIoV1beta2SubnetSpec {
            forProvider = {
                addressPrefixes = ["192.168.1.0/24"]
                resourceGroupNameSelector = {
                    matchControllerRef = True
                }
                serviceEndpoints = ["Microsoft.Sql"]
                virtualNetworkNameSelector = {
                    matchControllerRef = True
                }
            }
        })
    }
]

items = _items
