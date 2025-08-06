# proc is a function. this is used later to connect all the vdd! and vss! together.
proc connectGlobalNets {} {
	globalNetConnect vdd! -type pgpin -pin vdd! -all
	globalNetConnect vss! -type pgpin -pin vss! -all
	globalNetConnect vdd! -type tiehi -all
	globalNetConnect vss! -type tielo -all
	applyGlobalNets
}

# set the top level module name (used elsewhere in the scripts)
set design_toplevel cpu

# set the verilog file to pnr
set init_verilog ../synth/outputs/$design_toplevel.v

# set the lef file of your standard cells
# when you add your regfile lef, it is here
# if you want to supply more than one lef use the following syntax:
# set init_lef_file "1.lef 2.lef"
set init_lef_file [list ../stdcells.lef ../regfile.lef]

# actually set the top level cell name
set init_top_cell $design_toplevel

# set power and ground net names
set init_pwr_net vdd!
set init_gnd_net vss!

# set multi-mode multi-corner file
# this file contains the operating conditions used to evaluate timing
# for your design. In our case, we just use the single lib file as our corner.
# In ECE 498HK, this will contain slow, typical and fast corners
# for the wires and the standard cells
set init_mmmc_file mmmc.tcl

# actually init the design
init_design

# connect all the global nets in the design together (vdd!, vss!)
# the function is defined above.
connectGlobalNets

# TODO floorplan your design. Put the size of your chip that you want here.
floorPlan -site CoreSite -d 150 150 10 10 10 10

# create the horizontal vdd! and vss! wires used by the standard cells.
sroute -allowJogging 0 -allowLayerChange 0 -crossoverViaLayerRange { metal7 metal1 } -layerChangeRange { metal7 metal1 } -nets { vss! vdd! }

# create a power ring around your processor, connecting all the vss! and vdd! together physically.
addRing \
	-follow core \
	-offset {top 2 bottom 2 left 2 right 2} \
	-spacing {top 2 bottom 2 left 2 right 2} \
	-width {top 2 bottom 2 left 2 right 2} \
	-layer {top metal7 bottom metal7 left metal8 right metal8} \
	-nets { vss! vdd! }

# TODO add power grid
addStripe -nets {vdd! vss!} -layer metal8 -direction vertical \
  -width 0.5 -spacing 1.0 -number_of_sets 2 -start_offset 10

# TODO restrict routing to only metal 6
setDesignMode -topRoutingLayer metal6 -bottomRoutingLayer metal1

# TODO for the regfile part, place the regfile marco
placeInstance datapath/bitslices[0].bitslice/regfile 70.0 70.0

# TODO specify where are the pins
# editPin -pinNames { clk reset data_in[31:0] data_out[31:0] } \
# 	-layer metal5 \
# 	-edge top \
# 	-offset 10 \
# 	-spacing 5
editPin -pin clk -layer metal6 -assign 10 9 -side LEFT -fixed
editPin -pin rst -layer metal6 -assign 10 10 -side LEFT -fixed

for {set i 0} {$i < 32} {incr i} {
    editPin -pin "imem_addr[$i]" -layer metal6 -assign [expr 1 + $i*.30] 100 -side BOTTOM -fixed
    editPin -pin "imem_rdata[$i]" -layer metal6 -assign [expr 25 + $i*.30] 100 -side BOTTOM -fixed
}

for {set i 0} {$i < 32} {incr i} {
    editPin -pin "dmem_addr[$i]" -layer metal6 -assign [expr 1 + $i*.30] 0 -side TOP -fixed
    editPin -pin "dmem_wdata[$i]" -layer metal6 -assign [expr 25 + $i*.30] 0 -side TOP -fixed
    editPin -pin "dmem_rdata[$i]" -layer metal6 -assign [expr 50 + $i*.30] 0 -side TOP -fixed
}

editPin -pin dmem_write -layer metal6 -assign 200 50 -side RIGHT -fixed
editPin -pin dmem_wmask[0] -layer metal6 -assign 200 60 -side RIGHT -fixed
editPin -pin dmem_wmask[1] -layer metal6 -assign 200 70 -side RIGHT -fixed
editPin -pin dmem_wmask[2] -layer metal6 -assign 200 80 -side RIGHT -fixed
editPin -pin dmem_wmask[3] -layer metal6 -assign 200 90 -side RIGHT -fixed


# TODO uncomment the two below command to do pnr. These steps takes innovus more time.

# place all the standard cells in your design. This command is actually a series of many
# mini commands and settings, but it tries to optimally place the standard cells in your design
# considering area, timing, routing congestion, routing length, and other things.
# See "man place_design" to find out more.
place_design

routeDesign

connectGlobalNets

# TODO find the command that checks DRC
verify_drc > drc.rpt

# save your design as a GDSII, which you can open in Virtuoso
streamOut innovus.gdsii -mapFile "/class/ece425/innovus.map"

# save the design, so innovus can open it later
saveDesign $design_toplevel
