hostname r2
log file /var/log/quagga/quagga.log
!
interface eth0
 ipv6 nd suppress-ra
!
interface eth1
 ipv6 nd suppress-ra
!
interface eth2
 ipv6 nd suppress-ra
!
interface lo
!
ip prefix-list con-ospf seq 10 permit 2.2.2.2/32
ip prefix-list con-ospf seq 20 deny any
!
route-map con-ospf permit 10
 match ip address prefix-list con-ospf
!
ip forwarding
!
!
line vty
!
