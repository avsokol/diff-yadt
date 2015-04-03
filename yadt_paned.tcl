################################################################################
#
#  yadt_paned - YaDT-specific module which
#           provides a wrapper for Tk panedwindow widget
#
#
#
#------------------------------------------------------------------------------
#
#  Packages  required:
#  Packages  dependencies:
#
################################################################################

package provide YadtPaned 1.0

#===============================================================================

namespace eval ::YadtPaned {

}

#===============================================================================

variable ::YadtPaned::FRA

#===============================================================================

proc ::YadtPaned::Save { wdg type } {

    variable ::YadtPaned::FRA

    ::tk::panedwindow::ReleaseSash $wdg $type

    set pane_num [ llength [ $wdg panes ] ]
    set sash_num [ expr $pane_num - 1 ]

    set orient [ $wdg cget -orient ]
    switch -- $orient {
        "horizontal" {
            set index 0
            set size width
        }
        "vertical" {
            set index 1
            set size height
        }
    }

    set pane_size [ winfo $size $wdg ]
    
    if { $pane_size < 0 } {
        set pane_size 1
    }

    for { set i 0 } { $i < $sash_num } { incr i } {
        set cur_coord [ expr { [ lindex [ $wdg sash coord $i ] $index ] } ]
        set cur_coord "${cur_coord}.0"
        set FRA($wdg,$i) [ expr { $cur_coord / $pane_size } ]
    }
}

#===============================================================================

proc ::YadtPaned::Resize { wdg } {

    variable ::YadtPaned::FRA

    update

    set orient [ $wdg cget -orient ]
    set pane_num [ llength [ $wdg panes ] ]
    set sash_num [ expr $pane_num - 1 ]

    switch -- $orient {
        "horizontal" {
            set size width
        }
        "vertical" {
            set size height
        }
    }

    set pane_size [ winfo $size $wdg ]

    if { $pane_size < 0 } {
        set pane_size 1
    }

    for { set i 0 } { $i < $sash_num } { incr i } {
        if ![ info exists FRA($wdg,$i) ] {
            continue
        }
        switch -- $orient {
            "horizontal" {
                set new_y [ lindex [ $wdg sash coord $i ] 1 ]
                set new_x [ expr { int($pane_size*$FRA($wdg,$i)) } ]
            }
            "vertical" {
                set new_x [ lindex [ $wdg sash coord $i ] 0 ] 
                set new_y [ expr { int($pane_size*$FRA($wdg,$i)) } ]
            }
        }
        $wdg sash place $i $new_x $new_y
    }

    update
    update idletasks
}

#===============================================================================

proc ::YadtPaned::Paned { action wdg args } {

    variable ::YadtPaned::FRA

    switch -- $action {
        -create {
            panedwindow $wdg {*}$args

            ::YadtPaned::Save $wdg 0
            bind $wdg <ButtonRelease-1> "::YadtPaned::Save %W 1"
            bind $wdg <ButtonRelease-2> "::YadtPaned::Save %W 0"
            bind $wdg <Configure> "::YadtPaned::Resize %W"
            return $wdg
        }
        -pack {
            pack $wdg {*}$args
        }
        -add {
            if { [ llength $args ] != 1 } {
                rerurn -code error "Incorrect number of argumets for <$action>"
            }
            frame $wdg.$args
            $wdg add $wdg.$args
            event generate $wdg <Configure>
            return $wdg.$args
        }
        -init {
            ::YadtPaned::Save $wdg 1
            event generate $wdg <Configure>
            ::YadtPaned::Paned -fraction $wdg default
        }
        -configure {
            after idle $wdg configure {*}$args
            update
            event generate $wdg <Configure>
        }
        -show {
            if { [ llength $args ] != 1 } {
                return -code error "Incorrect number of argumets for <$action>"
            }
            $wdg add $args
            return $args
        }
        -hide {
            if { [ llength $args ] != 1 } {
                return -code error "Incorrect number of argumets for <$action>"
            }
            $wdg forget $args
        }
        -fraction {
            set p_nums [ expr [ llength [ $wdg panes ] ] - 1 ]
            if { $args == "default" } {
                set fra [ expr 1.0 / [ llength [ $wdg panes ] ] ]
            } 
            set offset 0
            for { set i 0 } { $i < $p_nums } { incr i } {
                if ![ info exists fra ] {
                    set fra [ lindex $args $i ]
                }
                set FRA($wdg,$i) [ expr $fra + $offset ]
                set offset [ expr $offset + $fra ]
            }
            event generate $wdg <Configure>
        }
    }
}

#===============================================================================
