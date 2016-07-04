from charms.reactive import hook
from charms.reactive import RelationBase
from charms.reactive import scopes


class RequiresOpenVIMCompute(RelationBase):
    scope = scopes.UNIT

    @hook('{requires:openvim-compute}-relation-{joined,changed}')
    def changed(self):
        self.set_state('{relation_name}.connected')
        if self.ready_to_ssh():
            self.set_state('{relation_name}.available')

    @hook('{requires:openvim-compute}-relation-{broken,departed}')
    def departed(self):
        self.remove_state('{relation_name}.connected')
        self.remove_state('{relation_name}.available')

    def send_ssh_key(self, key):
        for c in self.conversations():
            c.set_remote('ssh_key', key)

    def authorized_nodes(self):
        return [{
            'user': c.get_remote('user'),
            'address': c.get_remote('private-address'),
        } for c in self.conversations() if c.get_remote('ssh_key_installed')]

    def ready_to_ssh(self):
        return len(self.authorized_nodes()) > 0
