from charms.reactive import hook
from charms.reactive import RelationBase
from charms.reactive import scopes


class ProvidesOpenVIMCompute(RelationBase):
    scope = scopes.GLOBAL

    auto_accessors = ['ssh_key']

    @hook('{provides:openvim-compute}-relation-{joined,changed}')
    def changed(self):
        self.set_state('{relation_name}.connected')
        if self.ssh_key():
            self.set_state('{relation_name}.available')

    @hook('{provides:openvim-compute}-relation-{broken,departed}')
    def departed(self):
        self.remove_state('{relation_name}.connected')
        self.remove_state('{relation_name}.available')

    def ssh_key_installed(self):
        convo = self.conversation()
        convo.set_remote('ssh_key_installed', True)

    def send_user(self, user):
        convo = self.conversation()
        convo.set_remote('user', user)