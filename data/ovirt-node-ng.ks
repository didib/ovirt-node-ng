#
# Platform repositories
#
url --url=http://mirror.centos.org/centos/7/os/x86_64/
repo --name=updates --mirrorlist=http://mirrorlist.centos.org/?repo=updates&release=$releasever&arch=$basearch
repo --name=extra --mirrorlist=http://mirrorlist.centos.org/?repo=extras&release=$releasever&arch=$basearch

#url --mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=fedora-$releasever&arch=$basearch
#repo --name=updates --mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=updates-released-f$releasever&arch=$basearch
#repo --name=updates-testing --mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=updates-testing-f$releasever&arch=$basearch


lang en_US.UTF-8
keyboard us
timezone --utc Etc/UTC
network
auth --enableshadow --passalgo=sha512
selinux --permissive
rootpw --lock
user --name=node --lock
firstboot --reconfig

clearpart --all --initlabel
bootloader --timeout=1
part / --size=3072 --fstype=ext4 --fsoptions=discard

poweroff


#
# Packages
#
%packages --excludedocs --ignoremissing
@core

#
# Additional packages for EFI support
# https://www.brianlane.com/creating-live-isos-with-livemedia-creator.html
# http://lorax.readthedocs.org/en/latest/livemedia-creator.html#kickstarts
dracut-config-generic
-dracut-config-rescue
grub2-efi
memtest86+
syslinux

#
# Needed at install time for layer mgmt
lvm2
imgbased
%end


#
# Add custom post scripts after the base post.
#
%post --erroronfail

# setup systemd to boot to the right runlevel
echo "Setting default runlevel to multiuser text mode"
rm -vf /etc/systemd/system/default.target
ln -vs /lib/systemd/system/multi-user.target /etc/systemd/system/default.target

echo "Cleaning old yum repodata."
yum clean all
%end


#
# Adds the latest cockpit bits
#
%post
set -x
grep -i centos /etc/system-release && yum-config-manager --add-repo="https://copr.fedoraproject.org/coprs/sgallagh/cockpit-preview/repo/epel-7/sgallagh-cockpit-preview-epel-7.repo"
#grep -i centos /etc/system-release && yum-config-manager --add-repo="http://cbs.centos.org/repos/virt7-testing/x86_64/os/"
grep -i centos /etc/system-release && yum install -y https://download.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm
yum install --nogpgcheck -y cockpit
%end


#
# Adding upstream oVirt vdsm
#
%post --erroronfail
set -x

yum install -y http://plain.resources.ovirt.org/pub/yum-repo/ovirt-release36.rpm
yum install --nogpgcheck -y vdsm
yum install --nogpgcheck -y vdsm-cli ovirt-engine-cli
yum install --nogpgcheck -y glusterfs-server
%end


#
# Add imgbased
#
%post
set -x
mkdir -p /etc/imgbased.conf.d
cat > /etc/imgbased.conf.d/50-ovirt.conf <<EOF
[remote node-stable]
url = http://jenkins.ovirt.org/job/ovirt-appliance-node_master_create-imgbased-index/lastSuccessfulBuild/artifact/stable/

[remote node-unstable]
url = http://jenkins.ovirt.org/job/ovirt-appliance-node_master_create-imgbased-index/lastSuccessfulBuild/artifact/unstable/
EOF

yum install -y git automake autoconf
git clone https://github.com/fabiand/imgbased.git
pushd imgbased
 ./autogen.sh && ./configure
 yum install -y $(make --silent rpm-build-deps)
 make install
popd

imgbase --debug --experimental image-build --postprocess
# imgbase --debug update --set-upstream node-unstable:org.ovirt.node.Node
%end