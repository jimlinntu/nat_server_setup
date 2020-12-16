# NAT Server Setup

## Setup

(NAT Server: Ubuntu 18.04)
* `if=enp5s0`: internal network
* `of=enp0s31f6`: outward network
* `ip addr add 10.0.0.1/24 dev $if`: Add a static ip `10.0.0.1` for it.
```
$ ip addr
2: enp5s0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether 70:85:c2:49:44:df brd ff:ff:ff:ff:ff:ff
    inet 10.0.0.1/24 scope global enp5s0
       valid_lft forever preferred_lft forever
    inet6 fe80::7285:c2ff:fe49:44df/64 scope link
       valid_lft forever preferred_lft forever
```
* `iptables -t nat -I POSTROUTING 1 -s 10.0.0.0/24 -o "$of" -j MASQUERADE`: Perform Source NAT when the input IP is in `10.0.0.0/24`. And substitute that IP to `$of`.
* `iptables -A INPUT -i "$if" -j ACCEPT`: In case your default policy of `INPUT` is `DROP`.
* Allow bidirectional connections. (It should depend on your machine's default policy, mine is `Chain FORWARD (policy DROP 0 packets, 0 bytes)`)
    * `iptables -I FORWARD 1 -i "$if" -o "$of" -j ACCEPT`: Allow forwarding from `$if` to `$of`.
    * `iptables -I FORWARD 1 -i "$of" -o "$if" -j ACCEPT`: Allow forwarding from `$of` to `$if`.
```
$ iptables -L -v
Chain INPUT (policy ACCEPT 1816 packets, 1840K bytes)
 pkts bytes target     prot opt in     out     source               destination
    9  2952 ACCEPT     all  --  enp5s0 any     anywhere             anywhere

Chain FORWARD (policy DROP 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination
  125 17336 ACCEPT     all  --  enp0s31f6 enp5s0  anywhere             anywhere
  182 23136 ACCEPT     all  --  enp5s0 enp0s31f6  anywhere             anywhere

$ iptables -t nat -L -v
Chain POSTROUTING (policy ACCEPT 353 packets, 29982 bytes)
 pkts bytes target     prot opt in     out     source               destination
    5   420 MASQUERADE  all  --  any    enp0s31f6  10.0.0.0/24          anywhere
```
* set `net.ipv4.ip_forward=1` in `/etc/sysctl.conf`: allow this NAT Server to act as a router.
* `sysctl -p /etc/sysctl.conf`: load the configuration.

(Client: Ubuntu 20.04)
* `if=eno1`: internal network
* `ip addr add 10.0.0.2/24 dev $if`: Add a static ip `10.0.0.2` for it.
```
$ ip addr
2: eno1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether ac:1f:6b:6e:21:b2 brd ff:ff:ff:ff:ff:ff
    inet 10.0.0.2/24 scope global eno1
       valid_lft forever preferred_lft forever
    inet6 fe80::ae1f:6bff:fe6e:21b2/64 scope link
       valid_lft forever preferred_lft forever
```
* `ip route add default via 10.0.0.1 dev "$if"`: Add a default routing through `10.0.0.1` (the NAT server).
```
$ `ip route`
default via 10.0.0.1 dev eno1
10.0.0.0/24 dev eno1 proto kernel scope link src 10.0.0.2
```
* (Static IP configuration): `netplan apply` to take effect.
```
# This is the network config written by 'subiquity'
network:
  ethernets:
    eno1:
      addresses: [10.0.0.2/24]
      gateway4: 10.0.0.1
      nameservers:
        addresses: [208.67.222.222, 208.67.220.220]

  version: 2
```

## Troubleshooting
* `iptables -L -v` (default is `filter` table)
* `iptables -t nat -L -v`
* `ip route`
* `ip addr`
* `ping 10.0.0.1`
* `ping 10.0.0.2`
* `ping 8.8.8.8`

## References
* <https://wiki.archlinux.org/index.php/iptables>
* <http://linux.vbird.org/linux_server/0250simple_firewall.php#nat_what>
* <https://www.csie.ntu.edu.tw/~b93070/CNL/v4.0/CNLv4.0.files/Page1504.htm>
* <https://askubuntu.com/questions/988218/make-a-machine-a-nat-router>
* <https://www.cyberciti.biz/faq/howto-iptables-show-nat-rules/>
* <https://www.cyberciti.biz/faq/howto-linux-configuring-default-route-with-ipcommand/>
* <https://www.cyberciti.biz/faq/ip-route-add-network-command-for-linux-explained/>
* <https://www.cyberciti.biz/faq/linux-iptables-insert-rule-at-top-of-tables-prepend-rule/>
* <https://www.howtogeek.com/177621/the-beginners-guide-to-iptables-the-linux-firewall/>
* <https://help.ubuntu.com/community/IptablesHowTo>
* <https://www.cyberciti.biz/faq/reload-sysctl-conf-on-linux-using-sysctl/>
* <https://www.linuxtechi.com/assign-static-ip-address-ubuntu-20-04-lts/>
* <https://serverfault.com/questions/914493/ubuntu-18-04-doesnt-load-iptables-rules-after-reboot>: I mainly consult this answer's code when writing `load_nat_iptables_rules.service`.
* <https://netplan.io/faq/>: Ubuntu official Netplan FAQ.
* <https://unix.stackexchange.com/questions/506347/why-do-most-systemd-examples-contain-wantedby-multi-user-target>: The meaning of `WantedBy`.
* [how to start a systemd service before networking starts?](https://unix.stackexchange.com/questions/229048/how-to-start-a-systemd-service-before-networking-starts)
* [systemd.service — Service unit configuration](https://www.freedesktop.org/software/systemd/man/systemd.service.html)
