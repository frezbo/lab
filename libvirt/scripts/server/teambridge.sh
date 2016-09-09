#!/bin/bash
ip netns add virt
ip netns exec virt ip link set dev lo up
ip link add eno1 type veth peer name etho1
ip link add eno2 type veth peer name etho2
ip link set etho1 netns virt
ip link set etho2 netns virt
ip netns exec virt ip link add name etho1_2 type bridge
ip netns exec virt ip link set etho1 master etho1_2
ip netns exec virt ip link set etho2 master etho1_2
ip netns exec virt ip addr add 10.10.0.254/24 dev etho1_2
ip netns exec virt ip link set dev etho1_2 up
ip netns exec virt ip link set dev etho1 up
ip netns exec virt ip link set dev etho2 up
ip link set dev eno1 up
ip link set dev eno2 up
systemctl restart network
