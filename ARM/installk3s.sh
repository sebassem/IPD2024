#!/bin/bash
sudo apt-get update


# Set k3 deployment variables
export K3S_VERSION="1.29.6+k3s2" # Do not change!

# Installing Azure CLI & Azure Arc extensions
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

echo ""
echo "Log in to Azure"
echo ""
for i in {1..5}; do
    sudo -u $adminUsername az login --identity
    if [[ $? -eq 0 ]]; then
        break
    fi
    sleep 15
    if [[ $i -eq 5 ]]; then
        echo "Error: Failed to login to Azure after 5 retries"
        exit 1
    fi
done

az -v


    # Installing Azure Arc extensions
    echo ""
    echo "Installing Azure Arc extensions"
    echo ""
    sudo -u $adminUsername az extension add --name connectedk8s --version 1.9.3
    sudo -u $adminUsername az extension add --name k8s-configuration
    sudo -u $adminUsername az extension add --name k8s-extension

    # Installing Rancher K3s cluster (single control plane)
    echo ""
    echo "Installing Rancher K3s cluster"
    echo ""
    publicIp=$(hostname -i)
    sudo mkdir ~/.kube
    sudo -u $adminUsername mkdir /home/${adminUsername}/.kube
    curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --disable traefik --disable servicelb --node-ip ${publicIp} --node-external-ip ${publicIp} --bind-address ${publicIp} --tls-san ${publicIp}" INSTALL_K3S_VERSION=v${K3S_VERSION} K3S_KUBECONFIG_MODE="644" sh -
    if [[ $? -ne 0 ]]; then
        echo "ERROR: K3s installation failed"
        exit 1
    fi

    # Installing Helm 3
    echo ""
    echo "Installing Helm"
    echo ""
    sudo snap install helm --classic
    if [[ $? -ne 0 ]]; then
        echo "ERROR: Helm installation failed"
        exit 1
    fi

    echo ""
    echo "Making sure Rancher K3s cluster is ready..."
    echo ""
    sudo kubectl wait --for=condition=Available --timeout=60s --all deployments -A >/dev/null
    sudo kubectl get nodes -o wide | expand | awk 'length($0) > length(longest) { longest = $0 } { lines[NR] = $0 } END { gsub(/./, "=", longest); print "/=" longest "=\\"; n = length(longest); for(i = 1; i <= NR; ++i) { printf("| %s %*s\n", lines[i], n - length(lines[i]) + 1, "|"); } print "\\=" longest "=/" }'

exit 0