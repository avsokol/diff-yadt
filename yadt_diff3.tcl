################################################################################
#
#  yadt_diff3 - module for YaDT
#           provides procs for comparing 3 files
#
#
#
#------------------------------------------------------------------------------
#
#  Packages  required:
#  Packages  dependencies: YaDT
#
################################################################################

package provide YadtDiff3 1.0

#===============================================================================

namespace eval ::YadtDiff3 {

}

variable ::YadtDiff3::INFO_TEXT

array set ::YadtDiff3::INFO_TEXT {
    "ccc" {"!" "!" "!"}
    "cca" {"-" "-" " "}
    "cac" {"-" " " "-"}
    "acc" {" " "+" "+"}
    "caa" {"-" " " " "}
    "aca" {" " "+" " "}
    "aac" {" " " " "+"}
}

#===============================================================================

#-------------------------------------------------------------------------------

# As we do not use diff3 anymore, DIFF3 contains a result of merging results from
# above variables, but in the format of diff3 output
variable ::YadtDiff3::DIFF3

# DIFF3(<index>,which_file)   = <file_number>
# DIFF3(<index>,1,diff) <chunk_description>
# DIFF3(<index>,2,diff) <chunk_description>
# DIFF3(<index>,3,diff) <chunk_description>

# Where:
# <index> - index of chunk (group of continuous differences);
# 1,2,3   - file number;
# <file_number>  - number of modified file: may be 2, 3 or 0 if the both files (2 and 3) are modified;
# <chunk_description> - description of chunk in the following format:
#                       <line1>[,<line2>]<change_type>, where:
#                       <line1> - number of first modified line;
#                       <line2> - number of last modified line;
#                       <change_type> - modification type ('c' or 'a').

#-------------------------------------------------------------------------------
# Example of diff3 output/DIFF3 content:
# ====3
# 1:3c
# 2:3c
#   #  builder.tcl
# 3:3c
#   #  User management panel which allows add/edit/delete SYREN users
# ====3
# 1:5c
# 2:5c
#   #  Builder-related procedures for SYREN.
# 3:4a
# ====
# 1:262,263c
#           -local {
#   #            return [ eval exec -keepnewline $cmd $cmdargs ]
# 2:262,263c
#           -local {
#               return [ eval exec -keepnewline $cmd $cmdargs ]
# 3:772,774c
#       # find actually
#       set found -1
#       set i 0

# Result:
# DIFF3(1,which_file) = 3 - taken from ====3
# DIFF3(1,1,diff) = 3c - taken from 1:3c
# DIFF3(1,2,diff) = 3c - taken from 2:3c
# DIFF3(1,3,diff) = 3c - taken from 3:3c
# DIFF3(2,which_file) = 3 - taken from ====3
# DIFF3(2,1,diff) = 5c - taken from 1:5c
# DIFF3(2,2,diff) = 5c - taken from 2:5c
# DIFF3(2,3,diff) = 4a - taken from 3:4a
# DIFF3(3,which_file) = 0 - taken from ====
# DIFF3(3,1,diff) = 262,263c - taken from 1:262,263c
# DIFF3(3,2,diff) = 262,263c - taken from 2:262,263c
# DIFF3(3,3,diff) = 772,774c - taken from 3:772,774c

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
variable ::YadtDiff3::RANGES
variable ::YadtDiff3::RANGES2DIFF
variable ::YadtDiff3::DIFF2RANGES

#===============================================================================

proc ::YadtDiff3::Wipe {} {

    variable ::YadtDiff3::DIFF3
    variable ::YadtDiff3::RANGES
    variable ::YadtDiff3::RANGES2DIFF
    variable ::YadtDiff3::DIFF2RANGES

    array unset DIFF3
    array unset RANGES
    array unset RANGES2DIFF
    array unset DIFF2RANGES
}

#===============================================================================

proc ::YadtDiff3::Get_Diff_Num {} {

    variable ::YadtDiff3::DIFF3

    return [ llength [ array names DIFF3 *,which_file ] ]
}

#===============================================================================

proc ::YadtDiff3::Get_Which_File_For_Diff_Id { diff_id } {

    variable ::YadtDiff3::DIFF3

    if { $diff_id == 0 } {
        return 0
    }

    return $DIFF3($diff_id,which_file)
}

#===============================================================================

proc ::YadtDiff3::Find_Which_File_For_Diff_Id { diff_id } {

    lassign [ ::Yadt::Gather_File_Strings_By_Diff_Id $diff_id 1 lf1 ] str1 dummy
    lassign [ ::Yadt::Gather_File_Strings_By_Diff_Id $diff_id 2 lf2 ] str2 dummy
    lassign [ ::Yadt::Gather_File_Strings_By_Diff_Id $diff_id 3 lf3 ] str3 dummy

    if { $str1 == $str2 && $str1 == $str3 } {
        if { $lf1 == $lf2 && $lf1 == $lf3 } {
            return -code error "Couldn't find diffrence while it should be"
        }
        if { $lf1 == $lf2 } {
            return 3
        }
        if { $lf1 == $lf3 } {
            return 2
        }
        if { $lf2 == $lf3 } {
            return 1
        }
    } 

    if { $str1 == $str2 } {
        return 3
    }
    if { $str1 == $str3 } {
        return 2
    }
    if { $str2 == $str3 } {
        return 1
    }

    return 0
}

#===============================================================================

proc ::YadtDiff3::Set_Which_File_For_Diff_Id { diff_id value } {

    variable ::YadtDiff3::DIFF3

    set DIFF3($diff_id,which_file) $value
}

#===============================================================================

proc ::YadtDiff3::Get_Part_Diff3_For_Diff_Id { diff_id idx } {

    variable ::YadtDiff3::DIFF3

    return $DIFF3($diff_id,$idx,diff)
}

#===============================================================================

proc ::YadtDiff3::Set_Part_Diff3_For_Diff_Id { diff_id idx value } {

    variable ::YadtDiff3::DIFF3

    set DIFF3($diff_id,$idx,diff) $value
}

#===============================================================================

proc ::YadtDiff3::Get_Other_Ids  { id } {

    set ids_lst [ list 1 2 3 ]
    set ind [ lsearch -exact $ids_lst $id ]
    if { $ind < 0 } {
        return -code error "Unsupported id <$id>"
    }

    return [ lreplace $ids_lst $ind $ind ]
}

#===============================================================================

proc ::YadtDiff3::Analyze_Diff3 { diff_id file_id line } {

    if ![ regexp {^([0-9]*)(,([0-9]*))?(a|c)$} $line matchvar s1 x e1 op ] {
        return -code error "Cannot parse diff3 output:\n<$line>"
    }

    if ![ string length $e1 ] {
        set e1 $s1
    }

    if { $s1 > $e1 } {
        return -code error "Incorrect data from diff3:\n<$line>"
    }

    return [ list $line $s1 $e1 $op ]
}

#===============================================================================

proc ::YadtDiff3::Get_Diff3_Params { diff_id diff start end diff_type diff_size change_text } {

    upvar $diff thisdiff
    upvar $start s
    upvar $end e
    upvar $diff_size size
    upvar $diff_type type
    upvar $change_text text

    set diff_type [ ::Yadt::Get_Diff_Type ]

    foreach var [ list thisdiff s e size type text ] {
        array unset $var
    }

    for { set i 1 } { $i <= $diff_type } { incr i } {
        lassign [::Yadt::Get_Pdiff_For_Diff_Id $diff_id -file_id $i ] \
            thisdiff($i) s($i) e($i) type($i)
        set size($i) [ expr $e($i) - $s($i) ]

        switch -- $type($i) {
            "a" {
                incr s($i)
            }
            "c" {
                incr size($i)
            }
        }
    }

    if ![ ::YadtDiff3::Get_Which_File_For_Diff_Id $diff_id ] {
        for { set i 1 } { $i <= $diff_type } { incr i } {
            set text($i) "?"
        }
    } else {
        lassign [ ::YadtDiff3::Get_Diff3_Info_Text $type(1) $type(2) $type(3) ] text(1) text(2) text(3)
    }
}

#===============================================================================

proc ::YadtDiff3::Get_Diff3_Info_Text { type1 type2 type3 } {

    variable ::YadtDiff3::INFO_TEXT

    if ![ info exists INFO_TEXT($type1$type2$type3) ] {
            return -code error "Incorrect data <$type1$type2$type3> from diff3 in [ lindex [ info level 0 ] 0 ]"
    }

    return $INFO_TEXT($type1$type2$type3)
}

#===============================================================================

proc ::YadtDiff3::Get_Bs_Lcs_For_Diff_Id { diff_id args } {

    set ignore_blanks [ ::CmnTools::Get_Arg -ignore_blanks args -default 1 ]

    for { set i 1 } { $i <= [ ::Yadt::Get_Diff_Type ] } { incr i } {
        lassign [ ::Yadt::Gather_File_Strings_By_Diff_Id $diff_id $i ] str($i) str_bs($i)
    }

    if { $ignore_blanks } {
        set lcsdata(12) [ ::struct::list::LlongestCommonSubsequence2 $str_bs(1) $str_bs(2) 1000 ]
        set lcsdata(13) [ ::struct::list::LlongestCommonSubsequence2 $str_bs(1) $str_bs(3) 1000 ]
        set lcsdata(23) [ ::struct::list::LlongestCommonSubsequence2 $str_bs(2) $str_bs(3) 1000 ]
    } else {
        set lcsdata(12) [ ::struct::list::LlongestCommonSubsequence2 $str(1) $str(2) 1000 ]
        set lcsdata(13) [ ::struct::list::LlongestCommonSubsequence2 $str(1) $str(3) 1000 ]
        set lcsdata(23) [ ::struct::list::LlongestCommonSubsequence2 $str(2) $str(3) 1000 ]
    }

    return [ list $lcsdata(12) $lcsdata(13) $lcsdata(23) ]
}

#===============================================================================

proc ::YadtDiff3::Prepare_Lcs_Data_For_Diff_id { lcs diff_id shift_up } {

    upvar $lcs lcsdata
    upvar $shift_up shift

    lassign [ ::YadtDiff3::Get_Bs_Lcs_For_Diff_Id $diff_id ] lcsdata(12) lcsdata(13) lcsdata(23)

    set lcsdata(12,1) [ ::YadtLcs::Convert_Lcs_Data_To_Line_Nums [ lindex $lcsdata(12) 0 ] $shift(1) ]
    set lcsdata(12,2) [ ::YadtLcs::Convert_Lcs_Data_To_Line_Nums [ lindex $lcsdata(12) 1 ] $shift(2) ]

    set lcsdata(13,1) [ ::YadtLcs::Convert_Lcs_Data_To_Line_Nums [ lindex $lcsdata(13) 0 ] $shift(1) ]
    set lcsdata(13,3) [ ::YadtLcs::Convert_Lcs_Data_To_Line_Nums [ lindex $lcsdata(13) 1 ] $shift(3) ]

    set lcsdata(23,2) [ ::YadtLcs::Convert_Lcs_Data_To_Line_Nums [ lindex $lcsdata(23) 0 ] $shift(2) ]
    set lcsdata(23,3) [ ::YadtLcs::Convert_Lcs_Data_To_Line_Nums [ lindex $lcsdata(23) 1 ] $shift(3) ]

    unset lcsdata(12)
    unset lcsdata(13)
    unset lcsdata(23)
}

#===============================================================================

proc ::YadtDiff3::Align_Diff3_Strings { diff_id start diff_type diff_size ch_text } {

    upvar $start s
    upvar $diff_size size
    upvar $diff_type type
    upvar $ch_text change_text

    if { [ regexp -all -- "a" $type(1)$type(2)$type(3) ] < 2 } {
        ::YadtDiff3::Prepare_Lcs_Data_For_Diff_id lcsdata $diff_id s
    }

    switch -- $type(1)$type(2)$type(3) {
        "aac" {
            return [ ::YadtDiff3::Align_Two_Third_Empty_Diff3 $diff_id 3 s type size change_text ]
        }
        "aca" {
            return [ ::YadtDiff3::Align_Two_Third_Empty_Diff3 $diff_id 2 s type size change_text ]
        }
        "caa" {
            return [ ::YadtDiff3::Align_Two_Third_Empty_Diff3 $diff_id 1 s type size change_text ]
        }
        "acc" {
            return [ ::YadtDiff3::Align_One_Third_Empty_Diff3 $diff_id 1 lcsdata s type size change_text -align_inside [ ::Yadt::Get_Yadt_Option align_acc ] ]
        }
        "cac" {
            return [ ::YadtDiff3::Align_One_Third_Empty_Diff3 $diff_id 2 lcsdata s type size change_text ]
        }
        "cca" {
            return [ ::YadtDiff3::Align_One_Third_Empty_Diff3 $diff_id 3 lcsdata s type size change_text ]
        }
        "ccc" {
            return [ ::YadtDiff3::Align_Conflict $diff_id lcsdata s type size change_text ]
        }
        "aaa" {
            return -code error "Unexpected diff3 type <$type(1)$type(2)$type(3)>"
        }
    }
}

#===============================================================================

proc ::YadtDiff3::Align_One_Diff3 { diff_id } {

    ::YadtDiff3::Get_Diff3_Params $diff_id thisdiff s e type size change_text

    set scr_start [ expr $s(1) + [ ::Yadt::Get_Current_Delta 1 ] ]

    set scr_diff_size [ ::YadtDiff3::Align_Diff3_Strings $diff_id s type size change_text ]

    ::Yadt::Init_Scrinline_For_Diff_Id $diff_id

    for { set i 1 } { $i <= [ ::Yadt::Get_Diff_Type ] } { incr i } {
        set t_wdg($i) [ ::Yadt::Get_Diff_Wdg_List $i text ]
    }

    for { set i 0 } { $i < $scr_diff_size } { incr i } {
        set l1 [ expr $scr_start + $i ]
        set l2 [ expr $scr_start + $i ]
        set l3 [ expr $scr_start + $i ]
        ::Yadt::Find_Ratcliff_Diff3 $diff_id $l1 $l2 $l3 \
            [ $t_wdg(1) get $l1.0 $l1.end ] \
            [ $t_wdg(2) get $l2.0 $l2.end ] \
            [ $t_wdg(3) get $l3.0 $l3.end ]
    }
}

#===============================================================================

proc ::YadtDiff3::Get_Ranges_Num {} {

    variable ::YadtDiff3::RANGES

    return [ llength [ array names RANGES ] ]
}

#===============================================================================

proc ::YadtDiff3::Get_Range { idx args } {

    variable ::YadtDiff3::RANGES

    set is_exists [ ::CmnTools::Get_Arg -exists args -exists ]

    if { $is_exists } {
        return [ info exists RANGES($idx) ]
    }

    return $RANGES($idx)
}

#===============================================================================

proc ::YadtDiff3::Set_Range { idx start end type } {

    variable ::YadtDiff3::RANGES

    set RANGES($idx) [ list $start $end $type ]
}

#===============================================================================

proc ::YadtDiff3::Append_Border_Ranges { up_ranges start end } {

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

proc ::YadtDiff3::Combine_Ranges { up_ranges diff_id } {

    upvar $up_ranges ranges

    set ranges [ ::YadtDiff3::Sort_Ranges $ranges ]

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

proc ::YadtDiff3::Sort_Ranges { ranges } {

    set tmp_ranges {}

    foreach { s e } $ranges {
        lappend tmp_ranges [ list $s $e ]
    }

    set ranges [ join [ lsort -unique -integer -increasing -index 0 $tmp_ranges ] ]

    return $ranges
}

#===============================================================================

proc ::YadtDiff3::Remove_Range { up_ranges start end } {

    upvar $up_ranges ranges

    set new_ranges {}

    foreach { s e } $ranges {
        if { $s == $start && $e == $end } continue
        lappend new_ranges $s $e
    }

    set ranges $new_ranges
}

#===============================================================================

proc ::YadtDiff3::Split_Region_By_Ranges { start end ranges } {

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

proc ::YadtDiff3::Get_Border_Ranges { start diff_size shift } {

    upvar $start s
    upvar $diff_size size
    upvar $shift full_shift

    set shifted_size_max [ ::CmnTools::MaxN \
                               [ expr $size(1) + $full_shift(1) ] \
                               [ expr $size(2) + $full_shift(2) ] \
                               [ expr $size(3) + $full_shift(3) ] ]

    set r_start [ expr $s(1) + [ ::Yadt::Get_Current_Delta 1 ] ]
    set r_end   [ expr $r_start + $shifted_size_max - 1 ]
    return [ list $r_start $r_end ]
}

#===============================================================================

proc ::YadtDiff3::Create_Screen_Ranges { ranges diff_id start end type } {

    set ranges_num [ ::YadtDiff3::Get_Ranges_Num ]

    if { [ llength $ranges ] == 2 && \
             [ lindex $ranges 0 ] == $start && \
             [ lindex $ranges 1 ] == $end && \
             ![ ::YadtDiff3::Get_Which_File_For_Diff_Id $diff_id ] } {
        # Split ranges by 1 line
        for { set i $start } { $i <= $end } { incr i } {
            incr ranges_num
            ::YadtDiff3::Set_Range $ranges_num $i $i $type
            ::YadtDiff3::Set_Diff_Id_For_Range $ranges_num $diff_id
            ::YadtDiff3::Append_Range_To_Diff_Id $diff_id $ranges_num
        }
    } else {
        # Get all ranges inside diff
        set scr_ranges [ ::YadtDiff3::Split_Region_By_Ranges $start $end $ranges ]
        foreach [ list r_start r_end ] $scr_ranges {
            incr ranges_num
            ::YadtDiff3::Set_Range $ranges_num $r_start $r_end $type
            ::YadtDiff3::Set_Diff_Id_For_Range $ranges_num $diff_id
            ::YadtDiff3::Append_Range_To_Diff_Id $diff_id $ranges_num
        }
    }
}

#===============================================================================

proc ::YadtDiff3::Get_Diff_Id_For_Range { range_id } {

    variable ::YadtDiff3::RANGES2DIFF

    if { $range_id == 0 } {
        return 0
    }

    return $RANGES2DIFF($range_id)
}

#===============================================================================

proc ::YadtDiff3::Set_Diff_Id_For_Range { range_id diff_id } {

    variable ::YadtDiff3::RANGES2DIFF

    set RANGES2DIFF($range_id) $diff_id
}

#===============================================================================

proc ::YadtDiff3::Append_Range_To_Diff_Id { diff_id range } {

    variable ::YadtDiff3::DIFF2RANGES

    lappend DIFF2RANGES($diff_id) $range
}

#===============================================================================

proc ::YadtDiff3::Get_Ranges_For_Diff_Id { diff_id } {

    variable ::YadtDiff3::DIFF2RANGES

    if { $diff_id == 0 } {
        return {}
    }

    return $DIFF2RANGES($diff_id)
}

#===============================================================================

proc ::YadtDiff3::Get_Top_Range_For_Diff_Id { diff_id } {

    variable ::YadtDiff3::DIFF2RANGES

    if { $diff_id == 0 } {
        return 0
    }

    return [ lindex $DIFF2RANGES($diff_id) 0 ]
}

#===============================================================================

proc ::YadtDiff3::Add_Info_Strings_In_Range { start diff_size ch_text } {

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

proc ::YadtDiff3::Add_Diff3_Info_Strings {} {

    set num_diff [ ::YadtDiff3::Get_Diff_Num ]

    for { set diff_id 1 } { $diff_id <= $num_diff } { incr diff_id } {
        ::YadtDiff3::Get_Diff3_Params $diff_id thisdiff s e type size change_text
        ::YadtDiff3::Add_Info_Strings_In_Range s size change_text
    }
}

#===============================================================================

proc ::YadtDiff3::Move_Lines { lines shift_up ch_text } {

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

    ::YadtDiff3::Add_Info_Strings_In_Range ln shift change_text
}

#===============================================================================

proc ::YadtDiff3::Append_Final_Lcs_Lines { nums_up } {

    upvar $nums_up nums

    set diff_type [ ::Yadt::Get_Diff_Type ]

    set test_nums {}

    for { set i 1 } { $i <= $diff_type } { incr i } {
        lappend test_nums $nums($i)
    }

    set max_num [ ::CmnTools::MaxN {*}$test_nums ]

    for { set i 1 } { $i <= $diff_type } { incr i } {
        for { set j $nums($i) } { $j < $max_num } { incr j } {
            foreach t_wdg [ ::Yadt::Get_Diff_Wdg_List $i ] {
                $t_wdg insert [ expr $j + 1 ].0 "\n"
            }
        }
    }
}

#===============================================================================

proc ::YadtDiff3::Align_Two_Third_Empty_Diff3 { diff_id id1 start diff_type diff_size ch_text } {

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

    lassign [ ::YadtDiff3::Get_Other_Ids $id1 ] id2 id3

    set shift($id1) 0
    set shift($id2) $size($id1)
    set shift($id3) $size($id1)

    ::YadtDiff3::Move_Lines scr_line shift change_text
    for { set i 1 } { $i <= $diff_type } { incr i } {
        incr full_shift($i) $shift($i)
    }

    lassign [ ::YadtDiff3::Get_Border_Ranges s size full_shift ] r_start r_end
    lappend ranges $r_start $r_end

    for { set i 1 } { $i <= $diff_type } { incr i } {
        ::Yadt::Incr_Delta $i $full_shift($i)
    }

    ::YadtDiff3::Create_Screen_Ranges $ranges $diff_id $r_start $r_end $type(1)$type(2)$type(3)
    ::Yadt::Create_Scr_Diff $diff_id $r_start $r_end $type(1)$type(2)$type(3)

    return [ expr $r_end - $r_start + 1 ]
}

#===============================================================================

proc ::YadtDiff3::Align_One_Third_Empty_Diff3 { diff_id id3 lcs start diff_type diff_size ch_text args } {

    upvar $lcs lcsdata
    upvar $start s
    upvar $diff_type type
    upvar $diff_size size
    upvar $ch_text change_text

    set align_inside [ ::CmnTools::Get_Arg -align_inside args -default 1 ]

    set diff_type [ ::Yadt::Get_Diff_Type ]

    set ranges {}

    for { set i 1 } { $i <= $diff_type } { incr i } {
        set full_shift($i) 0
        set current_delta($i) [ ::Yadt::Get_Current_Delta $i ]
    }

    lassign [ ::YadtDiff3::Get_Other_Ids $id3 ] id1 id2

    if { $align_inside } {

        foreach f_line($id1) $lcsdata($id1$id2,$id1) {
            set idx($id2) [ lsearch $lcsdata($id1$id2,$id1) $f_line($id1) ]
            set f_line($id2) [ lindex $lcsdata($id1$id2,$id2) $idx($id2) ]

            set scr_line($id1) [ expr $f_line($id1) + $current_delta($id1) + $full_shift($id1) ]
            set scr_line($id2) [ expr $f_line($id2) + $current_delta($id2) + $full_shift($id2) ]
            set scr_line($id3) 0

            set scr_line_max [ ::CmnTools::MaxN $scr_line($id1) $scr_line($id2) ]

            set shift($id1) [ expr $scr_line_max - $scr_line($id1) ]
            set shift($id2) [ expr $scr_line_max - $scr_line($id2) ]
            set shift($id3) 0

            if { $scr_line($id1) == $scr_line($id2) } {
                if ![ info exists prev_line($id1) ] {
                    set prev_line($id1) $f_line($id1)
                    set prev_scr_line $scr_line($id1)
                }
                if ![ info exists prev_line($id2) ] {
                    set prev_line($id2) $f_line($id2)
                }

                set sh($id1) [ expr $f_line($id1) - $prev_line($id1) - 1 ]
                set sh($id2) [ expr $f_line($id2) - $prev_line($id2) - 1 ]

                if { $sh($id1) == $sh($id2) && $sh($id1) > 0 } {
                    lappend ranges [ expr $prev_scr_line + 1 ] [ expr $scr_line($id1) - 1 ]
                }

                set prev_line($id1) $f_line($id1)
                set prev_line($id2) $f_line($id2)
                set prev_scr_line $scr_line($id1)

                continue
            }

            if { $shift($id1) != 0 } {
                lappend ranges $scr_line($id1) [ expr $scr_line($id1) + $shift($id1) - 1 ]
            }
            if { $shift($id2) != 0 } {
                lappend ranges $scr_line($id2) [ expr $scr_line($id2) + $shift($id2) - 1 ]
            }

            ::YadtDiff3::Move_Lines scr_line shift change_text
            incr full_shift($id1) $shift($id1)
            incr full_shift($id2) $shift($id2)
        }
    }

    set scr_line($id1) [ expr $s($id1) + $current_delta($id1) + $size($id1) + $full_shift($id1) ]
    set scr_line($id2) [ expr $s($id2) + $current_delta($id2) + $size($id2) + $full_shift($id2) ]
    set scr_line($id3) [ expr $s($id3) + $current_delta($id3) ]

    set max_shift [ ::CmnTools::MaxN \
                        [ expr $size($id1) + $full_shift($id1) ] \
                        [ expr $size($id2) + $full_shift($id2) ] ]

    set shift($id1) [ expr $max_shift - $size($id1) - $full_shift($id1) ]
    set shift($id2) [ expr $max_shift - $size($id2) - $full_shift($id2) ]
    set shift($id3) $max_shift

    ::YadtDiff3::Move_Lines scr_line shift change_text
    for { set i 1 } { $i <= $diff_type } { incr i } {
        incr full_shift($i) $shift($i)
    }

    lassign [ ::YadtDiff3::Get_Border_Ranges s size full_shift ] r_start r_end
    ::YadtDiff3::Append_Border_Ranges ranges $r_start $r_end

    for { set i 1 } { $i <= $diff_type } { incr i } {
        ::Yadt::Incr_Delta $i $full_shift($i)
    }

    ::YadtDiff3::Create_Screen_Ranges $ranges $diff_id $r_start $r_end $type(1)$type(2)$type(3)
    ::Yadt::Create_Scr_Diff $diff_id $r_start $r_end $type(1)$type(2)$type(3)

    return [ expr $r_end - $r_start + 1 ]
}

#===============================================================================

proc ::YadtDiff3::Align_Conflict { diff_id lcs start diff_type diff_size ch_text } {

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
        set max_line($i) 0
    }

    set all_lines [ lsort -integer -unique [ concat $lcsdata(12,1) $lcsdata(12,2) \
                                                 $lcsdata(13,1) $lcsdata(13,3) \
                                                 $lcsdata(23,2) $lcsdata(23,3) ] ]
    foreach line $all_lines {

        for { set i 1 } { $i <= $diff_type } { incr i } {
            set f_line($i) 0
            set scr_line($i) 0
            set shift($i) 0

            if ![ info exists prev_line($i) ] {
                set prev_line($i) $f_line($i)
            }
            if ![ info exists prev_scr_line($i) ] {
                set prev_scr_line($i) $scr_line($i)
            }
        }

        set res [ ::YadtLcs::Find_Lcs_Corresponding_Lines lcsdata f_line $line ]

        for { set i 1 } { $i <= $diff_type } { incr i } {
            if { $f_line($i) == 0 } continue
            if { $max_line($i) >= $f_line($i) } {
                set res 0
                break
            }
        }

        if { $res } {
            for { set i 1 } { $i <= $diff_type } { incr i } {
                if { $f_line($i) != 0 } {
                    set scr_line($i) [ expr $f_line($i) + $current_delta($i) + $full_shift($i) ]
                }
            }

            set move 0
            set scr_line_max [ ::CmnTools::MaxN $scr_line(1) $scr_line(2) $scr_line(3) ]
            for { set i 1 } { $i <= $diff_type } { incr i } {
                if { $scr_line($i) != 0 } {
                    set shift($i) [ expr $scr_line_max - $scr_line($i) ]
                    if { $shift($i) > 0 } {
                        set move 1
                    }                    
                }
            }

            for { set i 1 } { $i <= $diff_type } { incr i } {
                incr full_shift($i) $shift($i)
            }

            if { $move } {
                for { set i 1 } { $i <= $diff_type } { incr i } {
                    if { $f_line($i) == 0 } continue
                    set max_line($i) $f_line($i)
                }
            }

            if { $move } {
                ::YadtDiff3::Move_Lines scr_line shift change_text
            }

            for { set i 1 } { $i <= $diff_type } { incr i } {
                set sh($i) 0
                if { $prev_line($i) != 0 } {
                    set sh($i) [ expr $f_line($i) - $prev_line($i) - 1 ]
                }

                if { $sh($i) > 0 } {
                    lappend ranges [ expr $prev_scr_line($i) + 1 ] [ expr $scr_line($i) - 1 ]
                }

                if { $f_line($i) != 0 } {
                    set prev_line($i) $f_line($i)
                }
                if { $scr_line($i) != 0 } {
                    set prev_scr_line($i) $scr_line($i)
                }

                if { $shift($i) > 0 } {
                    lappend ranges $scr_line($i) [ expr $scr_line($i) + $shift($i) - 1 ]
                }
            }
        }
    }

    set max_args {}
    for { set i 1 } { $i <= $diff_type } { incr i } {
        set scr_line($i) [ expr $s($i) + $current_delta($i) + $size($i) + $full_shift($i) ]
        set shifted_size($i) [ expr $size($i) + $full_shift($i) ]
        lappend max_args $shifted_size($i)
    }

    set shifted_size_max [ ::CmnTools::MaxN {*}$max_args ]

    set move 0
    for { set i 1 } { $i <= $diff_type } { incr i } {
        set shift($i) [ expr $shifted_size_max - $shifted_size($i) ]
        if { $shift($i) > 0 } {
            set move 1
            lappend ranges $scr_line($i) [ expr $scr_line($i) + $shift($i) - 1 ]
        }
    }

    if { $move } {
        ::YadtDiff3::Move_Lines scr_line shift change_text
    }

    if [ llength $ranges ] {
        ::YadtDiff3::Combine_Ranges ranges $diff_id
    }


    for { set i 1 } { $i <= $diff_type } { incr i } {
        incr full_shift($i) $shift($i)
    }

    lassign [ ::YadtDiff3::Get_Border_Ranges s size full_shift ] r_start r_end
    ::YadtDiff3::Append_Border_Ranges ranges $r_start $r_end

    for { set i 1 } { $i <= $diff_type } { incr i } {
        ::Yadt::Incr_Delta $i $full_shift($i)
    }

    ::YadtDiff3::Create_Screen_Ranges $ranges $diff_id $r_start $r_end $type(1)$type(2)$type(3)
    ::Yadt::Create_Scr_Diff $diff_id $r_start $r_end $type(1)$type(2)$type(3)

    return [ expr $r_end - $r_start + 1 ]
}

#===============================================================================

proc ::YadtDiff3::Create_Combo_Values_Based_On_Ranges {} {

    set combo_values {}

    set ranges_num [ ::YadtDiff3::Get_Ranges_Num ]

    for { set i 1 } { $i <= $ranges_num } { incr i } {

        set combo_value {}

        lassign [ ::YadtDiff3::Get_Range $i ] r_start r_end type

        for { set j 1 } { $j <= [ ::Yadt::Get_Diff_Type ] } { incr j } {
            set len($j) [ string length \
                              [ string trim \
                                    [ [ ::Yadt::Get_Diff_Wdg_List $j num ] \
                                          get $r_start.0 $r_end.end ] ] ]

            set value ""

            if { $len($j) } {
                set start [ string trim [ [ ::Yadt::Get_Diff_Wdg_List $j num ] get $r_start.0 $r_start.end ] ]
                set end [ string trim [ [ ::Yadt::Get_Diff_Wdg_List $j num ] get $r_end.0 $r_end.end ] ]

                append value $start
                if { $end > $start } {
                    append value ",$end"
                }
                append value "c"
            } else {
                set k $r_start
                set num 0
                while { $k > 0 } {
                    set line [ string trim [ [ ::Yadt::Get_Diff_Wdg_List $j num ] get $k.0 $k.end ] ]
                    if [ string length $line ] {
                        set num $line
                        break
                    }
                    incr k -1
                }
                append value $num
                append value "a"
            }

            lappend combo_value $value
        }

        lappend combo_values [ format "%-6d: %s" $i [ join $combo_value ": " ] ]
    }

    return $combo_values
}

#===============================================================================
