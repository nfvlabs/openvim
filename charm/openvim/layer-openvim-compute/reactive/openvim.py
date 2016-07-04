from os import chmod
from charms.reactive import when, when_not, set_state
from charmhelpers.core.hookenv import status_set
from charmhelpers.core.unitdata import kv
from charmhelpers.core.host import mkdir, symlink, chownr, add_user_to_group
from charmhelpers.fetch.archiveurl import ArchiveUrlFetchHandler
from charmhelpers.contrib.unison import ensure_user

def create_openvim_user():
    status_set("maintenance", "Creating OpenVIM user")
    ensure_user('openvim')

def group_openvim_user():
    status_set("maintenance", "Adding OpenVIM user to groups")
    add_user_to_group('openvim', 'libvirtd')
    add_user_to_group('openvim', 'sudo')

def nopasswd_openvim_sudo():
    status_set("maintenance", "Allowing nopasswd sudo for OpenVIM user")
    with open('/etc/sudoers', 'r+') as f:
        data = f.read()
        if 'openvim ALL=(ALL) NOPASSWD:ALL' not in data:
            f.seek(0)
            f.truncate()
            data += '\nopenvim ALL=(ALL) NOPASSWD:ALL\n'
            f.write(data)

def setup_qemu_binary():
    status_set("maintenance", "Setting up qemu-kvm binary")
    mkdir('/usr/libexec', owner='root', group='root', perms=0o775, force=False)
    symlink('/usr/bin/kvm', '/usr/libexec/qemu-kvm')

def setup_images_folder():
    status_set("maintenance", "Setting up VM images folder")
    mkdir('/opt/VNF', owner='openvim', group='openvim', perms=0o775, force=False)
    symlink('/var/lib/libvirt/images', '/opt/VNF/images')
    chownr('/opt/VNF', owner='openvim', group='openvim', follow_links=False, chowntopdir=True)
    chownr('/var/lib/libvirt/images', owner='root', group='openvim', follow_links=False, chowntopdir=True)
    chmod('/var/lib/libvirt/images', 0o775)

def download_default_image():
    status_set("maintenance", "Downloading default image")
    fetcher = ArchiveUrlFetchHandler()
    fetcher.download(
        source="https://cloud-images.ubuntu.com/releases/16.04/release/ubuntu-16.04-server-cloudimg-amd64-disk1.img",
        dest="/opt/VNF/images/ubuntu-16.04-server-cloudimg-amd64-disk1.img"
        # TODO: add checksum
    )

@when_not('openvim-compute.installed')
def prepare_openvim_compute():
    create_openvim_user()
    group_openvim_user()
    nopasswd_openvim_sudo()
    setup_qemu_binary()
    setup_images_folder()
    download_default_image()
    status_set("active", "Ready")
    set_state('openvim-compute.installed')

@when('compute.available', 'openvim-compute.installed')
def install_ssh_key(compute):
    cache = kv()
    if cache.get("ssh_key:" + compute.ssh_key()):
        return
    mkdir('/home/openvim/.ssh', owner='openvim', group='openvim', perms=0o775)
    with open("/home/openvim/.ssh/authorized_keys", 'a') as f:
        f.write(compute.ssh_key() + '\n')
    compute.ssh_key_installed()
    cache.set("ssh_key:" + compute.ssh_key(), True)

@when('compute.connected')
def send_user(compute):
    compute.send_user('openvim')
