from charmhelpers.core import hookenv
from charms.reactive import hook
from charms.reactive import RelationBase
from charms.reactive import scopes


class OpenVimProvides(RelationBase):
    scope = scopes.GLOBAL

    @hook('{provides:openvim}-relation-{joined,changed}')
    def changed(self):
        self.set_state('{relation_name}.available')

    @hook('{provides:openvim}-relation-{broken,departed}')
    def broken(self):
        self.remove_state('{relation_name}.available')

    def configure(self, port, user):
        relation_info = {
            'hostname': hookenv.unit_get('private-address'),
            'port': port,
            'user': user,
        }
        self.set_remote(**relation_info)
