# Terraform parameters
ENVIRONMENT       := localhost
TERRAFORM         := terraform
TF_FILES_PATH     := src
TF_BACKEND_CONF   := configuration/backend
TF_VARIABLES      := configuration/tfvars
LIBVIRT_IMGS_PATH := src/storage/images
LIBVIRT_POOL_PATH := src/storage/volumes/kubernetes
FCOS_VERSION      := 32.20200629.3.0
FCOS_IMAGE_PATH   := $(LIBVIRT_IMGS_PATH)/fedora-coreos-$(FCOS_VERSION).x86_64.qcow2
CENTOS_VERSION    := 8.1.1911-20200113.3
CENTOS_IMAGE_PATH := $(LIBVIRT_IMGS_PATH)/CentOS-8-GenericCloud-$(CENTOS_VERSION).x86_64.qcow2

all: init deploy test

require:
	$(info Installing dependencies...)
	@./requirements.sh

download-images:
	# Check if Fedora CoreOS image exists
ifeq (,$(wildcard $(FCOS_IMAGE_PATH)))
	$(info Downloading Fedora CoreOS image...)
	curl -s -S -L -f -o $(FCOS_IMAGE_PATH).xz \
		https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/$(FCOS_VERSION)/x86_64/fedora-coreos-$(FCOS_VERSION)-qemu.x86_64.qcow2.xz

	unxz -c $(FCOS_IMAGE_PATH).xz > $(FCOS_IMAGE_PATH)

	$(RM) -f $(FCOS_IMAGE_PATH).xz
else
	$(info Fedora CoreOS image already exists)
endif

	# Check if CentOS cloud image exists
ifeq (,$(wildcard $(CENTOS_IMAGE_PATH)))
	$(info Downloading Centos Cloud image...)
	curl -s -S -L -f -o $(CENTOS_IMAGE_PATH) \
		https://cloud.centos.org/centos/8/x86_64/images/CentOS-8-GenericCloud-$(CENTOS_VERSION).x86_64.qcow2
else
	$(info Centos Cloud image already exists)
endif

setup-libvirt:
	$(info Configuring folder for libvirt pool storage...)
	@install \
		--mode="0750" \
   		--context="system_u:object_r:virt_image_t:s0" \
    	--directory $(LIBVIRT_POOL_PATH)

setup-dns:
	$(info Elevating privileges...)
	@sudo -v

	$(info Configuring dnsmasq...)
	@sudo chmod 777 /etc/NetworkManager/conf.d
	@sudo chmod 777 /etc/NetworkManager/dnsmasq.d

render-ignition:
	$(info Rendering FCC configuration for load balancer...)
	@podman run -i --rm quay.io/coreos/fcct:release --pretty --strict \
  		< src/ignition/load-balancer/ignition.yml > src/ignition/load-balancer/ignition.json.tpl

init: download-images setup-libvirt setup-dns render-ignition
	$(info Initializing Terraform...)
	$(TERRAFORM) init \
		-backend-config="$(TF_BACKEND_CONF)/$(ENVIRONMENT).conf" $(TF_FILES_PATH)

changes:
	$(info Get changes in infrastructure resources...)
	$(TERRAFORM) plan \
		-var-file="$(TF_VARIABLES)/default.tfvars" \
		-var-file="$(TF_VARIABLES)/$(ENVIRONMENT).tfvars" \
		-out "output/tf.$(ENVIRONMENT).plan" \
		$(TF_FILES_PATH)

deploy: changes
	$(info Deploying infrastructure...)
	$(TERRAFORM) apply output/tf.$(ENVIRONMENT).plan

test:
	$(info Testing infrastructure...)

clean-dns:
	$(info Elevating privileges...)
	@sudo -v

	$(info Restoring network configuration...)
	@sudo chmod 755 /etc/NetworkManager/conf.d
	@sudo chmod 755 /etc/NetworkManager/dnsmasq.d
	@sudo systemctl restart NetworkManager

clean: changes clean-dns
	$(info Destroying infrastructure...)
	$(TERRAFORM) destroy \
		-auto-approve \
		-var-file="$(TF_VARIABLES)/default.tfvars" \
		-var-file="$(TF_VARIABLES)/$(ENVIRONMENT).tfvars" \
		$(TF_FILES_PATH)

	$(RM) -rf .terraform
	$(RM) -rf output/tf.$(ENVIRONMENT).plan
	$(RM) -rf state/terraform.$(ENVIRONMENT).tfstate
