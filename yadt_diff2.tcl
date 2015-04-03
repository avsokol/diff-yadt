################################################################################
#
#  yadt_diff2 - module for YaDT
#           provides procs for comparing 2 files
#
#
#
#------------------------------------------------------------------------------
#
#  Packages  required:
#  Packages  dependencies: YaDT
#
################################################################################

package provide YadtDiff2 1.0

#===============================================================================

namespace eval ::YadtDiff2 {

}

#===============================================================================

proc ::YadtDiff2::Analyze_Diff2 { line } {
    # The line must be of the form <range><op><range>, where op is one of "a","c" or "d". 
    # Range will either be a single number or two numbers separated by a comma.

    if ![ regexp {^([0-9]*)(,([1-9]+[0-9]*))?(a|c|d)([0-9]*)(,([1-9]+[0-9]*))?$} \
              $line matchvar s1 x e1 op s2 x e2 ] {
                  return -code error "Cannot parse diff output:\n<$line>"
              }

    if ![ string length $e1 ] {
        set e1 $s1
    }
    if ![ string length $e2 ] {
        set e2 $s2
    }

    if { $s1 > $e1 || $s2 > $e2 } {
        return -code error "Incorrect data from diff:\n<$line>"
    }

    return [ list $line $s1 $e1 $s2 $e2 $op ]
}

#===============================================================================

proc ::YadtDiff2::Analyze_Out_Diff2 { content from args } {

    set diffs {}
    set lines [ split $content "\n" ]

    switch -- $from {
        -diff {
            if { $lines != "" && \
                     ![ regexp {^([0-9]*)(,([1-9]+[0-9]*))?(a|c|d)([0-9]*)(,([1-9]+[0-9]*))?$} \
                            [ lindex $lines 0 ] ] } {   
                return -code error "Unexpected output from diff:\n$lines"
            }
        }
        -cvs {
            if { $lines != "" } {
                set cvs_file [ ::CmnTools::Get_Arg -filename args ]
                set found_fname ""
                regexp "Index: (.*)" [ lindex $lines 0 ] dummy found_fname
                if { $found_fname == "" || \
                         [ file nativename $found_fname ] != \
                         [ file nativename $cvs_file ] } {
                    return -code error "Unexpected output from cvs diff:\n$content"
                }
            }
        }
        default {
            return -code error "Unsupported 'from'-value <$from> in <[ lindex [ info level 0 ] 0 ]>"
        }
    }

    foreach line $lines {
        if { [ string match {[0-9]*} $line ] } {
            lappend diffs $line
        }
    }

    return $diffs
}

#===============================================================================

proc ::YadtDiff2::Align_One_Diff2 { diff_id } {

    lassign [ ::Yadt::Get_Pdiff_For_Diff_Id $diff_id ] thisdiff s(1) e(1) s(2) e(2) type

    set size(1) [ expr { $e(1) - $s(1) } ]
    set size(2) [ expr { $e(2) - $s(2) } ]

    incr s(1) [ ::Yadt::Get_Current_Delta 1 ]
    incr s(2) [ ::Yadt::Get_Current_Delta 2 ]

    switch -- $type {
        "a" {
            set lefttext " " ;# insert
            set righttext "+"
            set idx 1
            set count [ expr { $size(2) + 1 } ]
            incr s(1)
            incr size(2)
        }
        "d" {
            set lefttext "-" ;# delete
            set righttext " "
            set idx 2
            set count [ expr { $size(1) + 1 } ]
            incr s(2)
            incr size(1)
        }
        "c" {
            set lefttext "!" ;# change
            set righttext "!" ;# change
            set idx [ expr { $size(1) < $size(2) ? 1 : 2 } ]
            set count [ expr { abs($size(1) - $size(2)) } ]
            incr size(1)
            incr size(2)
        }
    }

    set line [ expr $s(1) + $size($idx) ]

    for { set i 0 } { $i < $count } { incr i } {
        foreach t_wdg [ ::Yadt::Get_Diff_Wdg_List $idx ] {
            $t_wdg insert $line.0 "\n"
        }
    }

    incr size($idx) $count
    set e(1) [ expr { $s(1) + $size(1) - 1 } ]
    set e(2) [ expr { $s(2) + $size(2) - 1 } ]
    ::Yadt::Incr_Delta $idx $count

    for { set i $s(1) } { $i <= $e(1) } { incr i } {
        [ ::Yadt::Get_Diff_Wdg_List 1 info ] insert $i.0 $lefttext
        [ ::Yadt::Get_Diff_Wdg_List 2 info ] insert $i.0 $righttext
    }

    ::Yadt::Create_Scr_Diff $diff_id $s(1) $e(1) $type
    ::Yadt::Init_Scrinline_For_Diff_Id $diff_id

    set numlines [ ::CmnTools::MaxN \
                       [ expr { $e(1) - $s(1) + 1 } ] \
                       [ expr { $e(2) - $s(2) + 1 } ] ]
    for { set i 0 } { $i < $numlines } { incr i } {
        set l(1) [ expr $s(1) + $i ]
        set l(2) [ expr $s(2) + $i ]
        ::Yadt::Find_Ratcliff_Diff2 $diff_id $l(1) $l(2) \
            [ [ ::Yadt::Get_Diff_Wdg_List 1 text ] get $l(1).0 $l(1).end ] \
            [ [ ::Yadt::Get_Diff_Wdg_List 2 text ] get $l(2).0 $l(2).end ]
    }
}

#===============================================================================
