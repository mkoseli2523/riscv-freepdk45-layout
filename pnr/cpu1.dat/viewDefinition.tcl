if {![namespace exists ::IMEX]} { namespace eval ::IMEX {} }
set ::IMEX::dataVar [file dirname [file normalize [info script]]]
set ::IMEX::libVar ${::IMEX::dataVar}/libs

create_library_set -name typLib\
   -timing\
    [list ${::IMEX::libVar}/mmmc/stdcells.lib]
create_rc_corner -name default_rc_corner\
   -preRoute_res 1\
   -postRoute_res 1\
   -preRoute_cap 1\
   -postRoute_cap 1\
   -postRoute_xcap 1\
   -preRoute_clkres 0\
   -preRoute_clkcap 0
create_delay_corner -name typDC\
   -library_set typLib
create_constraint_mode -name constraint_default\
   -sdc_files\
    [list ${::IMEX::libVar}/mmmc/cpu.sdc]
create_analysis_view -name typView -constraint_mode constraint_default -delay_corner typDC
set_analysis_view -setup [list typView] -hold [list typView]
