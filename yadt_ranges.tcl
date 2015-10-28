################################################################################
#
#  yadt_ranges - module for YaDT
#           provides procs for range manipulation
#
#
#
#------------------------------------------------------------------------------
#
#  Packages  required:
#  Packages  dependencies: YaDT
#
################################################################################

package provide YadtRange 1.0

#===============================================================================

namespace eval ::YadtRange {

}

# Ranges inside diff3 variables - used for expert merge mode
# RANGES:
#     keys - ranges id,
#     values - list of range's 'start_line end_line type'
# RANGES2DIFF:
#     keys - ranges id,
#     values 'diff_id', diff3 id, which correspond to current range
# DIFFS2RANGES:
#     keys - diff_id, normal diff3_id
#     values - list of ranges id, which are inside of this diff3 id
variable ::YadtRange::RANGES
variable ::YadtRange::RANGES2DIFF
variable ::YadtRange::DIFF2RANGES

#===============================================================================

proc ::YadtRange::Wipe {} {

    variable ::YadtRange::RANGES
    variable ::YadtRange::RANGES2DIFF
    variable ::YadtRange::DIFF2RANGES

    array unset RANGES
    array unset RANGES2DIFF
    array unset DIFF2RANGES
}

#===============================================================================

proc ::YadtRange::Get_Ranges_Num {} {

    variable ::YadtRange::RANGES

    return [ llength [ array names RANGES ] ]
}

#===============================================================================

proc ::YadtRange::Get_Range { idx args } {

    variable ::YadtRange::RANGES

    set is_exists [ ::CmnTools::Get_Arg -exists args -exists ]

    if { $is_exists } {
        return [ info exists RANGES($idx) ]
    }

    return $RANGES($idx)
}

#===============================================================================

proc ::YadtRange::Set_Range { idx start end type } {

    variable ::YadtRange::RANGES

    set RANGES($idx) [ list $start $end $type ]
}

#===============================================================================

proc ::YadtRange::Get_Diff_Id_For_Range { range_id } {

    variable ::YadtRange::RANGES2DIFF

    if { $range_id == 0 } {
        return 0
    }

    return $RANGES2DIFF($range_id)
}

#===============================================================================

proc ::YadtRange::Set_Diff_Id_For_Range { range_id diff_id } {

    variable ::YadtRange::RANGES2DIFF

    set RANGES2DIFF($range_id) $diff_id
}

#===============================================================================

proc ::YadtRange::Append_Range_To_Diff_Id { diff_id range } {

    variable ::YadtRange::DIFF2RANGES

    lappend DIFF2RANGES($diff_id) $range
}

#===============================================================================

proc ::YadtRange::Get_Ranges_For_Diff_Id { diff_id } {

    variable ::YadtRange::DIFF2RANGES

    if { $diff_id == 0 } {
        return {}
    }

    return $DIFF2RANGES($diff_id)
}

#===============================================================================

proc ::YadtRange::Get_Top_Range_For_Diff_Id { diff_id } {

    variable ::YadtRange::DIFF2RANGES

    if { $diff_id == 0 } {
        return 0
    }

    return [ lindex $DIFF2RANGES($diff_id) 0 ]
}

#===============================================================================

proc ::YadtRange::Append_Border_Ranges { up_ranges start end } {

    upvar $up_ranges ranges

    if ![ llength $ranges ] {
        set ranges "$start $end"
        return
    }

    if { $start < [ lindex $ranges 0 ] } {
        set ranges [ concat $start [ expr [ lindex $ranges 0 ] - 1 ] $ranges ]
    }
    if { $end > [ lindex $ranges end ] } {
        set ranges [ concat $ranges [ expr [ lindex $ranges end ] + 1 ] $end ]
    }
}

#===============================================================================

proc ::YadtRange::Combine_Ranges { up_ranges diff_id } {

    upvar $up_ranges ranges

    set ranges [ ::YadtRange::Sort_Ranges $ranges ]

    set new_ranges {}
    
    foreach { s e } $ranges {
        if { ![ info exists start ] && ![ info exists end ] } {
            set start $s
            set end $e
            continue
        }

        if { $e < $start } {
            lappend new_ranges $s $e
            set start $s
            set end $e
            continue
        }

        if { $s > $end } {
            lappend new_ranges $start $end
            set start $s
            set end $e
            continue
        }

        if { $s <= $end } {
            if { $s > $start } {
                lappend new_ranges $start [ expr $s - 1 ]
            }
            if { $e < $end } {
                lappend new_ranges $s $e
                set start [ expr $e + 1 ]
                continue
            }
            if { $e == $end } {
                lappend new_ranges $s $e
                unset start
                unset end
                continue
            }

            if { $e > $end } {
                lappend new_ranges $s [ expr $end ]
                set start [ expr $end + 1 ]
                set end $e
                continue
            }
        }
    }

    if { [ info exists start ] && [ info exists end ] } {
        lappend new_ranges $start $end
    }

    if { $ranges == $new_ranges } {
        return
    }

    set ranges $new_ranges
    Combine_Ranges ranges $diff_id
}

#===============================================================================

proc ::YadtRange::Sort_Ranges { ranges } {

    set tmp_ranges {}

    foreach { s e } $ranges {
        lappend tmp_ranges [ list $s $e ]
    }

    set ranges [ join [ lsort -unique -integer -increasing -index 0 $tmp_ranges ] ]

    return $ranges
}

#===============================================================================

proc ::YadtRange::Remove_Range { up_ranges start end } {

    upvar $up_ranges ranges

    set new_ranges {}

    foreach { s e } $ranges {
        if { $s == $start && $e == $end } continue
        lappend new_ranges $s $e
    }

    set ranges $new_ranges
}

#===============================================================================

proc ::YadtRange::Split_Region_By_Ranges { start end ranges } {

    set new_ranges {}

    set prev_r_start $start
    set prev_r_end [ expr [ lindex $ranges 0 ] - 1 ]

    if { $prev_r_start <= $prev_r_end } {
        lappend new_ranges $prev_r_start $prev_r_end
    } else {
        set prev_r_end $prev_r_start
    }

    set r_end $end

    foreach [ list r_start r_end ] $ranges {

        if { $prev_r_end < [ expr $r_start - 1 ] } {
            lappend new_ranges [ expr $prev_r_end + 1 ] [ expr $r_start - 1 ]
        }

        lappend new_ranges $r_start $r_end

        set prev_r_start $r_start
        set prev_r_end $r_end
    }

    if { $r_end < $end } {
        lappend new_ranges [ expr $r_end + 1 ] $end
    }

    return $new_ranges
}

#===============================================================================

proc ::YadtRange::Get_Border_Ranges { start diff_size shift } {

    upvar $start s
    upvar $diff_size size
    upvar $shift full_shift

    set sizes {}
    for { set i 1 } { $i <= [ ::Yadt::Get_Diff_Type ] } { incr i } {
        lappend sizes [ expr $size($i) + $full_shift($i) ]
    }

    set shifted_size_max [ ::CmnTools::MaxN {*}$sizes ]

    set r_start [ expr $s(1) + [ ::Yadt::Get_Current_Delta 1 ] ]
    set r_end   [ expr $r_start + $shifted_size_max - 1 ]
    return [ list $r_start $r_end ]
}

#===============================================================================

proc ::YadtRange::Add_Info_Strings_In_Range { start diff_size ch_text } {

    upvar $start s
    upvar $diff_size size
    upvar $ch_text change_text

    for { set i 1 } { $i <= [ ::Yadt::Get_Diff_Type ] } { incr i } {
        for { set j 0 } { $j < $size($i) } { incr j } {
            set line($i) [ expr $s($i) + $j ]
            set wdg [ ::Yadt::Get_Diff_Wdg_List $i "info" ]
            $wdg insert $line($i).0 $change_text($i)
        }
    }
}

#===============================================================================

proc ::YadtRange::Move_Lines { lines shift_up ch_text } {

    upvar $lines ln
    upvar $shift_up shift
    upvar $ch_text change_text

    for { set i 1 } { $i <= [ ::Yadt::Get_Diff_Type ] } { incr i } {
        for { set j 0 } { $j < $shift($i) } { incr j } {
            set mv_line $ln($i)

            foreach t_wdg [ ::Yadt::Get_Diff_Wdg_List $i ] {
                $t_wdg insert $mv_line.0 "\n"
            }
        }
    }

    ::YadtRange::Add_Info_Strings_In_Range ln shift change_text
}

#===============================================================================
