echo ' - Update system'
dnf update -y
echo ' - Disable swap'
swapoff -a
sed -i 's/^[^#]* swap /#&/' /etc/fstab
echo ' - Disable SELinux'
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
echo ' - Configure /etc/hosts'
echo -e "\n192.168.80.120 kubernetes          // For control plane endpoint\n192.168.80.130 k8smaster1          // For node Master1\n192.168.80.131 k8smaster2          // For node Master2\n192.168.80.132 k8smaster3          // For node Master3\n192.168.80.133 k8shost1            // For node Host1\n192.168.80.134 k8shost2            // For node Host2\n192.168.80.135 k8shost3            // For node Host3" | tee -a /etc/hosts > /dev/null
echo ' - Install iproute-tc'
dnf install -y iproute-tc
echo ' - Configure firewall'
firewall-cmd --permanent --add-port=6443/tcp
firewall-cmd --permanent --add-port=2379-2380/tcp
firewall-cmd --permanent --add-port=10250/tcp
firewall-cmd --permanent --add-port=10251/tcp
firewall-cmd --permanent --add-port=10252/tcp
firewall-cmd --permanent --add-port=30000-32767/tcp
firewall-cmd --reload
echo ' - Configure netfilter'
echo -e "overlay\nbr_netfilter" | tee -a /etc/modules-load.d/k8s.conf > /dev/null
modprobe overlay
modprobe br_netfilter
echo -e "net.bridge.bridge-nf-call-iptables  = 1\nnet.ipv4.ip_forward                 = 1\nnet.bridge.bridge-nf-call-ip6tables = 1" | tee -a /etc/sysctl.d/k8s.conf > /dev/null
sysctl --system
echo ' - Export VERSION'
export VERSION=1.22
echo ' - version is: $VERSION'
echo ' - Add repositories'
curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable.repo https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/CentOS_8/devel:kubic:libcontainers:stable.repo
curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable:cri-o:${VERSION}.repo https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:${VERSION}/CentOS_8/devel:kubic:libcontainers:stable:cri-o:${VERSION}.repo
echo ' - Install cri-o'
dnf install cri-o cri-tools -y
systemctl daemon-reload
systemctl enable --now crio
echo ' - Add Kubernetes repository'
echo -e "[kubernetes]\nname=Kubernetes\nbaseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg\nexclude=kubelet kubeadm kubectl" | tee -a /etc/yum.repos.d/kubernetes.repo > /dev/null
echo ' - Install kube packages'
dnf install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
echo ' - Start Kubelet'
systemctl enable --now kubelet
echo ' - Completed!'