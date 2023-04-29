if {$argc != 3} {
    puts "The WLan.tcl script requires a 3 arguments: bandwidth packetsize errorRate.(e.g., WLan.tcl 1Mb 512 0.000001)"
    return 0
} else {
    set bandwidth [lindex $argv 0]
    set packetsize [lindex $argv 1]
    set err_rate [lindex $argv 2]
}

puts "------- Mac/802_11 bandwidth set to $bandwidth"
puts "------- packetsize set to $packetsize"
puts "------- error rate set to $err_rate"

# ======================================================================
# Defining Simulation options
# ======================================================================

set opt(chan)           Channel/WirelessChannel  ;# channel type
set opt(prop)           Propagation/TwoRayGround ;# radio-propagation model
set opt(netif)          Phy/WirelessPhy          ;# network interface type
set opt(mac)            Mac/802_11               ;# MAC type
set opt(ifq)            Queue/DropTail/PriQueue  ;# interface queue type
set opt(ll)             LL                       ;# link layer type
set opt(ant)            Antenna/OmniAntenna      ;# antenna model
set opt(ifqlen)         50                       ;# max packet in ifq
set opt(adhocRouting)   AODV                     ;# routing protocol
set opt(finish)         100                      ;# time to stop simulation
set opt(x)              600                      ;# X coordinate of the topography
set opt(y)              500                      ;# Y coordinate of the topography
set opt(nNodes)         9                        ;# number of nodes


# By default data rate is 1Mb, Note that wireless networks use electromagnetic waves rather than coax cable or similar, 
# the speed of transmitting data (dataRate) used instead of bandwidth.
Mac/802_11 set dataRate_ $bandwidth

# Create the simulator object
set ns [new Simulator]

# Create direcory
set traces "traces/"
file mkdir $traces

set nams "nams/"
file mkdir $nams

set scenario "$bandwidth-$packetsize-$err_rate"

# Set Up Tracing
#$ns use-newtrace
set tracefd [open $traces/$scenario.tr w]
set namtrace [open $nams/$scenario.nam w]
$ns trace-all $tracefd
$ns namtrace-all-wireless $namtrace $opt(x) $opt(y)

#Set Up Topography Object
set topo [new Topography]
$topo load_flatgrid $opt(x) $opt(y)

# Create an instance of General Operations Director, which keeps track of nodes and
# node-to-node reachability. The parameter is the total number of nodes in the simulation.
create-god $opt(nNodes)

# Configure nodes
$ns node-config -adhocRouting $opt(adhocRouting) \
                 -llType $opt(ll) \
                 -macType $opt(mac) \
                 -ifqType $opt(ifq) \
                 -ifqLen $opt(ifqlen) \
                 -antType $opt(ant) \
                 -propType $opt(prop) \
                 -phyType $opt(netif) \
                 -channel [new $opt(chan)] \
                 -topoInstance $topo \
                 -agentTrace ON \
                 -routerTrace ON \
                 -macTrace ON \
                 -movementTrace OFF 

#=====================================================
# Error Model Configuration
#=====================================================
$ns node-config -IncomingErrProc UniformErr \
                -OutgoingErrProc UniformErr

proc UniformErr {} {
    global err_rate
    set err [new ErrorModel]
    $err unit packet
    $err set rate_ $err_rate
    return $err
}


# Create nodes
set A [$ns node]
    $A set X_ 100
    $A set Y_ 400
    $A set Z_ 0

set B [$ns node]
    $B set X_ 50
    $B set Y_ 250
    $B set Z_ 0

set C [$ns node]
    $C set X_ 200
    $C set Y_ 300
    $C set Z_ 0

set D [$ns node]
    $D set X_ 100
    $D set Y_ 100
    $D set Z_ 0

set E [$ns node]
    $E set X_ 200
    $E set Y_ 200
    $E set Z_ 0

set F [$ns node]
    $F set X_ 300
    $F set Y_ 200
    $F set Z_ 0

set G [$ns node]
    $G set X_ 300
    $G set Y_ 300
    $G set Z_ 0

set H [$ns node]
    $H set X_ 400
    $H set Y_ 300
    $H set Z_ 0

set L [$ns node]
    $L set X_ 400
    $L set Y_ 200
    $L set Z_ 0


# A UDP agent accepts data in variable size chunks from an application, and segments the data if needed.
# The default maximum segment size (MSS) for UDP agents is 1000 byte.
Agent/UDP set packetSize_   2048

# Create UDP agents attach them to node A nd D
set udpA1 [new Agent/UDP]
$ns attach-agent $A $udpA1

# set udpA2 [new Agent/UDP]
# $ns attach-agent $A $udpA2

set udpD1 [new Agent/UDP]
$ns attach-agent $D $udpD1

# set udpD2 [new Agent/UDP]
# $ns attach-agent $D $udpD2

# Specify the CBR agent to genrate traffic over udpA
set cbrA1 [new Application/Traffic/CBR]
$cbrA1 set packetSize_ $packetsize
$cbrA1 set interval_ 0.05
$cbrA1 attach-agent $udpA1

# set cbrA2 [new Application/Traffic/CBR]
# $cbrA2 set packetSize_ $packetsize
# $cbrA2 set interval_ 0.01
# $cbrA2 attach-agent $udpA2


# Specify the CBR agent to genrate traffic over udpD
set cbrD1 [new Application/Traffic/CBR]
$cbrD1 set packetSize_ $packetsize
$cbrD1 set interval_ 0.05
$cbrD1 attach-agent $udpD1

# set cbrD2 [new Application/Traffic/CBR]
# $cbrD2 set packetSize_ $packetsize
# $cbrD2 set interval_ 0.01
# $cbrD2 attach-agent $udpD2

# Create Null agents (traffic sinks) and attach them to node H and L
set recvH1 [new Agent/Null]
$ns attach-agent $H $recvH1

# set recvH2 [new Agent/Null]
# $ns attach-agent $H $recvH2

set recvL1 [new Agent/Null]
$ns attach-agent $L $recvL1

# set recvL2 [new Agent/Null]
# $ns attach-agent $L $recvL2

# Connecting sender and receiver nodes
$ns connect $udpA1 $recvH1
$ns connect $udpD1 $recvL1
# $ns connect $udpA2 $recvL2
# $ns connect $udpD2 $recvH2

$ns initial_node_pos $A 30
$ns initial_node_pos $B 30
$ns initial_node_pos $C 30
$ns initial_node_pos $D 30
$ns initial_node_pos $E 30
$ns initial_node_pos $F 30
$ns initial_node_pos $G 30
$ns initial_node_pos $H 30
$ns initial_node_pos $L 30

$ns at 0.5 "$cbrA1 start"
$ns at 1.0 "$cbrD1 start"
# $ns at 2.0 "$cbrD2 start"
# $ns at 2.3 "$cbrA2 start"
$ns at $opt(finish) "finish"

proc finish {} {
    global ns tracefd namtrace
    $ns flush-trace
    close $tracefd
    close $namtrace
    exit 0
}

# Begin simulation
$ns run
