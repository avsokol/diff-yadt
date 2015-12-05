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

variable ::YadtDiff2::INFO_TEXT

array set ::YadtDiff2::INFO_TEXT {
    "a" {" " "+"}
    "d" {"-" " "}
    "c" {"!" "!"}
}

# Input data array for diff - get by Exec_Diff2 proc
variable ::YadtDiff2::DIFF2
# Format:
# DIFF2(diff) <list of diff output values>

# Example:
# DIFF2(diff) = "1c1 3c3 5d4 6a6 8c8 10c10 12,13c12"

#-------------------------------------------------------------------------------

#===============================================================================

proc ::YadtDiff2::Wipe {} {

    variable ::YadtDiff2::DIFF2

    set DIFF2(diff) ""
    ::YadtRange::Wipe
}

#===============================================================================

proc ::YadtDiff2::Get_Diff_Num {} {

    variable ::YadtDiff2::DIFF2

    return [ llength $DIFF2(diff) ]
}

#===============================================================================

proc ::YadtDiff2::Get_Diff2 { args } {

    variable ::YadtDiff2::DIFF2

    set is_exists [ ::CmnTools::Get_Arg -exists args -exists ]

    if { $is_exists } {
        return [ info exists DIFF2(diff) ]
    }

    return $DIFF2(diff)
}

#===============================================================================

proc ::YadtDiff2::Set_Diff2 { values } {

    variable ::YadtDiff2::DIFF2

    set DIFF2(diff) $values
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

proc ::YadtDiff2:::Get_Diff2_Info_Text { type } {

    variable ::YadtDiff2::INFO_TEXT

    if ![ info exists INFO_TEXT($type) ] {
            return -code error "Incorrect data <$type> from diff2 in [ lindex [ info level 0 ] 0 ]"
    }

    return $INFO_TEXT($type)
}

#===============================================================================

proc ::YadtDiff2::Add_Diff2_Info_Strings {} {

    set num_diff [ ::YadtDiff2::Get_Diff_Num ]

    for { set diff_id 1 } { $diff_id <= $num_diff } { incr diff_id } {
        ::YadtDiff2::Get_Diff2_Params $diff_id thisdiff s e type size change_text
        ::YadtRange::Add_Info_Strings_In_Range s size change_text
    }
}

#===============================================================================

proc ::YadtDiff2::Get_Diff2_Params { diff_id diff start end diff_type diff_size change_text } {

    upvar $diff thisdiff
    upvar $start s
    upvar $end e
    upvar $diff_size size
    upvar $diff_type type
    upvar $change_text text

    set diff_type [ ::Yadt::Get_Diff_Type ]

    lassign [ ::Yadt::Get_Pdiff_For_Diff_Id $diff_id ] thisdiff s(1) e(1) s(2) e(2) type

    set size(1) [ expr { $e(1) - $s(1) } ]
    set size(2) [ expr { $e(2) - $s(2) } ]

    switch -- $type {
        "a" {
            incr s(1)
            incr size(2)
        }
        "d" {
            incr s(2)
            incr size(1)
        }
        "c" {
            incr size(1)
            incr size(2)
        }
    }

    lassign [ ::YadtDiff2::Get_Diff2_Info_Text $type ] text(1) text(2)
}

#===============================================================================

proc ::YadtDiff2::Align_One_Diff2 { diff_id } {

    ::YadtDiff2::Get_Diff2_Params $diff_id thisdiff s e type size change_text

    set scr_start [ expr $s(1) + [ ::Yadt::Get_Current_Delta 1 ] ]

    set scr_diff_size [ ::YadtDiff2::Align_Diff2_Strings $diff_id s type size change_text ]

    ::Yadt::Init_Scrinline_For_Diff_Id $diff_id

    for { set i 1 } { $i <= [ ::Yadt::Get_Diff_Type ] } { incr i } {
        set t_wdg($i) [ ::Yadt::Get_Diff_Wdg_List $i text ]
    }

    for { set i 0 } { $i < $scr_diff_size } { incr i } {
        set l1 [ expr $scr_start + $i ]
        set l2 [ expr $scr_start + $i ]
        ::Yadt::Find_Ratcliff_Diff2 $diff_id $l1 $l2 \
            [ $t_wdg(1) get $l1.0 $l1.end ] \
            [ $t_wdg(2) get $l2.0 $l2.end ]
    }
}

#===============================================================================

proc ::YadtDiff2::Align_Diff2_Strings { diff_id start diff_type diff_size ch_text } {

    upvar $start s
    upvar $diff_size size
    upvar $diff_type type
    upvar $ch_text change_text

    if { $type == "c" } {
        ::YadtDiff2::Prepare_Lcs_Data_For_Diff_id lcsdata $diff_id s
    }

    switch -- $type {
        "a" {
            return [ ::YadtDiff2::Align_One_Empty_Diff2 $diff_id 1 s type size change_text ]
        }
        "d" {
            return [ ::YadtDiff2::Align_One_Empty_Diff2 $diff_id 2 s type size change_text ]
        }
        "c" {
            return [ ::YadtDiff2::Align_Non_Empty_Diff2 $diff_id lcsdata s type size change_text ]
        }
    }
}

#===============================================================================

proc ::YadtDiff2::Align_One_Empty_Diff2 { diff_id empty_id start diff_type diff_size ch_text } {

    upvar $start s
    upvar $diff_type type
    upvar $diff_size size
    upvar $ch_text change_text

    set diff_type [ ::Yadt::Get_Diff_Type ]

    set ranges {}

    for { set i 1 } { $i <= $diff_type } { incr i } {
        set full_shift($i) 0
        set scr_line($i) [ expr $s($i) + [ ::Yadt::Get_Current_Delta $i ] ]
    }

    set non_empty_id  [ ::YadtDiff2::Get_Other_Id $empty_id ]

    set shift($non_empty_id) 0
    set shift($empty_id) $size($non_empty_id)

    ::YadtRange::Move_Lines scr_line shift change_text
    for { set i 1 } { $i <= $diff_type } { incr i } {
        incr full_shift($i) $shift($i)
    }

    lassign [ ::YadtRange::Get_Border_Ranges s size full_shift ] r_start r_end
    lappend ranges $r_start $r_end

    for { set i 1 } { $i <= $diff_type } { incr i } {
        ::Yadt::Incr_Delta $i $full_shift($i)
    }

    ::YadtDiff2::Create_Screen_Ranges $ranges $diff_id size $r_start $r_end $type
    ::Yadt::Create_Scr_Diff $diff_id $r_start $r_end $type

    return [ expr $r_end - $r_start + 1 ]
}

#===============================================================================

proc ::YadtDiff2::Align_Non_Empty_Diff2 { diff_id lcs start diff_type diff_size ch_text } {

    upvar $lcs lcsdata
    upvar $start s
    upvar $diff_type type
    upvar $diff_size size
    upvar $ch_text change_text

    set diff_type [ ::Yadt::Get_Diff_Type ]

    set ranges {}

    for { set i 1 } { $i <= $diff_type } { incr i } {
        set full_shift($i) 0
        set current_delta($i) [ ::Yadt::Get_Current_Delta $i ]
    }

    foreach f_line(1) $lcsdata(12,1) {
        set idx(2) [ lsearch $lcsdata(12,1) $f_line(1) ]
        set f_line(2) [ lindex $lcsdata(12,2) $idx(2) ]

        set scr_line(1) [ expr $f_line(1) + $current_delta(1) + $full_shift(1) ]
        set scr_line(2) [ expr $f_line(2) + $current_delta(2) + $full_shift(2) ]

        set scr_line_max [ ::CmnTools::MaxN $scr_line(1) $scr_line(2) ]

        set shift(1) [ expr $scr_line_max - $scr_line(1) ]
        set shift(2) [ expr $scr_line_max - $scr_line(2) ]

        if ![ info exists prev_line(1) ] {
            set prev_line(1) $f_line(1)
            set prev_scr_line $scr_line(1)
        }
        if ![ info exists prev_line(2) ] {
            set prev_line(2) $f_line(2)
        }

        set sh(1) [ expr $f_line(1) - $prev_line(1) - 1 ]
        set sh(2) [ expr $f_line(2) - $prev_line(2) - 1 ]

        if { $sh(1) == $sh(2) && $sh(1) > 0 } {
            if { [ lindex $ranges end ] <= $prev_scr_line } {
                set i 1
                while { [ expr $prev_scr_line + $i ] <= [ expr $scr_line(1) - 1 ] } {
                    lappend ranges [ expr $prev_scr_line + $i ] [ expr $prev_scr_line + $i ]
                    incr i
                }
            }
        }

        set prev_line(1) $f_line(1)
        set prev_line(2) $f_line(2)
        set prev_scr_line $scr_line(1)

        set move 0
        if { $shift(1) != 0 } {
            set move 1
            lappend ranges $scr_line(1) [ expr $scr_line(1) + $shift(1) - 1 ]
        }
        if { $shift(2) != 0 } {
            set move 1
            lappend ranges $scr_line(2) [ expr $scr_line(2) + $shift(2) - 1 ]
        }

        if { $move } {
            ::YadtRange::Move_Lines scr_line shift change_text
        }
        incr full_shift(1) $shift(1)
        incr full_shift(2) $shift(2)
    }

    set scr_line(1) [ expr $s(1) + $current_delta(1) + $size(1) + $full_shift(1) ]
    set scr_line(2) [ expr $s(2) + $current_delta(2) + $size(2) + $full_shift(2) ]

    set max_shift [ ::CmnTools::MaxN \
                        [ expr $size(1) + $full_shift(1) ] \
                        [ expr $size(2) + $full_shift(2) ] ]

    set shift(1) [ expr $max_shift - $size(1) - $full_shift(1) ]
    set shift(2) [ expr $max_shift - $size(2) - $full_shift(2) ]

    set move 0
    if { $shift(1) > 0 || $shift(2) > 0 } {
        set move 1
    }

    set last_range_start [ ::CmnTools::MinN $scr_line(1) $scr_line(2) ]
    set last_range_end [ expr $last_range_start + abs($shift(2) - $shift(1)) - 1 ]

    if { $last_range_start <= $last_range_end } {
        lappend ranges $last_range_start $last_range_end
    }

    if { $move } {
        ::YadtRange::Move_Lines scr_line shift change_text
    }
    for { set i 1 } { $i <= $diff_type } { incr i } {
        incr full_shift($i) $shift($i)
    }

    lassign [ ::YadtRange::Get_Border_Ranges s size full_shift ] r_start r_end
    ::YadtRange::Append_Border_Ranges ranges $r_start $r_end

    for { set i 1 } { $i <= $diff_type } { incr i } {
        ::Yadt::Incr_Delta $i $full_shift($i)
    }

    ::YadtDiff2::Create_Screen_Ranges $ranges $diff_id size $r_start $r_end $type
    ::Yadt::Create_Scr_Diff $diff_id $r_start $r_end $type

    return [ expr $r_end - $r_start + 1 ]
}

#===============================================================================

proc ::YadtDiff2::Get_Other_Id { id } {

    return [ expr $id == 1 ? 2 : 1 ]
}

#===============================================================================

proc ::YadtDiff2::Prepare_Lcs_Data_For_Diff_id { lcs diff_id shift_up } {

    upvar $lcs lcsdata
    upvar $shift_up shift

    lassign [ ::YadtDiff2::Get_Bs_Lcs_For_Diff_Id $diff_id ] lcsdata(12)

    set lcsdata(12,1) [ ::YadtLcs::Convert_Lcs_Data_To_Line_Nums [ lindex $lcsdata(12) 0 ] $shift(1) ]
    set lcsdata(12,2) [ ::YadtLcs::Convert_Lcs_Data_To_Line_Nums [ lindex $lcsdata(12) 1 ] $shift(2) ]

    unset lcsdata(12)
}

#===============================================================================

proc ::YadtDiff2::Get_Bs_Lcs_For_Diff_Id { diff_id args } {

    set ignore_blanks [ ::CmnTools::Get_Arg -ignore_blanks args -default 1 ]

    for { set i 1 } { $i <= [ ::Yadt::Get_Diff_Type ] } { incr i } {
        lassign [ ::Yadt::Gather_File_Strings_By_Diff2_Id $diff_id $i ] str($i) str_bs($i)
    }

    if { $ignore_blanks } {
        set lcsdata [ ::struct::list::LlongestCommonSubsequence2 $str_bs(1) $str_bs(2) 1000 ]
    } else {
        set lcsdata [ ::struct::list::LlongestCommonSubsequence2 $str(1) $str(2) 1000 ]
    }

    return [ list $lcsdata ]
}

#===============================================================================

proc ::YadtDiff2::Add_One_Diff2 { diff_id } {

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

proc ::YadtDiff2::Create_Screen_Ranges { ranges diff_id diff_size start end type } {

    upvar $diff_size size

    set ranges_num [ ::YadtRange::Get_Ranges_Num ]

    if { [ llength $ranges ] == 2 && \
             [ lindex $ranges 0 ] == $start && \
             [ lindex $ranges 1 ] == $end && \
             $size(1) == $size(2) } {
        lassign [ ::Yadt::Gather_File_Strings_By_Diff2_Id $diff_id 1 ] s1 s1test
        lassign [ ::Yadt::Gather_File_Strings_By_Diff2_Id $diff_id 2 ] s2 s2test

        if { $s1test == $s2test } {
            incr ranges_num
            ::YadtRange::Set_Range $ranges_num $start $end $type
            ::YadtRange::Set_Diff_Id_For_Range $ranges_num $diff_id
            ::YadtRange::Append_Range_To_Diff_Id $diff_id $ranges_num
        } else {
            # Split ranges by 1 line
            for { set i $start } { $i <= $end } { incr i } {
                incr ranges_num
                ::YadtRange::Set_Range $ranges_num $i $i $type
                ::YadtRange::Set_Diff_Id_For_Range $ranges_num $diff_id
                ::YadtRange::Append_Range_To_Diff_Id $diff_id $ranges_num
            }
        }
    } else {
        # Get all ranges inside diff
        set scr_ranges [ ::YadtRange::Split_Region_By_Ranges $start $end $ranges ]
        foreach [ list r_start r_end ] $scr_ranges {
            incr ranges_num
            ::YadtRange::Set_Range $ranges_num $r_start $r_end $type
            ::YadtRange::Set_Diff_Id_For_Range $ranges_num $diff_id
            ::YadtRange::Append_Range_To_Diff_Id $diff_id $ranges_num
        }
    }
}

#===============================================================================

proc ::YadtDiff2::Diff_Cmd_Windows_Compatibility_Mode { action cmd_path { compatibility "~ WINXPSP3" } } {

    switch -- $action {
        -get {
            if [ catch { registry get "HKEY_CURRENT_USER\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\AppCompatFlags\\Layers" [ file nativename $cmd_path ] } value ] {
                set value ""
            }
            return $value
        }
        -set {
            if { $compatibility == "" } {
                ::YadtDiff2::Diff_Cmd_Windows_Compatibility_Mode -delete $cmd_path
                return
            }

            registry set "HKEY_CURRENT_USER\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\AppCompatFlags\\Layers" [ file nativename $cmd_path ] $compatibility
        }
        -delete {
            registry delete "HKEY_CURRENT_USER\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\AppCompatFlags\\Layers" "[ file nativename $cmd_path ]"
        }
        default {
            return -code error "Unsupported action <$action>"
        }
    }
}

#===============================================================================
