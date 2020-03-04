################################################################################
#
#  yadt_cvs - module for YaDT
#           provides procs for working with cvs
#
#
#
#------------------------------------------------------------------------------
#
#  Packages  required:
#  Packages  dependencies: YaDT, YadtDiff3
#
################################################################################

package provide YadtCvs 1.0

#===============================================================================

namespace eval ::YadtCvs {

}

#===============================================================================

proc ::YadtCvs::VCS_Detected_In_Dir { dir vcs_pattern } {

    variable ::Yadt::OPTIONS

    set abs_dir [ file nativename [ file normalize $dir ] ]
    set dir $abs_dir
    while { 1 } {
        if { $dir == "/" || $dir in [ file volumes ] } {
            break
        }
        set git_dir [ file join $dir ".$vcs_pattern" ]
        if { [ file exists $git_dir ] && [ file isdirectory $git_dir ] } {
            set OPTIONS(vcs) $vcs_pattern
            set OPTIONS(${vcs_pattern}_abs_dir) $dir
            return 1
        }
        set dir [ file dirname $dir ]
    }

    return 0
}

#===============================================================================

proc ::YadtCvs::Detect_VCS { dir } {

    variable ::Yadt::OPTIONS

    # check for CVS
    set cvs_dir [ file join $dir CVS ]
    if { [ file exists $cvs_dir ] && [ file isdirectory $cvs_dir ] } {
        set OPTIONS(vcs) "cvs"
        return
    }

    # check for cvs.exe
    set cvs_dir [ file join $dir .cvs ]
    if { [ file exists $cvs_dir ] && [ file isdirectory $cvs_dir ] } {
        set OPTIONS(vcs) "cvs.exe"
        return
    }

    # check for GIT
    if [ ::YadtCvs::VCS_Detected_In_Dir $dir "git" ] {
        return
    }

    # check for Mercurial
    if [ ::YadtCvs::VCS_Detected_In_Dir $dir "hg" ] {
        return
    }
}

#===============================================================================

proc ::YadtCvs::Save_CVS_Like_Merge_File {} {

    set save_file [ ::Yadt::Request_File_Name 3 ]

    if { [ string trim $save_file ] == "" } return

    set file_ancestor [ ::Yadt::Get_Diff_File_Label 1 ]
    if [ regexp {^.*\(CVS r(.*)\)$} $file_ancestor dummy revision ] {
        set file_ancestor $revision
    }
    set file1 [ ::Yadt::Get_Diff_File_Label 2 ]
    if [ regexp {^.*\(CVS r(.*)\)$} $file1 dummy revision ] {
        set file1 $revision
    }
    set file2 [ ::Yadt::Get_Diff_File_Label 3 ]

    set start_line 1

    set num_diff [ ::YadtDiff3::Get_Diff_Num ]

    set fd [ open $save_file w ]

    for { set i 1 } { $i <= $num_diff } { incr i } {

        # Start diff line
        lassign [ ::Yadt::Get_Diff_Scr_Params $i ] tmp_start tmp_end dt

        switch -- [ ::YadtDiff3::Get_Which_File_For_Diff_Id $i ] {
            0 {
                # Left content
                set add_content "<<<<<<< $file2"

                lassign [ ::Yadt::Get_Pdiff_For_Diff_Id $i -file_id 3 ] \
                    thisdiff s(3) e(3) type(3)
                set add_lines_num [ expr { $e(3) - $s(3) } ]
                if { $type(3) != "a" } {
                    incr add_lines_num
                }

                set content [ join [ lindex [ ::Yadt::Gather_File_Strings_By_Diff3_Id $i 3 ] 0 ] \n ]
                if { $content != "" } {
                    append add_content "\n$content"
                }

                # Right content
                append add_content "\n======= $file_ancestor"

                lassign [ ::Yadt::Get_Pdiff_For_Diff_Id $i -file_id 2 ] \
                    thisdiff s(2) e(2) type(2)
                set add_lines_num [ expr { $e(2) - $s(2) } ]
                if { $type(2) != "a" } {
                    incr add_lines_num
                }

                set content [ join [ lindex [ ::Yadt::Gather_File_Strings_By_Diff3_Id $i 2 ] 0 ] \n ]
                if { $content != "" } {
                    append add_content "\n$content"
                }

                append add_content "\n>>>>>>> $file1"
            }
            2 {
                # LINES num to add
                lassign [ ::Yadt::Get_Pdiff_For_Diff_Id $i -file_id 2 ] \
                    thisdiff s(2) e(2) type(2)
                set add_lines_num [ expr { $e(2) - $s(2) } ]
                if { $type(2) != "a" } {
                    incr add_lines_num
                }

                set add_content [ join [ lindex [ ::Yadt::Gather_File_Strings_By_Diff3_Id $i 2 ] 0 ] \n ]
            }
            1 -
            3 {
                # LINES num to add
                lassign [ ::Yadt::Get_Pdiff_For_Diff_Id $i -file_id 3 ] \
                    thisdiff s(3) e(3) type(3)
                set add_lines_num [ expr { $e(3) - $s(3) } ]
                if { $type(3) != "a" } {
                    incr add_lines_num
                }

                set add_content [ join [ lindex [ ::Yadt::Gather_File_Strings_By_Diff3_Id $i 3 ] 0 ] \n ]
            }
        }

        # puts content before diff
        if { $start_line < $tmp_start } {
            set content [ [ ::Yadt::Get_Diff_Wdg_List 1 text ] get $start_line.0 ${tmp_start}.0-1char ]
            puts $fd $content
        }

        # puts diff/conflict content
        if { $add_content != "" } {
            puts $fd $add_content
        }

        set start_line [ expr { $tmp_end + 1 } ]
    }

    # puts content after the last diff
    set content [ [ ::Yadt::Get_Diff_Wdg_List 1 text ] get $start_line.0 end-1lines ]
    puts -nonewline $fd $content

    close $fd
}

#===============================================================================

proc ::YadtCvs::Ignore_No_CVS_Tag_Error { cvs_out args } {

    upvar $cvs_out out

    set code [ ::CmnTools::Get_Arg -code args -default "" ]
    if { $code != "" } {
        upvar $code exitcode
    }

    # This modification is made to unify behavior
    # when cvs diff/checkout for -r <revision> and for -r <tag>
    # as: when we do not have a revision, cvs does not raise an error
    # but when we do not have a tag, cvs raises an error
    if [ regsub {^cvs \[checkout|diff aborted\]: no such tag.*$} $out "" out ] {
        set exitcode 42
    }
}

#===============================================================================

proc ::YadtCvs::Get_Work_Rev_From_Entries { file } {

    # Retuns:
    # revision value from CVS/Entries file;
    # -1 - file CVS/Entries is absent;
    # -2 - the revision information is not found in CVS/Entries.

    set filename [ file tail $file ]
    set dirname [ file dirname $file ]

    set entries_file [ file join $dirname CVS Entries ]

    if ![ file exists $entries_file ] {
        return -1
    }

    set data [ ::Yadt::Read_File $entries_file ]

    foreach line [ split $data \n ] {
        if [ regexp "\/$filename\/(\[0-9.\]+)\/" $line dummy rev ] {
            return $rev
        }
    }

    return -2
}

#===============================================================================

proc ::YadtCvs::Get_Work_Rev_From_CVS { filename cvs_cmd } {

    set cvsroot [ ::YadtCvs::Determine_CVS_Root_From_File $filename ]

    set cvscmd [ list $cvs_cmd -d $cvsroot status $filename ]

    set result [ ::Yadt::Run_Cmd_As_Pipe $cvscmd ]

    lassign $result stdout stderr exitcode

    if { $exitcode != 0 } {
        return -code error "Error while executing <$cvscmd>:\n$stderr\n$stdout"
    }

    set lines [ split $stdout "\n" ]

    set rev -1
    foreach line $lines {
        if [ regexp {Working revision:.*} $line str ] {
            if [ regexp {No entry.*} $str ] {
                # Probably checkout needed
                break
            }
            set rev [ lindex $str 2 ]
            break
        }
    }

    if { $rev == -1 } {
        return -code error "Could not determine <$filename> revision."
    }

    return $rev
}

#===============================================================================

proc ::YadtCvs::Determine_CVS_Root_From_File { filename } {

    set fname [ file join [ file dirname $filename ] CVS Root ]

    set cvsroot [ ::Yadt::Read_File $fname -nonewline ]

    if { $cvsroot == "" } {
        return -code error "Couldn't determine CVS Root"
    }

    return $cvsroot
}

#===============================================================================

proc ::YadtCvs::Determine_CVS_Module_From_File { filename } {

    set fname [ file join [ file dirname $filename ] CVS Repository ]

    set content [ ::Yadt::Read_File $fname -nonewline ]

    if { $content == "" } {
        return -code error "Couldn't determine CVS Module"
    }

    return $content
}

#===============================================================================

proc ::YadtCvs::Split_CVS_Conflicts { filepath chdir secondname } {

    switch -- [ ::Yadt::Get_Diff_Type ] {
        2 {
            set confl_files [ ::YadtCvs::Split_CVS_Conflicts2 $filepath ]

            ::Yadt::Prepare_File [ lindex "$confl_files" 0 ] 1 $chdir
            ::Yadt::Prepare_File [ lindex "$confl_files" 1 ] 2 $chdir
            ::Yadt::Set_Diff_File_Label 1 [ lindex "$confl_files" 2 ]
            ::Yadt::Set_Diff_File_Label 2 [ lindex "$confl_files" 3 ]            
        }
        3 {
            set confl_files [ ::YadtCvs::Split_CVS_Conflicts3 $filepath $secondname ]

            ::Yadt::Prepare_File [ lindex "$confl_files" 0 ] 1 $chdir
            ::Yadt::Prepare_File [ lindex "$confl_files" 1 ] 2 $chdir
            ::Yadt::Prepare_File [ lindex "$confl_files" 2 ] 3 $chdir
            ::Yadt::Set_Diff_File_Label 1 [ lindex "$confl_files" 3 ]
            ::Yadt::Set_Diff_File_Label 2 [ lindex "$confl_files" 4 ]
            ::Yadt::Set_Diff_File_Label 3 [ lindex "$confl_files" 5 ]
        }
        default {
            return -code error "Couldn't determine conflict type in <$filepath>"
        }
    }
}

#===============================================================================

proc ::YadtCvs::Split_CVS_Conflicts2 { filepath } {

    set filedir [ file dirname $filepath ]
    set filename [ file tail $filepath ]

    set first ${filename}.1
    set second ${filename}.2

    set temp1 [ ::Yadt::Temp_File $first ]
    set temp2 [ ::Yadt::Temp_File $second ]

    if [ catch { open $filepath r } input ] {
        return -code error "Couldn't open file <$filepath>: $input"
    }

    set first [ open $temp1 w ]
    ::Yadt::Tmp_Files_List add -file $temp1
    set second [ open $temp2 w ]
    ::Yadt::Tmp_Files_List add -file $temp2

    set firstname ""
    set secondname ""
    set output 3

    set firstMatch ""
    set secondMatch ""
    set thirdMatch ""

    while { [ gets $input line ] >= 0 } {
        if { $firstMatch == "" } {
            if { [ regexp {^<<<<<<<* +(.*)} $line ] } {
                set firstMatch {^<<<<<<<* +(.*)}
                set secondMatch {^=======*}
                set thirdMatch {^>>>>>>>* +(.*)}
            } elseif { [ regexp {^>>>>>>>* +(.*)} $line ] } {
                set firstMatch {^>>>>>>>* +(.*)}
                set secondMatch {^<<<<<<<* +(.*)}
                set thirdMatch {^=======*}
            }
        }
        if { $firstMatch != "" } {
            if { [ regexp $firstMatch $line ] } {
                set output 2
                if { $secondname == "" } {
                    regexp $firstMatch $line all secondname
                }
            } elseif { [ regexp $secondMatch $line ] } {
                set output 1
                if { $firstname == "" } {
                    regexp $secondMatch $line all firstname
                }
            } elseif { [ regexp $thirdMatch $line ] } {
                set output 3
                if { $firstname == "" } {
                    regexp $thirdMatch $line all firstname
                }
            } else {
                if { $output & 1 } {
                    puts $first $line
                }
                if { $output & 2 } {
                    puts $second $line
                }
            }
        } else {
            puts $first $line
            puts $second $line
        }
    }
    close $input
    close $first
    close $second

    if { $firstname == "" } {
        set firstname "old"
    }
    if { $secondname == "" } {
        set secondname "new"
    }

    return "{$temp1} {$temp2} {$firstname} {$secondname}"
}

#===============================================================================

proc ::YadtCvs::Split_CVS_Conflicts3 { filepath secondname } {

    set filedir [ file dirname $filepath ]
    set filename [ file tail $filepath ]

    if [ catch { open $filepath r } input ] {
        return -code error "Couldn't open file <$filepath>: $input"
    }

    set first ${filename}.1
    set second ${filename}.2
    set third  ${filename}.3

    set temp1 [ ::Yadt::Temp_File $first ]
    set temp2 [ ::Yadt::Temp_File $second ]
    set temp3 [ ::Yadt::Temp_File $third ]

    set first  [ open $temp1 w ]
    ::Yadt::Tmp_Files_List add -file $temp1
    set second [ open $temp2 w ]
    ::Yadt::Tmp_Files_List add -file $temp2
    set third  [ open $temp3 w ]
    ::Yadt::Tmp_Files_List add -file $temp3

    set firstMatch {^<<<<<<<* +(.*)}
    set secondMatch {^\|\|\|\|\|\|\|* +(.*)}
    set thirdMatch {^=======*}
    set fourthMatch {^>>>>>>>* +(.*)}

    set firstname ""
    set thirdname ""

    set start -1
    set secondfound 0

    set buffer(1) ""
    set buffer(2) ""
    set buffer(3) ""

    while { [ gets $input line ] >= 0 } {

        if [ regexp $firstMatch $line ] {
            set start 1
            if { $firstname == "" } {
                regexp $firstMatch $line all firstname
            }
            if { $firstname == $secondname } {
                set firstname ""
            }
            continue
        }

        if [ regexp $secondMatch $line ] {
            set secondfound 1
            set start 2
            continue
        }

        if [ regexp $thirdMatch $line ] {
            set start 3
            continue
        }

        if [ regexp $fourthMatch $line ] {
            if { $thirdname == "" } {
                regexp $fourthMatch $line all thirdname
            }
            set start 0
        }

        switch -- $start {
            -1 {
                puts $first $line
                puts $second $line
                puts $third $line
            }
            0 {
                if { $buffer(1) != "" } {
                    puts $first $buffer(1)
                }
                if { $buffer(2) != "" } {
                    puts $second $buffer(2)
                }
                if { $buffer(3) != "" } {
                    puts $third $buffer(3)
                }

                set buffer(1) ""
                set buffer(2) ""
                set buffer(3) ""

                set start -1
                set secondfound 0
            }
            1 {
                if { $line != "" } {
                    if { $buffer(1) != "" } {
                        append buffer(1) "\n"
                    }
                    append buffer(1) $line
                }
            }
            2 {
                if { $line != "" } {
                    if { $buffer(2) != "" } {
                        append buffer(2) "\n"
                    }
                    append buffer(2) $line
                }
            }
            3 {
                if { $line != "" } {
                    if { $buffer(3) != "" } {
                        append buffer(3) "\n"
                    }
                    append buffer(3) $line
                }

                if { !$secondfound } {
                    set buffer(2) $buffer(1)
                    set buffer(1) $buffer(3)
                }
            }
        }
    }
   
    close $input
    close $first
    close $second
    close $third

    return "{$temp1} {$temp2} {$temp3} {$firstname} {$secondname} {$thirdname}"
}

#===============================================================================
