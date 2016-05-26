#!/bin/bash
awk '
($1=="lease" && $3=="{"){ lease=$2; active="no"; found="no" }
($1=="binding" && $2=="state" && $3=="active;"){ active="yes" }
($1=="hardware" && $2=="ethernet" && $3==tolower("'$1';")){ found="yes" }
($1=="client-hostname"){ name=$2 }
($1=="}"){ if (active=="yes" && found=="yes"){ target_lease=lease; target_name=name}}
END{printf("%s", target_lease)} #print target_name
' /var/lib/dhcp/dhcpd.leases

