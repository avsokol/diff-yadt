################################################################################
#
#  ya_lcs - module for YaDT
#           provides procs like finding common longest substring (LCS),
#           ranges manipulation etc.
#
#  Copyright EMC Corp., 2014
#
#------------------------------------------------------------------------------
#
#  Packages  required:
#  Packages  dependencies: YaDT
#
################################################################################

package provide YaLcs 1.0

#===============================================================================

namespace eval ::YaLcs {

}

#===============================================================================

proc ::YaLcs::Compare2 { id1 id2 { upvar_lcsdata "" } } {

    variable ::Yadt::DIFF_FILES
    variable ::Yadt::OPTIONS
    variable ::Yadt::DIFF_TYPE
    global errorCode

    if { $upvar_lcsdata != "" } {
        upvar $upvar_lcsdata lcsdata
        set lcsdata {}
    }

    ::Yadt::Get_File_Strings $id1 $id2

    set lcsdata [ ::struct::list::LlongestCommonSubsequence2 $DIFF_FILES(test_strings,$id1) $DIFF_FILES(test_strings,$id2) ]

    if { !$OPTIONS(ignore_blanks) } {
        set lcsdata1 {}
        set lcsdata2 {}
        for { set i 0 } { $i < [ llength [ lindex $lcsdata 0 ] ] } { incr i } {
            set idx1 [ lindex [ lindex $lcsdata 0 ] $i ]
            set idx2 [ lindex [ lindex $lcsdata 1 ] $i ]
            if { [ lindex $DIFF_FILES(strings,$id1) $idx1 ] != [ lindex $DIFF_FILES(strings,$id2) $idx2 ] } {
                continue
            }
            lappend lcsdata1 $idx1
            lappend lcsdata2 $idx2
        }
        set lcsdata [ list $lcsdata1 $lcsdata2 ]
    }
        
    set diffs [ ::YaLcs::Convert_Lcs_Data_To_Diff2 $lcsdata \
                    [ llength $DIFF_FILES(test_strings,$id1) ] \
                    [ llength $DIFF_FILES(test_strings,$id2) ] ]

    return $diffs
}

#===============================================================================

proc ::YaLcs::Convert_Lcs_Data_To_Diff2 { lcsdata len1 len2 } {

    set diffs {}

    set diff_data [ ::struct::list::LlcsInvertMerge $lcsdata $len1 $len2 ]

    foreach item $diff_data {
        lassign $item kind idx1 idx2

        switch -exact -- $kind {
            added {
                set operation "a"
                set start [ lindex $idx1 1 ]
                set idx2_start [ expr [ lindex $idx2 0 ] + 1 ]
                set idx2_end   [ expr [ lindex $idx2 1 ] + 1 ]
                set end $idx2_start
                if { $idx2_end > $idx2_start} {
                    append end ",$idx2_end"
                }
            }
            deleted {
                set operation "d"
                set idx1_start [ expr [ lindex $idx1 0 ] + 1 ]
                set idx1_end   [ expr [ lindex $idx1 1 ] + 1 ]
                set start $idx1_start
                if { $idx1_end > $idx1_start } {
                    append start ",$idx1_end"
                }
                set end [ lindex [ lindex $idx2 1 ] end ]
            }
            changed {
                set operation "c"
                set idx1_start [ expr [ lindex $idx1 0 ] + 1 ]
                set idx1_end   [ expr [ lindex $idx1 1 ] + 1 ]

                set idx2_start [ expr [ lindex $idx2 0 ] + 1 ]
                set idx2_end   [ expr [ lindex $idx2 1 ] + 1 ]

                set start $idx1_start
                if { $idx1_end > $idx1_start } {
                    append start ",$idx1_end"
                }

                set end $idx2_start
                if { $idx2_end > $idx2_start} {
                    append end ",$idx2_end"
                }
            }
            unchanged {
                continue
            }
            default {
                return -code error "Unknown kind <$kind> in diff data."
            }
        }
        lappend diffs "$start$operation$end"
    }

    return $diffs
}

#===============================================================================

proc ::YaLcs::Convert_Diff2_To_Lcs_Data { diff2 id1 id2 len1 len2 } {

#    variable ::Yadt::DIFF_FILES

    set lines($id1) {}
    set lines($id2) {}
    
    for { set j 0 } { $j < $len1 } { incr j } {
        lappend lines($id1) $j
    }
    for { set j 0 } { $j < $len2 } { incr j } {
        lappend lines($id2) $j
    }
    
    
    # foreach i [ list $id1 $id2 ] {
    #     set len($i) [ llength $DIFF_FILES(strings,$i) ]
    #     set lines($i) {}
    #     for { set j 0 } { $j < $len($i) } { incr j } {
    #         lappend lines($i) $j
    #     }
    # }

    foreach diff $diff2 {

        foreach "thisdiff s($id1) e($id1) s($id2) e($id2) type" [ ::Yadt::Analyze_Diff2 $diff ] { }

        incr s($id1) -1
        incr e($id1) -1
        incr s($id2) -1
        incr e($id2) -1

        switch -- $type {
            "d" {
                set start($id1) [ lsearch $lines($id1) $s($id1) ]
                set end($id1)   [ lsearch $lines($id1) $e($id1) ]
                set lines($id1) [ lreplace $lines($id1) $start($id1) $end($id1) ]
            }
            "a" {
                set start($id2) [ lsearch $lines($id2) $s($id2) ]
                set end($id2)   [ lsearch $lines($id2) $e($id2) ]
                set lines($id2) [ lreplace $lines($id2) $start($id2) $end($id2) ]
            }
            "c" {
                set start($id1) [ lsearch $lines($id1) $s($id1) ]
                set end($id1)   [ lsearch $lines($id1) $e($id1) ]
                set start($id2) [ lsearch $lines($id2) $s($id2) ]
                set end($id2)   [ lsearch $lines($id2) $e($id2) ]

                set lines($id1) [ lreplace $lines($id1) $start($id1) $end($id1) ]
                set lines($id2) [ lreplace $lines($id2) $start($id2) $end($id2) ]
            }
            default {
                return -code error "Unexpected diff type <$type>"
            }
        }
    }

    set lcsdata [ list $lines($id1) $lines($id2) ]

    # AVS: Just for self-checking test
    # set test_diff [ ::YaLcs::Convert_Lcs_Data_To_Diff2 \
    #                     $lcsdata \
    #                     [ llength $DIFF_FILES(strings,$id1) ] \
    #                     [ llength $DIFF_FILES(strings,$id2) ] ]
    # if { $diff2 == $test_diff } {
    #     puts "TEST Ok"
    # } else {
    #     puts "TEST NoK"
    # }

    return $lcsdata
}

#===============================================================================

proc ::YaLcs::Convert_Lcs_Data_To_Line_Nums { lcsdata shift } {

    proc lcs2linenum { element shift } { expr $element + $shift }

    return [ ::struct::list::Lmap $lcsdata "lcs2linenum $shift" ]
}

#===============================================================================

proc ::YaLcs::Find_Unchanged_Diff3_Lines_From_Lcs_Data { lcs } {

    upvar $lcs lcsdata

    set id2 12
    set id3 13
    set check_list2 [ lindex $lcsdata(23) 0 ]
    set check_list3 [ lindex $lcsdata(23) 1 ]
    set max_equal_lines [ llength [ lindex $lcsdata($id2) 0 ] ]
    if { $max_equal_lines < [ llength [ lindex $lcsdata($id3) 0 ] ] } {
        set max_equal_lines [ llength [ lindex $lcsdata($id3) 0 ] ]
        set id2 13
        set id3 12
        set check_list2 [ lindex $lcsdata(23) 1 ]
        set check_list3 [ lindex $lcsdata(23) 0 ]
    }

    set master_list0 [ lindex $lcsdata($id2) 0 ]
    set master_list1 [ lindex $lcsdata($id2) 1 ]
    set slave_list0  [ lindex $lcsdata($id3) 0 ]
    set slave_list1  [ lindex $lcsdata($id3) 1 ]

    array unset unchanged_lines
    set unchanged_lines(1) {}
    set unchanged_lines($id2) {}
    set unchanged_lines($id3) {}

    for { set index1 0 } { $index1 < $max_equal_lines } { incr index1 } {

        # Get element from one of diffs2
        set el1 [ lindex $master_list0 $index1 ]

        # Search for this element in another diff2
        set index2 [ lsearch $slave_list0 $el1 ]
        if { $index2 < 0 } continue

        set el2 [ lindex $master_list1 $index1 ]
        set el3 [ lindex $slave_list1  $index2 ]

        # Final Check with 2vs3 diff
        set chk_idx2 [ lsearch $check_list2 $el2 ]
        if { $chk_idx2 < 0 } continue

        set chk_el [ lindex $check_list3 $chk_idx2 ]
        if { $chk_el != $el3 } continue

        lappend unchanged_lines(1)    $el1
        lappend unchanged_lines($id2) $el2
        lappend unchanged_lines($id3) $el3
    }

    return [ list $unchanged_lines(1) $unchanged_lines(12) $unchanged_lines(13) ]
}

#===============================================================================

proc ::YaLcs::Find_Lcs_Corresponding_Lines { lcs lines line } {

    upvar $lcs lcsdata
    upvar $lines ln

    set idx12 [ lsearch $lcsdata(12,1) $line ]
    set idx13 [ lsearch $lcsdata(13,1) $line ]

    if { $idx12 != -1 && $idx13 != -1 } {
        set ln12 [ lindex $lcsdata(12,2) $idx12 ]
        set ln13 [ lindex $lcsdata(13,3) $idx13 ]

        set idx23 [ lsearch $lcsdata(23,2) $ln12 ]
        set ln23 [ lindex $lcsdata(23,2) $idx23 ]

        set ln(1) $line

        if { $ln12 == $ln23 } {
            set ln(2) $ln12
            set ln(3) $ln13

            set lcsdata(12,1) [ lreplace $lcsdata(12,1) $idx12 $idx12 ]
            set lcsdata(12,2) [ lreplace $lcsdata(12,2) $idx12 $idx12 ]

            set lcsdata(13,1) [ lreplace $lcsdata(13,1) $idx13 $idx13 ]
            set lcsdata(13,3) [ lreplace $lcsdata(13,3) $idx13 $idx13 ]

            set lcsdata(23,2) [ lreplace $lcsdata(23,2) $idx13 $idx23 ]
            set lcsdata(23,3) [ lreplace $lcsdata(23,3) $idx13 $idx23 ]
        }

        if { $ln12 < $ln13 } {
            set ln(2) $ln12

            set lcsdata(12,1) [ lreplace $lcsdata(12,1) $idx12 $idx12 ]
            set lcsdata(12,2) [ lreplace $lcsdata(12,2) $idx12 $idx12 ]
        } 

        if { $ln12 >  $ln13 } {
            set ln(3) $ln13

            set lcsdata(13,1) [ lreplace $lcsdata(13,1) $idx13 $idx13 ]
            set lcsdata(13,3) [ lreplace $lcsdata(13,3) $idx13 $idx13 ]
        }

        return 1
    }

    set idx [ lsearch $lcsdata(12,1) $line ]
    if { $idx != -1 } {
        set ln(1) [ lindex $lcsdata(12,1) $idx ]
        set ln(2) [ lindex $lcsdata(12,2) $idx ]

        set lcsdata(12,1) [ lreplace $lcsdata(12,1) $idx $idx ]
        set lcsdata(12,2) [ lreplace $lcsdata(12,2) $idx $idx ]

        set idx23 [ lsearch $lcsdata(23,2) $ln(2) ]
        if { $idx23 != -1 } {
            set ln23 [ lindex $lcsdata(23,3) $idx23 ]

            if { $ln23 == $ln(1) } {
                set ln(3) $ln23
                set lcsdata(23,2) [ lreplace $lcsdata(23,2) $idx23 $idx23 ]
                set lcsdata(23,3) [ lreplace $lcsdata(23,3) $idx23 $idx23 ]
            }
        }

        return 1
    }

    set idx [ lsearch $lcsdata(12,2) $line ]
    if { $idx != -1 } {
        set ln(2) [ lindex $lcsdata(12,2) $idx ]
        set ln(1) [ lindex $lcsdata(12,1) $idx ]

        set lcsdata(12,1) [ lreplace $lcsdata(12,1) $idx $idx ]
        set lcsdata(12,2) [ lreplace $lcsdata(12,2) $idx $idx ]

        set idx [ lsearch $lcsdata(13,1) $ln(1) ]
        if { $idx != -1 } {
            set ln(3) [ lindex $lcsdata(13,3) $idx ]

            set lcsdata(13,1) [ lreplace $lcsdata(13,1) $idx $idx ]
            set lcsdata(13,3) [ lreplace $lcsdata(13,3) $idx $idx ]
        }

        return 1
    }

    set idx [ lsearch $lcsdata(13,1) $line ]
    if { $idx != -1 } {

        set ln(1) [ lindex $lcsdata(13,1) $idx ]
        set ln(3) [ lindex $lcsdata(13,3) $idx ]

        set lcsdata(13,1) [ lreplace $lcsdata(13,1) $idx $idx ]
        set lcsdata(13,3) [ lreplace $lcsdata(13,3) $idx $idx ]

        set idx [ lsearch $lcsdata(12,1) $ln(1) ]
        if { $idx != -1 } {
            set ln(2) [ lindex $lcsdata(12,2) $idx ]

            set lcsdata(12,1) [ lreplace $lcsdata(12,1) $idx $idx ]
            set lcsdata(12,2) [ lreplace $lcsdata(12,2) $idx $idx ]
        }

        return 1
    }

    set idx [ lsearch $lcsdata(13,3) $line ]
    if { $idx != -1 } {
        set ln(1) [ lindex $lcsdata(13,1) $idx ]
        set ln(3) [ lindex $lcsdata(13,3) $idx ]

        set lcsdata(13,1) [ lreplace $lcsdata(13,1) $idx $idx ]
        set lcsdata(13,3) [ lreplace $lcsdata(13,3) $idx $idx ]

        set idx [ lsearch $lcsdata(12,1) $ln(1) ]
        if { $idx != -1 } {
            set ln(2) [ lindex $lcsdata(12,2) $idx ]

            set lcsdata(12,1) [ lreplace $lcsdata(12,1) $idx $idx ]
            set lcsdata(12,2) [ lreplace $lcsdata(12,2) $idx $idx ]
        }

        return 1
    }

    set idx [ lsearch $lcsdata(23,2) $line ]
    if { $idx != -1 } {

        set ln(2) [ lindex $lcsdata(23,2) $idx ]
        set ln(3) [ lindex $lcsdata(23,3) $idx ]

        set lcsdata(23,2) [ lreplace $lcsdata(23,2) $idx $idx ]
        set lcsdata(23,3) [ lreplace $lcsdata(23,3) $idx $idx ]

        set idx [ lsearch $lcsdata(12,2) $ln(2) ]
        if { $idx != -1 } {
            set ln(1) [ lindex $lcsdata(12,1) $idx ]

            set lcsdata(12,1) [ lreplace $lcsdata(12,1) $idx $idx ]
            set lcsdata(12,2) [ lreplace $lcsdata(12,2) $idx $idx ]
        }

        return 1
    }

    set idx [ lsearch $lcsdata(23,3) $line ]
    if { $idx != -1 } {

        set ln(2) [ lindex $lcsdata(23,2) $idx ]
        set ln(3) [ lindex $lcsdata(23,3) $idx ]

        set lcsdata(23,2) [ lreplace $lcsdata(23,2) $idx $idx ]
        set lcsdata(23,3) [ lreplace $lcsdata(23,3) $idx $idx ]

        set idx [ lsearch $lcsdata(12,2) $ln(2) ]
        if { $idx != -1 } {
            set ln(1) [ lindex $lcsdata(12,1) $idx ]

            set lcsdata(12,1) [ lreplace $lcsdata(12,1) $idx $idx ]
            set lcsdata(12,2) [ lreplace $lcsdata(12,2) $idx $idx ]
        }

        return 1
    }

    return 0
}

#===============================================================================

proc ::YaLcs::Append_Border_Ranges { up_ranges start end } {

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
    foreach { s e } $ranges {
        lappend tmp_ranges [ list $s $e ]
    }        

    set ranges [ join [ lsort -unique -integer -index 1 $tmp_ranges ] ]
}

#===============================================================================

proc ::YaLcs::Combine_Ranges { up_ranges start end } {

    upvar $up_ranges ranges

    if ![ llength $ranges ] {
        set ranges "$start $end"
        return
    }

    set ranges [ ::YaLcs::Sort_Ranges $ranges ]

    if { $start == [ lindex $ranges 0 ] && $end == [ lindex $ranges end ] } {
        return
    }

    if { $start > [ lindex $ranges end ] } {
        set ranges [ concat $ranges $start $end ]
        return
    }

    if { $end < [ lindex $ranges 0 ] } {
        set ranges [ concat $start $end $ranges ]
        return
    }

    set new_ranges {}
    set intersect_ranges {}

    foreach { s e } $ranges {

        if { $s == $start && $e == $end } {
            lappend new_ranges $s $e
            continue
        }

        if { $e < $start } {
            lappend new_ranges $s $e
            continue
        }

        if { $s > $end } {
            lappend new_ranges $s $e
            continue
        }

        if { $s < $start && $e < $end } {
            lappend new_ranges $s [ expr $start - 1 ]
            lappend intersect_ranges $start $e
            continue
        }

        if { $s > $start && $e > $end } {
            lappend new_ranges [ expr $end + 1 ] $e
            lappend intersect_ranges $s $end
            continue
        }

        if { $s <= $start && $e >= $end } {
            foreach { st en } [ ::YaLcs::Split_Region_By_Ranges $s $e [ list $start $end ] ] {
                lappend new_ranges $st $en
            }
            ::YaLcs::Remove_Range new_ranges $s $e
            continue
        }

        lappend intersect_ranges $s $e
    }

    set r [ ::YaLcs::Split_Region_By_Ranges $start $end $intersect_ranges ]

    set ranges [ ::YaLcs::Sort_Ranges [ concat $new_ranges $r ] ]
}

#===============================================================================

proc ::YaLcs::Sort_Ranges { ranges } {

    set tmp_ranges {}

    foreach { s e } $ranges {
        lappend tmp_ranges [ list $s $e ]
    }

    set ranges [ join [ lsort -unique -integer -increasing -index 1 $tmp_ranges ] ]

    return $ranges
}

#===============================================================================

proc ::YaLcs::Remove_Range { up_ranges start end } {

    upvar $up_ranges ranges

    set new_ranges {}

    foreach { s e } $ranges {
        if { $s == $start && $e == $end } continue
        lappend new_ranges $s $e
    }

    set ranges $new_ranges
}

#===============================================================================

proc ::YaLcs::Split_Region_By_Ranges { start end ranges } {

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

proc ::YaLcs::Get_Other_Ids  { id } {

    switch -- $id {
        1 {
            return [ list 2 3 ]
        }
        2 {
            return [ list 1 3 ]
        }
        3 {
            return [ list 1 2 ]
        }
        default {
            return -code error "Unsupported empty_id <$id>"
        }
    }
}

#===============================================================================

proc ::YaLcs::Try_To_Split_Diffs { diffs id1 id2 lcsdata str_list1 str_list2 } {

    set modified 0

    set lcsdata0 [ lindex $lcsdata 0 ]
    set lcsdata1 [ lindex $lcsdata 1 ]

    foreach diff $diffs {

        foreach "thisdiff s($id1) e($id1) s($id2) e($id2) type" [ ::Yadt::Analyze_Diff2 $diff ] { }

        set size($id1) [ expr $e($id1) - $s($id1) ]
        set size($id2) [ expr $e($id2) - $s($id2) ]

        if { $size($id1) < 3 || $size($id2) < 3 } continue

        set ind_start($id1) [ expr $s($id1) - 1 ]
        set ind_end($id1)   [ expr $e($id1) - 1 ]
        set ind_start($id2) [ expr $s($id2) - 1 ]
        set ind_end($id2)   [ expr $e($id2) - 1 ]

        set str($id1) [ lrange $str_list1 $ind_start($id1) $ind_end($id1) ]
        set str($id2) [ lrange $str_list2 $ind_start($id2) $ind_end($id2) ]

        set lcs [ ::struct::list::LlongestCommonSubsequence2 $str($id1) $str($id2) ]

        set lcs0 [ lindex $lcs 0 ]
        set lcs1 [ lindex $lcs 1 ]

        if ![ llength $lcs0 ] continue
        
        set lcs0_tmp {}
        foreach element $lcs0 {
            lappend lcs0_tmp [ expr $element + $ind_start($id1) ]
        }
        set lcs0 $lcs0_tmp

        set lcs1_tmp {}
        foreach element $lcs1 {
            lappend lcs1_tmp [ expr $element + $ind_start($id2) ]
        }
        set lcs1 $lcs1_tmp

        set modified 1

        set lcsdata0 [ concat $lcsdata0 $lcs0 ]
        set lcsdata1 [ concat $lcsdata1 $lcs1 ]
    }

    if { $modified } {
        set lcsdata0 [ lsort -integer -increasing $lcsdata0 ]
        set lcsdata1 [ lsort -integer -increasing $lcsdata1 ]
    }

    return [ list $lcsdata0 $lcsdata1 ]
}

#===============================================================================

proc ::Yadt::Get_Diff3_Info_Text { type1 type2 type3 } {

    switch -- $type1$type2$type3 {
        "ccc" {
            set change_text1 "!"
            set change_text2 "!"
            set change_text3 "!"
        }
        "cca" {
            set change_text1 "-"
            set change_text2 "-"
            set change_text3 " "
        }
        "cac" {
            set change_text1 "-"
            set change_text2 " "
            set change_text3 "-"
            }
        "acc" {
            set change_text1 " "
            set change_text2 "+"
            set change_text3 "+"
        }
        "caa" {
            set change_text1 "-"
            set change_text2 " "
            set change_text3 " "
        }
        "aca" {
            set change_text1 " "
            set change_text2 "+"
            set change_text3 " "
        }
        "aac" {
            set change_text1 " "
            set change_text2 " "
            set change_text3 "+"
        }
        "aaa" -
        default {
            return -code error "Incorrect data <$type1$type2$type3> from diff3 in [ lindex [ info level 0 ] 0 ]"
        }
    }

    return [ list $change_text1 $change_text2 $change_text3 ]
}

#===============================================================================
