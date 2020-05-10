# Terraform parameters
environment=localhost
tf_cmd=terraform
tf_files=src
tf_backend_conf=configuration/backend
tf_variables=configuration/tfvars
libvirt_pool_dir=/var/lib/libvirt/storage
libvirt_imgs_dir=/var/lib/libvirt/images
ssh_maintuser_pubkey=`cat src/ssh/maintuser/id_rsa.pub`

all: init plan deploy test
requirements:
	@echo "Installing dependencies..."
	@./requirements.sh
init:
	@echo "Initializing Terraform plugins"
	terraform init \
		-backend-config="$(tf_backend_conf)/$(environment).conf" $(tf_files)

	@echo "Configuring path $(libvirt_pool_dir) for libvirt pool storage..."
	@sudo install \
		--owner="root" \
		--group="root" \
		--mode="0750" \
   		--context="system_u:object_r:virt_image_t:s0" \
    	--directory $(libvirt_pool_dir)

	@echo "Creating directory $(libvirt_imgs_dir) for libvirt images..."
	@sudo install \
		--owner="root" \
		--group="libvirt" \
		--mode="0770" \
   		--context="system_u:object_r:virt_image_t:s0" \
    	--directory $(libvirt_imgs_dir)

	@echo "Generating SSH keypair for maintenance user..."
	@mkdir -p src/ssh/maintuser
	@echo -e 'n\n' | ssh-keygen -o -t rsa -b 4096 -C "" -N "" -f "$(shell pwd)/src/ssh/maintuser/id_rsa" || true && echo ""

	@echo "Rendering FCC configuration for load balancer..."
	@yq write -i src/ignition/load-balancer/ignition.yml \
		'passwd.users[0].ssh_authorized_keys[0]' "$(ssh_maintuser_pubkey)"
	@podman run -i --rm quay.io/coreos/fcct:release --pretty --strict \
  		< src/ignition/load-balancer/ignition.yml > src/ignition/load-balancer/ignition.json

	@echo "Configuring firewall for public machines..."
	@sudo firewall-cmd --new-zone=k8s-public --permanent || true
	@sudo firewall-cmd --zone=k8s-public --permanent --set-target=DROP
	@sudo firewall-cmd --zone=k8s-public --permanent \
		--add-service=ssh \
		--add-service=dns \
		--add-service=dhcp \
		--add-service=dhcpv6
	@sudo firewall-cmd --zone=k8s-public --permanent \
		--add-protocol=icmp \
		--add-protocol=ipv6-icmp

	@echo "Configuring firewall for internal machines..."
	@sudo firewall-cmd --new-zone=k8s-internal --permanent || true
	@sudo firewall-cmd --zone=k8s-internal --permanent --set-target=DROP
	@sudo firewall-cmd --zone=k8s-internal --permanent \
		--add-service=ssh \
		--add-service=dns \
		--add-service=dhcp \
		--add-service=dhcpv6
	@sudo firewall-cmd --zone=k8s-internal --permanent \
		--add-protocol=icmp \
		--add-protocol=ipv6-icmp

plan:
	@echo "Planing infrastructure changes..."
	terraform plan \
		-var-file="$(tf_variables)/default.tfvars" \
		-var-file="$(tf_variables)/$(environment).tfvars" \
		-out "output/tf.$(environment).plan" \
		$(tf_files)
deploy:
	@echo "Deploying infrastructure..."
	terraform apply output/tf.$(environment).plan

	#@sudo iptables -I FORWARD 1 -j ACCEPT -i kubevirbr0 -o kubevirbr1 -s 10.1.0.0/24 -d 172.1.0.0/24
	#@sudo iptables -I FORWARD 2 -j ACCEPT -i kubevirbr1 -o kubevirbr0 -s 172.1.0.0/24 -d 10.1.0.0/24
test:
	@echo "Testing infrastructure..."
destroy: plan
	@echo "Destroying infrastructure..."
	terraform destroy \
		-var-file="$(tf_variables)/default.tfvars" \
		-var-file="$(tf_variables)/$(environment).tfvars" \
		$(tf_files)
	@rm -rf .terraform
	@rm -rf output/tf.$(environment).plan
	@rm -rf state/terraform.$(environment).tfstate
	@rm -rf src/ssh
	@sudo firewall-cmd --permanent --delete-zone=k8s-public
	@sudo firewall-cmd --permanent --delete-zone=k8s-internal
	@sudo firewall-cmd --reload
	@sudo systemctl restart libvirtd