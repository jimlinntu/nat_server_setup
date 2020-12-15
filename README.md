# NAT Server Setup

## Setup

(NAT Server)
* `if=enp5s0`: internal network
* `of=enp0s31f6`: outward network
* `ip addr add 10.0.0.1/24 dev $if`: Add a static ip `10.0.0.1` for it.
* `iptables -t nat -I POSTROUTING 1 -s 10.0.0.0/24 -o "$of" -j MASQUERADE`: Perform Source NAT when the input IP is in `10.0.0.0/24`. And substitute that IP to `$of`.
* `iptables -A INPUT -i "$if" -j ACCEPT`: In case your default policy of `INPUT` is `DROP`.
* Allow bidirectional connections. (It should depend on your machine's default policy, mine is `Chain FORWARD (policy DROP 0 packets, 0 bytes)`)
    * `iptables -I FORWARD 1 -i "$if" -o "$of" -j ACCEPT`: Allow forwarding from `$if` to `$of`.
    * `iptables -I FORWARD 1 -i "$of" -o "$if" -j ACCEPT`: Allow forwarding from `$of` to `$if`.
* set `net.ipv4.ip_forward=1` in `/etc/sysctl.conf`: allow this NAT Server to act as a router.
* `sysctl -p /etc/sysctl.conf`: load the configuration.

(Client)
* `if=eno1`: internal network
* `ip addr add 10.0.0.2/24 dev $if`: Add a static ip `10.0.0.2` for it.
* `ip route add default via 10.0.0.1 dev "$if"`: Add a default routing through `10.0.0.1` (the NAT server).

## Troubleshooting
* `iptables -L -v` (default is `filter` table)
* `iptables -t nat -L -v`
* `ip route`
* `ip addr`
* `ping 10.0.0.1`
* `ping 10.0.0.2`

## References
* <https://wiki.archlinux.org/index.php/iptables>
* <http://linux.vbird.org/linux_server/0250simple_firewall.php#nat_what>
* <https://www.csie.ntu.edu.tw/~b93070/CNL/v4.0/CNLv4.0.files/Page1504.htm>
* <https://askubuntu.com/questions/988218/make-a-machine-a-nat-router>
