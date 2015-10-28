################################################################################
#
#  yadt_lcs - module for YaDT
#           provides procs to find longest common substring (LCS)
#
#
#
#------------------------------------------------------------------------------
#
#  Packages  required:
#  Packages  dependencies: Yadt, YadtDiff2
#
################################################################################

package provide YadtLcs 1.0

#===============================================================================

namespace eval ::YadtLcs {

}

#===============================================================================

proc ::YadtLcs::Compare2 { id1 id2 ignore_blanks { upvar_lcsdata "" } } {

    global errorCode

    if { $upvar_lcsdata != "" } {
        upvar $upvar_lcsdata lcsdata
        set lcsdata {}
    }

    ::Yadt::Get_File_Strings $id1 $id2

    set test_strings($id1) [ ::Yadt::Get_Diff_Files_Info "test_strings,$id1" ]
    set test_strings($id2) [ ::Yadt::Get_Diff_Files_Info "test_strings,$id2" ]

    set lcsdata [ ::struct::list::LlongestCommonSubsequence2 $test_strings($id1) $test_strings($id2) ]

    if { !$ignore_blanks } {
        set strings($id1) [ ::Yadt::Get_Diff_Files_Info "strings,$id1" ]
        set strings($id2) [ ::Yadt::Get_Diff_Files_Info "strings,$id2" ]        
        set lcsdata1 {}
        set lcsdata2 {}
        for { set i 0 } { $i < [ llength [ lindex $lcsdata 0 ] ] } { incr i } {
            set idx1 [ lindex [ lindex $lcsdata 0 ] $i ]
            set idx2 [ lindex [ lindex $lcsdata 1 ] $i ]
            if { [ lindex $strings($id1) $idx1 ] != [ lindex $strings($id2) $idx2 ] } {
                continue
            }
            lappend lcsdata1 $idx1
            lappend lcsdata2 $idx2
        }
        set lcsdata [ list $lcsdata1 $lcsdata2 ]
    }
        
    set diffs [ ::YadtLcs::Convert_Lcs_Data_To_Diff2 $lcsdata \
                    [ llength $test_strings($id1) ] \
                    [ llength $test_strings($id2) ] ]

    return $diffs
}

#===============================================================================

proc ::YadtLcs::Try_To_Split_Diffs_Having_Lcs { diffs id1 id2 lcsdata str_list1 str_list2 } {

    set modified 0

    set lcsdata0 [ lindex $lcsdata 0 ]
    set lcsdata1 [ lindex $lcsdata 1 ]

    foreach diff $diffs {

        lassign [ ::YadtDiff2::Analyze_Diff2 $diff ] thisdiff s($id1) e($id1) s($id2) e($id2) type

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

proc ::YadtLcs::Convert_Lcs_Data_To_Diff2 { lcsdata len1 len2 } {

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

proc ::YadtLcs::Convert_Diff2_To_Lcs_Data { diff2 id1 id2 len1 len2 } {

    for { set j 0 } { $j < $len1 } { incr j } {
        set lines[ set id1 ]($j) 1
    }
    for { set j 0 } { $j < $len2 } { incr j } {
        set lines[ set id2 ]($j) 1
    }

    foreach diff $diff2 {

        lassign [ ::YadtDiff2::Analyze_Diff2 $diff ] thisdiff s($id1) e($id1) s($id2) e($id2) type

        incr s($id1) -1
        incr e($id1) -1
        incr s($id2) -1
        incr e($id2) -1

        switch -- $type {
            "d" {
                for { set j $s($id1) } { $j <= $e($id1) } { incr j } {
                    unset lines[ set id1 ]($j)
                }
            }
            "a" {
                for { set j $s($id2) } { $j <= $e($id2) } { incr j } {
                    unset lines[ set id2 ]($j)
                }
            }
            "c" {
                for { set j $s($id1) } { $j <= $e($id1) } { incr j } {
                    unset lines[ set id1 ]($j)
                }
                for { set j $s($id2) } { $j <= $e($id2) } { incr j } {
                    unset lines[ set id2 ]($j)
                }
            }
            default {
                return -code error "Unexpected diff type <$type>"
            }
        }
    }

    set lcsdata [ list [ lsort -integer [ array names lines[ set id1 ] ] ] [ lsort -integer [ array names lines[ set id2 ] ] ] ]

    return $lcsdata
}

#===============================================================================

proc ::YadtLcs::Convert_Lcs_Data_To_Line_Nums { lcsdata shift } {

    set result {}
    foreach element $lcsdata {
        lappend result [ expr $element + $shift ]
    }
    return $result
}

#===============================================================================

proc ::YadtLcs::Find_Unchanged_Diff3_Lines_From_Lcs_Data { lcs } {

    upvar $lcs lcsdata

    set id2 12
    set id3 13
    set check_list0 [ lindex $lcsdata(23) 0 ]
    set check_list1 [ lindex $lcsdata(23) 1 ]
    if { [ llength [ lindex $lcsdata($id2) 0 ] ] < [ llength [ lindex $lcsdata($id3) 0 ] ] } {
        set id2 13
        set id3 12
        set check_list0 [ lindex $lcsdata(23) 1 ]
        set check_list1 [ lindex $lcsdata(23) 0 ]
    }

    set master_list0 [ lindex $lcsdata($id2) 0 ]
    set master_list1 [ lindex $lcsdata($id2) 1 ]
    set slave_list0  [ lindex $lcsdata($id3) 0 ]
    set slave_list1  [ lindex $lcsdata($id3) 1 ]

    array unset unchanged_lines
    set unchanged_lines(1) {}
    set unchanged_lines($id2) {}
    set unchanged_lines($id3) {}


    for { set i 0 } { $i < [ llength $master_list0 ] } { incr i } {
        set master_array([ lindex $master_list0 $i ]) [ lindex $master_list1 $i ]
    }

    for { set i 0 } { $i < [ llength $slave_list0 ] } { incr i } {
        set slave_array([ lindex $slave_list0 $i ]) [ lindex $slave_list1 $i ]
    }

    for { set i 0 } { $i < [ llength $check_list0 ] } { incr i } {
        set check_array([ lindex $check_list0 $i ]) [ lindex $check_list1 $i ]
    }

    foreach el1 [ lsort -integer [ array names master_array ] ] {

        if ![ info exists slave_array($el1) ] continue
        
        set el2 $master_array($el1)

        if ![ info exists check_array($el2) ] continue

        set el3 $slave_array($el1)

        if { $el3 != $check_array($el2) } continue

        lappend unchanged_lines(1)    $el1
        lappend unchanged_lines($id2) $el2
        lappend unchanged_lines($id3) $el3
    }

    return [ list $unchanged_lines(1) $unchanged_lines(12) $unchanged_lines(13) ]
}

#===============================================================================

proc ::YadtLcs::Find_Lcs_Corresponding_Lines { lcs lines line } {

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

        if { $ln12 == $ln13 } {
            set ln(2) $ln12
            set ln(3) $ln13

            set lcsdata(12,1) [ lreplace $lcsdata(12,1) $idx12 $idx12 ]
            set lcsdata(12,2) [ lreplace $lcsdata(12,2) $idx12 $idx12 ]

            set lcsdata(13,1) [ lreplace $lcsdata(13,1) $idx13 $idx13 ]
            set lcsdata(13,3) [ lreplace $lcsdata(13,3) $idx13 $idx13 ]

            set lcsdata(23,2) [ lreplace $lcsdata(23,2) $idx23 $idx23 ]
            set lcsdata(23,3) [ lreplace $lcsdata(23,3) $idx23 $idx23 ]
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
