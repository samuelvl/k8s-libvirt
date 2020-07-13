#!/usr/bin/env bash

set -o errexit  # exit when a command fails
set -o nounset  # exit when use undeclared variables
set -o pipefail # return the exit code of the last command that threw a non-zero

# Global variables
TF_VERSION="0.12.28"
TF_PROVIDERS_DIR="${HOME}/.terraform.d/plugins"
TF_LIBVIRT_PROVIDER_VERSION="v0.6.2/terraform-provider-libvirt-0.6.2+git.1585292411.8cbe9ad0.Fedora_28.x86_64.tar.gz"
CFSSL_VERSION="1.2"
KUBECTL_VERSION="1.18.0"
KREW_VERSION="0.3.4"
HELM_VERSION="3.3.0-rc.1"

# install_terraform <installation_dir> <terraform_version>
function install_terraform {
    tf_installation_dir=${1}
    tf_binary="${tf_installation_dir}/terraform"
    tf_version=${2}

    # Create installation dir
    mkdir -p ${tf_installation_dir}

    # Download Terraform from Hashicorp site
    curl -s -L --output ${tf_binary}.zip \
        https://releases.hashicorp.com/terraform/${tf_version}/terraform_${tf_version}_linux_amd64.zip

    # Install Terraform
    unzip -d ${tf_installation_dir} ${tf_binary}.zip
    chmod +x ${tf_binary}
    rm -f ${tf_binary}.zip
}

# install_tf_provider <installation_dir> <provider_name> <provider_source>
function install_tf_provider {
    provider_install_dir=${1}
    provider_name=${2}
    provider_binary="${provider_install_dir}/${provider_name}"
    provider_src=${3}

    # Create plugins dir
    mkdir -p ${provider_install_dir}

    # Download provider from source
    curl -s -L --output ${provider_binary}.tar.gz ${provider_src}

    # Install Provider
    tar -xvf ${provider_binary}.tar.gz -C ${provider_install_dir}
    chmod +x ${provider_binary}
    rm -f ${provider_binary}.tar.gz
}

# install_cfssl <installation_dir> <cfssl_version>
function install_cfssl {
    cfssl_install_dir=${1}
    cfssl_version=${2}

    curl -s -L --output ${cfssl_install_dir}/cfssl \
        https://pkg.cfssl.org/R${cfssl_version}/cfssl_linux-amd64

    curl -s -L --output ${cfssl_install_dir}/cfssljson \
        https://pkg.cfssl.org/R${cfssl_version}/cfssljson_linux-amd64

    chmod +x ${cfssl_install_dir}/cfssl ${cfssl_install_dir}/cfssljson
}

# install_kubectl <installation_dir> <kubectl_version>
function install_kubectl {
    kubectl_install_dir=${1}
    kubectl_version=${2}

    curl -s -L --output ${kubectl_install_dir}/kubectl \
        https://storage.googleapis.com/kubernetes-release/release/v${kubectl_version}/bin/linux/amd64/kubectl

    chmod +x ${kubectl_install_dir}/kubectl
}

# install_krew <installation_dir> <krew_version>
function install_krew {
    krew_install_dir=${1}
    krew_version=${2}
    krew_binary="${krew_install_dir}/kubectl-krew"

    curl -S -L --output ${krew_binary}.tar.gz \
        https://github.com/kubernetes-sigs/krew/releases/download/v${krew_version}/krew.tar.gz

    # Install krew
    tar -xvf ${krew_binary}.tar.gz -C ${krew_install_dir} ./krew-linux_amd64
    mv ${krew_install_dir}/krew-linux_amd64 ${krew_binary}
    chmod +x ${krew_binary}
    rm -f ${krew_binary}.tar.gz

    # Change plugins installation directory
    mkdir -p ${HOME}/.krew
    ln -s ${krew_install_dir} ${HOME}/.krew/bin
}

# install_helm <installation_dir> <helm_version>
function install_helm {
    helm_install_dir=${1}
    helm_version=${2}
    helm_binary="${helm_install_dir}/helm"

    curl -S -L --output ${helm_binary}.tar.gz \
        https://get.helm.sh/helm-v${helm_version}-linux-amd64.tar.gz

    # Install Helm
    tar -xvf ${helm_binary}.tar.gz -C ${helm_install_dir} --strip-components=1 linux-amd64/helm
    chmod +x ${helm_binary}
    rm -f ${helm_binary}.tar.gz
}

# Install libvirt
if ! (which virsh &> /dev/null); then
    echo "Follow the instructions to install libvirt in your linux distribution."
fi

# Install terraform
if ! (which terraform &> /dev/null); then
    echo "Installing Terraform ${TF_VERSION}..."
    install_terraform ${HOME}/bin ${TF_VERSION}
    echo "Successfully installed!"
else
    terraform_current_version=$(terraform version)
    echo "${terraform_current_version} is already installed."
fi

# Install libvirt provider plugin
if ! (ls ${TF_PROVIDERS_DIR}/terraform-provider-libvirt &> /dev/null); then
    echo "Installing libvirt provider for Terraform..."
    install_tf_provider ${TF_PROVIDERS_DIR} terraform-provider-libvirt \
        "https://github.com/dmacvicar/terraform-provider-libvirt/releases/download/${TF_LIBVIRT_PROVIDER_VERSION}"
    echo "Successfully installed!"
else
    libvirt_tf_current_version=$(echo "$(${TF_PROVIDERS_DIR}/terraform-provider-libvirt -version)" |\
        head -n 1 | rev | cut -d " " -f 1 | rev)
    echo "Libvirt provider ${libvirt_tf_current_version} for Terraform is already installed."
fi

# Install CloudFlare's PKI toolkit
if ! (which cfssl &> /dev/null); then
    echo "Installing CFSSL ${CFSSL_VERSION}..."
    install_cfssl ${HOME}/bin ${CFSSL_VERSION}
    echo "Successfully installed!"
else
    cfssl_current_version=$(cfssl version | head -n 1 | rev | cut -d " " -f 1 | rev)
    echo "CFSSL version ${cfssl_current_version} is already installed."
fi

# Install kubectl
if ! (which kubectl &> /dev/null); then
    echo "Installing kubectl ${KUBECTL_VERSION}..."
    install_kubectl ${HOME}/bin ${KUBECTL_VERSION}
    echo "Successfully installed!"
else
    kubectl_current_version=$(kubectl version --client --short)
    echo "Kubectl ${kubectl_current_version} is already installed."
fi

# Install Krew
if ! (which kubectl-krew &> /dev/null); then
    echo "Installing krew ${KREW_VERSION}..."
    install_krew ${HOME}/bin ${KREW_VERSION}
    echo "Successfully installed!"
else
    krew_current_version=$(kubectl-krew version | grep GitTag | awk '{print $2}')
    echo "krew version ${krew_current_version} is already installed."
fi

# Install Helm
if ! (which helm &> /dev/null); then
    echo "Installing Helm ${HELM_VERSION}..."
    install_helm ${HOME}/bin ${HELM_VERSION}
    echo "Successfully installed!"
else
    helm_current_version=$(helm version --short)
    echo "Helm version ${helm_current_version} is already installed."
fi
