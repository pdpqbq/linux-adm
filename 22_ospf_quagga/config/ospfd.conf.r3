interface eth0
!
interface eth1
 ip ospf network point-to-point
 ip ospf hello-interval 3
 ip ospf dead-interval 6
!
interface eth2
 ip ospf network point-to-point
 ip ospf hello-interval 3
 ip ospf dead-interval 6
!
interface lo
!
router ospf
 ospf router-id 3.3.3.3
 log-adjacency-changes detail
 redistribute connected route-map con-ospf
 passive-interface default
 no passive-interface eth1
 no passive-interface eth2
 network 172.23.0.0/24 area 0.0.0.0
 network 172.31.0.0/24 area 0.0.0.0
!
ip prefix-list con-ospf seq 10 permit 3.3.3.3/32
ip prefix-list con-ospf seq 20 deny any
!
route-map con-ospf permit 10
 match ip address prefix-list con-ospf
!
line vty
!
