#!/usr/bin/env bash

# internal NIC
if=enp5s0
# outward NIC
of=enp0s31f6

iptables -t nat -C POSTROUTING -s 10.0.0.0/24 -o "$of" -j MASQUERADE
# this rule is not present
if [[ $? != 0 ]]; then
    echo "Add MASQUERADE iptables rule"
    iptables -t nat -I POSTROUTING 1 -s 10.0.0.0/24 -o "$of" -j MASQUERADE
else
    echo "MASQUERADE rule is already present"
fi

iptables -C INPUT -i "$if" -j ACCEPT
if [[ $? != 0 ]]; then
    echo "Add ACCEPT for ${if}"
    iptables -A INPUT -i "$if" -j ACCEPT
else
    echo "ACCEPT for ${if} is already present"
fi

iptables -C FORWARD -i "$if" -o "$of" -j ACCEPT
if [[ $? != 0 ]]; then
    echo "Add FORWARD ACCEPT from ${if} to ${of}"
    iptables -I FORWARD 1 -i "$if" -o "$of" -j ACCEPT
else
    echo "FORWARD ACCEPT from ${if} to ${of} is already present"
fi

iptables -C FORWARD -i "$of" -o "$if" -j ACCEPT
if [[ $? != 0 ]]; then
    echo "Add FORWARD ACCEPT from ${of} to ${if}"
    iptables -I FORWARD 1 -i "$of" -o "$if" -j ACCEPT
else
    echo "FORWARD ACCEPT from ${of} to ${if} is already present"
fi

exit 0
