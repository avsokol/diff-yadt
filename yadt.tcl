#!/bin/sh
#-*-tcl-*-
# the next line restarts using wish \
exec wish "$0" -- ${1+"$@"}

# above header is left for backward compatibility - 
# YaDT is actually supposed to be run
# as a standalone starkit executable or via tclkit

################################################################################
#
#  YaDT - yet-another-diff-tool
#         based on tkdiff tool
#         allows to compare two or three files with merge possibility
#
#
#------------------------------------------------------------------------------
#
#  Packages  required: Tk BWidget CmnTools
#
#
################################################################################

package provide yadt 1.0

#===============================================================================

namespace eval ::Yadt {

}

variable ::Yadt::DIFF_TYPE
variable ::Yadt::MERGE_START

# DIFF_FILES - array which contains a set of files information:
#  files paths, labels, merge marks, contents etc.
variable ::Yadt::DIFF_FILES

# TEXT_WDG - array: names: 1,2,3
# elements: widget pathes of text windows
variable ::Yadt::TEXT_WDG
variable ::Yadt::TEXT_NUM_WDG
variable ::Yadt::TEXT_INFO_WDG
variable ::Yadt::MERGE_TEXT_WDG
variable ::Yadt::MERGE_INFO_WDG

variable ::Yadt::MAP_TITLE
variable ::Yadt::MAP_TITLE_SHORT
variable ::Yadt::DIFF_CMD
variable ::Yadt::DIFF_IGNORE_SPACES_OPTION "-w"
variable ::Yadt::VCS_CMD

# widget variables
variable ::Yadt::WIDGETS

variable ::Yadt::OPTIONS
variable ::Yadt::WDG_OPTIONS

# Array for storing internal values like 
# pos, count, delta, pdiff, scrdiff, merge<value>
variable ::Yadt::DIFF_INT

# pdiff - represent region of start and end lines of original diff size, f.i.
#   For DIFF2:
#     DIFF_INT(<diff_number>,pdiff) = 
#       <orig_diff_value> start_line1 end_line1 start_line2 end_line2 diff_type
#   Example:
#     DIFF_INT(12,pdiff)   = 30,36c187,239 30 36 187 239 c
#   For DIFF3:
#     DIFF_INT(<diff_number>,<file_number>,pdiff) =
#       <orig_diff_value> start_line end_line diff_type
#   Examlpe:
#     DIFF_INT(29,1,pdiff)    = 83a 83 83 a
#     DIFF_INT(29,2,pdiff)    = 346,349c 346 349 c
#     DIFF_INT(29,3,pdiff)    = 346,349c 346 349 c

# scrdiff - represent region of start and end lines of screen diff size, t.i. 
#     some blank lines in text widgets are taken into account: start and end 
# lines here means start and end lines inside of a text widget
#   DIFF2 Example:
#     DIFF_INT(12,scrdiff) = 188 240 c
#   DIFF3 Example:
#     DIFF_INT(12,scrdiff) = 188 240 cca

# scrtag -  represents tags in text widgets. Used to toggle such tags 
#     depending on shown_in_lines option
#  DIFF_INT(scrtag,diff_id,file_number) = <tag> <from_line> <to_line>

# scrinline - represents inline differences for each line inside of a differrence
# DIFF_INT(scrinline,diff_id,file_number) - value of inline diffs 
#     in file <file_number> in diff <diff_id>
# DIFF_INT(scrinline,diff_id,file_number,inline_diff_id) = <string_num> <col_start> <col_end>
# 
# Example:
#     DIFF_INT(scrinline,1,2)    = 6
#     DIFF_INT(scrinline,1,2,0)  = 10728 42 46
#     DIFF_INT(scrinline,1,2,1)  = 10729 6 7
#     DIFF_INT(scrinline,1,2,2)  = 10729 10 13
#     DIFF_INT(scrinline,1,2,3)  = 10729 14 35
#     DIFF_INT(scrinline,1,2,4)  = 10729 37 41
#     DIFF_INT(scrinline,1,2,5)  = 10729 42 43
#     DIFF_INT(scrinline,1,3)    = 9
#     DIFF_INT(scrinline,1,3,0)  = 10728 41 43
#     DIFF_INT(scrinline,1,3,1)  = 10729 4 10
#     DIFF_INT(scrinline,1,3,2)  = 10729 11 20
#     DIFF_INT(scrinline,1,3,3)  = 10729 21 35
#     DIFF_INT(scrinline,1,3,4)  = 10729 36 41
#     DIFF_INT(scrinline,1,3,5)  = 10729 42 46
#     DIFF_INT(scrinline,1,3,6)  = 10729 47 48
#     DIFF_INT(scrinline,1,3,7)  = 10729 50 52
#     DIFF_INT(scrinline,1,3,8)  = 10729 53 55

#-------------------------------------------------------------------------------

# Input data array for diff - get by Exec_Diff2 proc
variable ::Yadt::DIFF2
# Format:
# DIFF2(diff) <list of diff output values>

# Example:
# DIFF2(diff) = "1c1 3c3 5d4 6a6 8c8 10c10 12,13c12"

#-------------------------------------------------------------------------------

# The folowing array is used for diff3 comparison. As we do not use diff3 anymore,
# but insetad, we compare 1st file vs 2nd, 1st vs 3rd
# Format of these variables is the same as for DIFF2
variable ::Yadt::DIFFS

#-------------------------------------------------------------------------------

# As we do not use diff3 anymore, DIFF3 contains a result of merging results from
# above variables, but in the format of diff3 output
variable ::Yadt::DIFF3

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

# Example:
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
#-------------------------------------------------------------------------------

# Array, which contains a common longest substring (cls) elements between files
# used for comparing 3 files
# array keys: '12', '13', '23', 'unchanged'
variable ::Yadt::LCSDATA
# Format: f.i. LCSDATA(13) - cls between 1st and 3rd files contains
# 2 lists of lists of equal length:
# {0 1 2 3 4 7 8 9 10 12 13 14 15 16 18 20 21 22 23 58 59 60 61 62 63 85 86 91}
# {0 1 2 3 4 7 8 9 10 12 13 14 15 16 18 20 21 22 23 24 25 26 27 28 29 30 31 37}
# Each i-th element shows equal string numbers (note that lists start from zero)
# in the 1st and the 3rd files.
# Example:
#   19-th element: 1st - 23, 3rd - 23 and
#   20-th element: 1st - 58, 3rd - 24
# That means:
#   line24 from 1st == line 24 from 3rd and as the next element:
#   line59 from 1st == line 25 from 3rd.
# obvious that lines 25-58 were deleted in the 1st file.
# Key 'unchanged' shows lines which are equal in all three files.
# Such fragments (parts of file) of equal lines are considered to be a kind of
# 'separator' between file diffs - diff3
#-------------------------------------------------------------------------------

# Ranges inside diff3 variables - used for expert merge mode
# RANGES:
#     keys - ranges id,
#     values - list of range's 'start_line end_line'
# RANGES2DIFF:
#     keys - ranges id,
#     values 'diff_id', diff3 id, which correspond to current range
# DIFFS2RANGES:
#     keys - diff_id, normal diff3_id
#     values - list of ranges id, which are inside of this diff3 id
variable ::Yadt::RANGES
variable ::Yadt::RANGES2DIFF
variable ::Yadt::DIFF2RANGES

################################################################################
# Some helpfull additional procs                                               #
################################################################################

#===============================================================================

proc ::Yadt::Make_Absolute_Real_Path { relpath } {

    while { [ file type $relpath ] == "link" } {
        set temp [ file readlink $relpath ]
        if ![ regexp "^/" $temp ] {
            set temp [ file nativename [ file join [ file dirname $relpath ] $temp ] ]
        }
        if { $relpath == $temp } break
        set relpath $temp
    }
    return $relpath
}

#===============================================================================

proc ::Yadt::Disable_Mouse_Paste {} {

    variable ::Yadt::OPTIONS

    set OPTIONS(paste_proc_body) [ info body ::tk::TextPasteSelection ]

    # Redefine ::tk::TextPasteSelection to do nothing 
    # to avoid text paste via Mouse Button
    proc ::tk::TextPasteSelection { w x y } { }
}

#===============================================================================

proc ::Yadt::Enable_Mouse_Paste {} {

    variable ::Yadt::OPTIONS

    # Restore saved ::tk::TextPasteSelection proc
    proc ::tk::TextPasteSelection { w x y } { 
        eval $::Yadt::OPTIONS(paste_proc_body)
    }
}

#===============================================================================

proc ::Yadt::Align_Cmd_For_Old_Windows { command } {

    # on Windows XP, redo diff will lead to a diff(3) execution hang
    # when stdin handler is set
    # passing smth, even empty str to stdin while executing diff(3)
    # resolves this problem
    global tcl_platform
    variable ::Yadt::OPTIONS
    upvar $command cmd

    if { $OPTIONS(external_call) && \
             $tcl_platform(platform) == "windows" && \
             $tcl_platform(osVersion) < "6.1" } {
        lappend cmd << ""
    }
}

#===============================================================================

proc ::Yadt::Run_Cmd_As_Pipe { cmd } {

    variable ::Yadt::WDG_OPTIONS
    global errorCode

    ::Yadt::Align_Cmd_For_Old_Windows cmd

    set stderr ""
    set exitcode 0

    set cmd [ linsert $cmd 0 "|" ]

    set fd [ open $cmd r ]
    set stdout [ read -nonewline $fd ]
    set fd_exitcode [ catch { close $fd } stderr ]

    if { $fd_exitcode != 0 } {
        set exitcode [ ::CmnTools::Obtain_Result_From_Error_Code -default_value -1 ]
        if { $exitcode != 0 } {
            if { $exitcode == 1 } {
                regsub "child process exited abnormally" $stderr "" stderr
            } else {
                set stderr $stdout
            }
        }
    }

    return [ list "$stdout" "$stderr" "$exitcode" ]
}

#===============================================================================

proc ::Yadt::Execute_Cmd { cmd } {

    ::Yadt::Align_Cmd_For_Old_Windows cmd

    set stderr ""
    set exitcode 0

    if [ catch { eval exec $cmd } stdout ] {
        set exitcode [ ::CmnTools::Obtain_Result_From_Error_Code -default_value -1 ]
    }
    if { $exitcode != 0  &&  $exitcode != 1 } {
        set stderr $stdout
    }
    return [ list "$stdout" "$stderr" "$exitcode" ]
}

#===============================================================================

proc ::Yadt::Exec_To_File { cmd file } {

    global errorCode

    set exec_cmd $cmd
    lappend exec_cmd >$file

    set result [ ::Yadt::Execute_Cmd $exec_cmd ]

    lassign $result stdout stderr exitcode

    ::Yadt::Ignore_No_CVS_Tag_Error stdout -code exitcode

    if { $exitcode != 0 } {
        return -code error "Error while executing <$cmd>:\n$stderr\n$stdout"
    }
}

#===============================================================================

proc ::Yadt::Ignore_No_CVS_Tag_Error { cvs_out args } {

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
        set exitcode 0
    }    
}

#===============================================================================

proc ::Yadt::Generate_Next_Id {} {

    variable ::Yadt::WDG_OPTIONS

    incr WDG_OPTIONS(counter)

    return $WDG_OPTIONS(counter)
}

#===============================================================================

proc ::Yadt::Temp_File { filename } {

    variable ::Yadt::OPTIONS

    set attempt 5

    while { $attempt > 0 } {
        set fname "[ file rootname ${filename} ]_[ pid ]_[ clock seconds ]_[ ::Yadt::Generate_Next_Id ][ file extension $filename ]"
        set fpath [ file join $OPTIONS(tmpdir) $fname ]

        if { ![ file exist $fpath ] && ![ file isdirectory $fpath ] } {
            return $fpath
        }

        incr attempt -1
        after 500
    }

    return -code error "After <$attempt> attempts couldn't create tmp file for <$filename>."
}

#===============================================================================

proc ::Yadt::Check_Conflict_Type { filepath second_name } {

    upvar $second_name secondname

    set dif_type 2
    set secondname ""

    set check_pattern {^\|\|\|\|\|\|\|* +(.*)}

    set fd [ open $filepath r ]

    while { [ gets $fd line ] >= 0 } {
        if [ regexp $check_pattern $line dummy secname ] {
            set secondname secname
            set dif_type 3
            break
        }
    }

    close $fd

    return $dif_type
}

#===============================================================================

proc ::Yadt::Split_CVS_Conflicts { filepath chdir secondname } {

    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::DIFF_FILES

    switch -- $DIFF_TYPE {
        2 {
            set confl_files [ ::Yadt::Split_CVS_Conflicts2 $filepath ]

            ::Yadt::Prepare_File [ lindex "$confl_files" 0 ] 1 $chdir
            ::Yadt::Prepare_File [ lindex "$confl_files" 1 ] 2 $chdir
            set DIFF_FILES(label,1) [ lindex "$confl_files" 2 ]
            set DIFF_FILES(label,2) [ lindex "$confl_files" 3 ]            
        }
        3 {
            set confl_files [ ::Yadt::Split_CVS_Conflicts3 $filepath $secondname ]

            ::Yadt::Prepare_File [ lindex "$confl_files" 0 ] 1 $chdir
            ::Yadt::Prepare_File [ lindex "$confl_files" 1 ] 2 $chdir
            ::Yadt::Prepare_File [ lindex "$confl_files" 2 ] 3 $chdir
            set DIFF_FILES(label,1) [ lindex "$confl_files" 3 ]
            set DIFF_FILES(label,2) [ lindex "$confl_files" 4 ]
            set DIFF_FILES(label,3) [ lindex "$confl_files" 5 ]
        }
        default {
            return -code error "Couldn't determine conflict type in <$filepath>"
        }
    }
}

#===============================================================================

proc ::Yadt::Split_CVS_Conflicts2 { filepath } {

    variable ::Yadt::OPTIONS
    variable ::Yadt::WDG_OPTIONS

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
    lappend WDG_OPTIONS(tempfiles) $temp1
    set second [ open $temp2 w ]
    lappend WDG_OPTIONS(tempfiles) $temp2

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

proc ::Yadt::Split_CVS_Conflicts3 { filepath secondname } {

    variable ::Yadt::OPTIONS
    variable ::Yadt::WDG_OPTIONS

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
    lappend WDG_OPTIONS(tempfiles) $temp1
    set second [ open $temp2 w ]
    lappend WDG_OPTIONS(tempfiles) $temp2
    set third  [ open $temp3 w ]
    lappend WDG_OPTIONS(tempfiles) $temp3

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

proc ::Yadt::Prepare_File { filename index { chdir "" } } {

    variable ::Yadt::DIFF_FILES

    if ![ file exist $filename ] {
        set errmsg "File <$filename> does not exist"
        if { $chdir != "" && [ file pathtype $filename ] == "relative" } {
            append errmsg " in $chdir"
        }
        return -code error $errmsg
    }
    if [ file isdirectory $filename ] {
        set errmsg "File <$filename>"
        if { $chdir != "" && [ file pathtype $filename ] == "relative" } {
            append errmsg " in $chdir"
        }
        append errmsg " is a directory"
        return -code error $errmsg
    }

    set DIFF_FILES(label,$index) "$filename"
    set DIFF_FILES(path,$index) "$filename"
    set DIFF_FILES(full_path,$index) "[ file join [ pwd ] $filename ]"
    set DIFF_FILES(tmp,$index) 0
}

#===============================================================================

proc ::Yadt::Detect_VCS { dir } {

    variable ::Yadt::OPTIONS

    set cvs_dir [ file join $dir CVS ]

    # check for CVS
    if { [ file exists $cvs_dir ] && [ file isdirectory $cvs_dir ] } {
        set OPTIONS(vcs) "cvs"
        return
    }

    # check for GIT
    set abs_dir [ file nativename [ file normalize $dir ] ]
    set dir $abs_dir
    while { 1 } {
        if { $dir == "/" } {
            break
        }
        set git_dir [ file join $dir .git ]
        if { [ file exists $git_dir ] && [ file isdirectory $git_dir ] } {
            set OPTIONS(vcs) "git"
            return
        }
        set dir [ file dirname $dir ]
    }
}

#===============================================================================

proc ::Yadt::Prepare_File_Rev { filename index { rev "" } } {

    variable ::Yadt::OPTIONS
    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::DIFF_FILES

    set dirname [ file dirname $filename ]
    set tailname [ file tail $filename ]

    switch -- $OPTIONS(vcs) {
        "cvs" {
            set vcs_cmd [ ::Yadt::Prepare_CVS_Cmd $filename $index $rev ]
        }
        "git" {
            set vcs_cmd [ ::Yadt::Prepare_GIT_Cmd $filename $index $rev ]
        }
        default {
            return -code error "Sorry, VCS <$OPTIONS(vcs)> not supported yet"
        }
    }

    # output_file_content_to can be -file or -variable:
    #     -file     : we retrieve file from CVS and save it in tmp dir
    #                 for further "diff" or "diff3" execution
    #     -variable : we save file revision content into the variable DIFF_FILES(content,..)
    #                 this content is needed for loading into the text widget
    # Note, that for cvs and diff3 (DIFF_TYPE =3) we always use -file for output_file_content_to as
    # it is not possible to use "cvs diff" for comparing 3 revisions

    set output_file_content_to -variable
    if { !$OPTIONS(use_cvs_diff) } {
        set output_file_content_to -file
    }
    if { $OPTIONS(vcs) == "cvs" && $DIFF_TYPE == 2 && $OPTIONS(use_cvs_diff) } {
        set output_file_content_to -variable
    }

    switch -- $output_file_content_to {
        -file {
            set DIFF_FILES(path,$index) [ ::Yadt::Temp_File $tailname ]
            set DIFF_FILES(tmp,$index) 1

            ::Yadt::Exec_To_File $vcs_cmd $DIFF_FILES(path,$index)
        }
        -variable {
            set result [ ::Yadt::Run_Cmd_As_Pipe $vcs_cmd ]
            set err  [ lindex $result 1 ]
            set code [ lindex $result 2 ]

            if { $code < 0 || $code > 1 } {
                return -code error "diff failed:\ncode: '$code'\nError message: '$err'"
            }

            set DIFF_FILES(content,$index) [ lindex $result 0 ]
            set DIFF_FILES(path,$index) ""
            set DIFF_FILES(tmp,$index) 0
            set DIFF_FILES(rev,$index) $rev
            set DIFF_FILES(filename,$index) $filename
        }
        default {
            return -code error "Unsupported value <$output_file_content_to>\
             for 'output_file_content_to' variable in [ lindex [ info level 0 ] 0 ]"
        }
    }
}

#===============================================================================

proc ::Yadt::Prepare_CVS_Cmd { filename index rev } {

    variable ::Yadt::DIFF_FILES
    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::OPTIONS
    variable ::Yadt::VCS_CMD

    set dirname [ file dirname $filename ]
    set tailname [ file tail $filename ]

    set cvsroot   $OPTIONS(cvsroot)
    set cvsmodule $OPTIONS(cvsmodule)

    if { [ file pathtype $filename ] == "absolute" } {

        if ![ file exists $filename ] {
            return -code error "No such file <$filename>"
        }

        # If file path is absolute, we get cvsroot and cvsmodule from
        # CVS/Root and CVS/Repository files.
        # If either cvsroot or cvsmodule is specified as a parameter,
        # we ignore it and show warning msg about it at the YaDT start.

        if { $cvsroot != "" } {
            set msg "CVS Root <$cvsroot> shouldn't be specified\
                     for absolute file path <$filename>"
            if { [ lsearch $OPTIONS(start_warn_msg) $msg ] < 0 } {
                lappend OPTIONS(start_warn_msg) $msg
            }
        }
        if { $cvsmodule != "" } {
            set msg "CVS Module <$cvsmodule> shouldn't be specified\
                     for absolute file path <$filename>"
            if { [ lsearch $OPTIONS(start_warn_msg) $msg ] < 0 } {
                lappend OPTIONS(start_warn_msg) $msg
            }
        }

        set cvsroot   [ ::Yadt::Determine_CVS_Root_From_File   $filename ]
        set cvsmodule [ ::Yadt::Determine_CVS_Module_From_File $filename ]

        set file_to_compare $cvsmodule/$tailname

    } else {

        # If file path is relative:
        # If cvsroot, cvsmodule and revision are specified - 
        #     we assume file path is a path inside cvs structure
        #     and compare directly cvsmodule/filename,
        #     otherwise, local file should exist.
        # If specified either cvsroot or cvsmodule - 
        #     use it, and get unspecified parameter from CVS dir

        if { $cvsroot != "" && $cvsmodule != "" && $rev != "" } {
            set file_to_compare $cvsmodule/$filename
        } else {

            if ![ file exists $filename ] {
                return -code error "No such file <$filename>"
            }

            if { $cvsroot == "" } {
                set cvsroot [ ::Yadt::Determine_CVS_Root_From_File $filename ]
            }

            set f_cvsmodule [ ::Yadt::Determine_CVS_Module_From_File $filename ]

            if { $cvsmodule == "" } {
                set cvsmodule $f_cvsmodule
                set fname $tailname
            } else {
                if { $cvsmodule != $f_cvsmodule } {
                    set msg "Specified CVS Module: <$cvsmodule>\
                             differs from those if CVS <$dirname> directory: <$f_cvsmodule>.\
                             \nMake sure you compare exactly what you need."
                    lappend OPTIONS(start_warn_msg) $msg
                }
                set fname $filename
            }
            set file_to_compare $cvsmodule/$fname
        }
    }

    if { $rev == "" } {
        # By default we use not HEAD, but Working file revision
        if { $OPTIONS(cvs_ver_from_entry) } {
            set rev [ ::Yadt::Get_Work_Rev_From_Entries $filename ]
        }
        if { $rev < 0  ||  $rev == "" } {
            # Failed to obtain version from 'CVS/Entries' OR it is defined to
            # get version from the "cvs status" command:
            set rev [ ::Yadt::Get_Work_Rev_From_CVS $filename ]
        }
    }

    set DIFF_FILES(label,$index) "$filename (CVS r$rev)"

    set vcs_cmd [ list $VCS_CMD -d $cvsroot -q co -p -r $rev $file_to_compare ]

    return $vcs_cmd
}

#===============================================================================

proc ::Yadt::Prepare_GIT_Cmd { filename index rev } {
    
    variable ::Yadt::DIFF_FILES
    variable ::Yadt::VCS_CMD

    if { $rev == "" } {
        set rev "HEAD"
    }

    set DIFF_FILES(label,$index) "$filename (CVS r$rev)"

    set vcs_cmd [ list $VCS_CMD show $rev:$filename ]

    return $vcs_cmd
}

#===============================================================================

proc ::Yadt::Prepare_For_Diff3 {} {

    variable ::Yadt::DIFF_FILES

    set dirs_count 0

    for { set i 1 } { $i <= 3 } { incr i } {

        set files_map(path,$i) $DIFF_FILES(path,$i)

        if [ file isdirectory $DIFF_FILES(path,$i) ] {
            incr dirs_count
            set files_map(type,$i) dir
        } else {
            set files_map(type,$i) file
            set files_map(name,$i) [ file tail $DIFF_FILES(path,$i) ]
        }
    }

    switch -- $dirs_count {
        1 {
            set found 0
            for { set i 1 } { $i <= 3 } { incr i } {
                if { $files_map(type,$i) == "file" } {

                    if { !$found } {
                        set fname $files_map(name,$i)
                        set found 1
                        continue
                    }

                    if { $fname !=  $files_map(name,$i) } {
                        return -code error "Cannot determine which file to diff <$fname> or <$files_map(name,$i)>"
                    }
                }
            }

            for { set i 1 } { $i <= 3 } { incr i } {
                if { $files_map(type,$i) == "dir" } {
                    set files_map(path,$i) [ file join $files_map(path,$i) $fname ] 
                    break
                }
            }
        }
        2 {
            for { set i 1 } { $i <= 3 } { incr i } {
                if { $files_map(type,$i) == "file" } {
                    set fname [ file tail $files_map(name,$i) ]
                    break
                }
            }
            for { set i 1 } { $i <= 3 } { incr i } {
                if { $files_map(type,$i) == "dir" } {
                    set files_map(path,$i) [ file join $files_map(path,$i) $fname ]
                }
            }
        }
        3 {
            return -code error "Either <$files_map(path,1)> or <$files_map(path,2)>\
                       or <$files_map(path,3)> must be a plain file."
        }
        0 -
        default {
        }
    }

    for { set i 1 } { $i <= 3 } { incr i } {
        ::Yadt::Prepare_File $files_map(path,$i) $i
    }
}

#===============================================================================

proc ::Yadt::Clean_Tmp {} {

    variable ::Yadt::DIFF_FILES
    variable ::Yadt::WDG_OPTIONS
    variable ::Yadt::DIFF_TYPE

    for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
        if { [ info exists DIFF_FILES(tmp,$i) ] && $DIFF_FILES(tmp,$i) } {
            file delete $DIFF_FILES(path,$i)
        }
    }

    foreach fname $WDG_OPTIONS(tempfiles) {
        file delete $fname
    }
}

#===============================================================================

proc ::Yadt::Get_Work_Rev_From_Entries { file } {

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

proc ::Yadt::Get_Work_Rev_From_CVS { filename } {

    variable ::Yadt::VCS_CMD

    set cvsroot [ ::Yadt::Determine_CVS_Root_From_File $filename ]

    set vcs_cmd [ list $VCS_CMD -d $cvsroot status $filename ]

    set result [ ::Yadt::Run_Cmd_As_Pipe $vcs_cmd ]
    lassign $result stdout stderr exitcode

    if { $exitcode != 0 } {
        return -code error "Error while executing <$vcs_cmd>:\n$stderr\n$stdout"
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

proc ::Yadt::Determine_CVS_Root_From_File { filename } {

    set fname [ file join [ file dirname $filename ] CVS Root ]

    set cvsroot [ ::Yadt::Read_File $fname -nonewline ]

    if { $cvsroot == "" } {
        return -code error "Couldn't determine CVS Root"
    }

    return $cvsroot
}

#===============================================================================

proc ::Yadt::Determine_CVS_Module_From_File { filename } {

    set fname [ file join [ file dirname $filename ] CVS Repository ]

    set content [ ::Yadt::Read_File $fname -nonewline ]

    if { $content == "" } {
        return -code error "Couldn't determine CVS Module"
    }

    return $content
}

#===============================================================================

proc ::Yadt::Read_File { filename args } {

    set nonewline [ ::CmnTools::Get_Arg -nonewline args -exists ]
    set translation [ ::CmnTools::Get_Arg -translation args -default "auto" ]

     if { ![ file exist $filename ] || ![ file isfile $filename ] } {
         return -code error "No such file <$filename>"
     }

    set fd [ open $filename r ]

    fconfigure $fd -translation $translation

    set cmd read
    if { $nonewline } {
        lappend cmd -nonewline
    }
    lappend cmd $fd
    set content [ eval $cmd ]
    close $fd

    return $content
}

#===============================================================================

################################################################################
# Main procs                                                                   #
################################################################################

#===============================================================================

proc ::Yadt::Is_Parameter { param } {

    set result 0

    switch -regexp -- $param {
        {^--ge(o|om|ome|omet|ometr|ometry)?$} -
        {^--ve(r|rt|rti|rtic|rtica|rtical)?$} -
        {^--ho(r|ri|riz|rizo|rizon|rizont|rizonta|rizontal)?$} -
        "^--bytetag$" -
        "^--config$" -
        "^--conflict$" -
        "^--diff3$" -
        "^--difftag$" -
        "^--chdir$" -
        "^--diff-cmd$" -
        "^--cvs-cmd$" -
        "^--git-cmd$" -
        "^--initline$" -
        "^--inlinetag$" -
        "^--inlineinstag$" -
        "^--inlinechgtag$" -
        "^--merge$" -
        "^--merge1$" -
        "^--merge2$" -
        "^--merge_mode$" -
        "^--module$" -
        "^--norc$" -
        "^--auto-merge$" -
        "^--external-call$" -
        "^--textopt$" -
        "^--title$" -
        "^--translation$" -
        "^--d$" -
        "^-d$" -
        "^-r$" - 
        "^-r.*" -
        "^-file$" {
            set result 1
        }
    }

    return $result
}

#===============================================================================

proc ::Yadt::Read_Config_File {} {

    variable ::Yadt::OPTIONS
    variable ::Yadt::WDG_OPTIONS

    if { $WDG_OPTIONS(config_file_path) != "" } {
        if [ file isdirectory $WDG_OPTIONS(config_file_path) ] {
            set WDG_OPTIONS(rcfile) [ file join $WDG_OPTIONS(config_file_path) $WDG_OPTIONS(basercfile) ]
        } else {
            set WDG_OPTIONS(rcfile) $WDG_OPTIONS(config_file_path)
        }
    } elseif [ info exists ::env(HOME) ] {
        set WDG_OPTIONS(rcfile) [ file join $::env(HOME) $WDG_OPTIONS(basercfile) ]
    } else {
        set WDG_OPTIONS(rcfile) [ file join "/" $WDG_OPTIONS(basercfile) ]
    }

    if !$WDG_OPTIONS(sourcercfile) return
    if ![ file exist $WDG_OPTIONS(rcfile) ] return

    set file_content [ ::Yadt::Read_File $WDG_OPTIONS(rcfile) ]

    foreach { name value } [ ::CmnTools::Parse_Yadt_Customization_Data $file_content ] {

        if { [ info exists WDG_OPTIONS($name,is_set) ] && \
                 $WDG_OPTIONS($name,is_set) } continue

        set OPTIONS($name) $value
        set WDG_OPTIONS($name,is_set) 1
    }
}

#===============================================================================

proc ::Yadt::Parse_Args {} {

    global argv argc ERROR_CODES

    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::MERGE_START
    variable ::Yadt::DIFF_FILES
    variable ::Yadt::DIFF_CMD
    variable ::Yadt::VCS_CMD
    variable ::Yadt::OPTIONS
    variable ::Yadt::WDG_OPTIONS

    set execute_list {}

    set DIFF_TYPE 0
    set revs 0
    set conflict 0
    set argindex 0

    set rev_index 0
    array unset rev_order

    set chdir ""
    set DIFF_CMD ""
    set VCS_CMD ""
    set diff_option 2
    set OPTIONS(vcs_needed) 0

    # Note: there is no sense to parse and to support "--" option
    # This option is completely ignored by wish or tclkit
    while { $argindex < $argc } {
        set arg [ lindex $argv $argindex ]
        switch -regexp -- $arg {
            {^--ge(o|om|ome|omet|ometr|ometry)?$} {
                incr argindex
                set arg_value [ lindex $argv $argindex ]
                if [ ::CmnTools::Parse_WM_Geometry $arg_value -width width -height height -left x -top y ] {
                    set OPTIONS(geometry) ""

                    if { [ info exists width ] && [ info exists height ] } {
                        set WDG_OPTIONS(yadt_width)  [ expr { $width  <= [ winfo screenwidth  . ] ? $width  : [ winfo screenwidth  . ] } ]
                        set WDG_OPTIONS(yadt_height) [ expr { $height <= [ winfo screenheight . ] ? $height : [ winfo screenheight . ] } ]
                        set OPTIONS(geometry) "$WDG_OPTIONS(yadt_width)x$WDG_OPTIONS(yadt_height)"
                        set WDG_OPTIONS(size,is_set) 1
                    }

                    if { [ info exists x ] && [ info exists y ] } {
                        set sign_x [ string range $x 0 0 ]
                        set sign_y [ string range $y 0 0 ]
                        set WDG_OPTIONS(yadt_x) [ expr { $x <= [ expr { [ winfo screenwidth . ] - 100 } ] ? $x : 100 } ]
                        set WDG_OPTIONS(yadt_y) [ expr { $y <= [ expr { [ winfo screenheight . ] - 100 } ] ? $y : 100 } ]

                        if { $WDG_OPTIONS(yadt_x) < 0 } {
                            set sign_x ""
                        }
                        if { $WDG_OPTIONS(yadt_y) < 0 } {
                            set sign_y ""
                        }

                        set OPTIONS(geometry) "$OPTIONS(geometry)$sign_x$WDG_OPTIONS(yadt_x)$sign_y$WDG_OPTIONS(yadt_y)"
                        set WDG_OPTIONS(position,is_set) 1
                    }
                } else {
                    return -code $ERROR_CODES(argerror) "Incorrect geometry specified: <$arg_value>"
                }
            }
            {^--ve(r|rt|rti|rtic|rtica|rtical)?$} {
                set OPTIONS(diff_layout) vertical
                set WDG_OPTIONS(diff_layout,is_set) 1
            }
            {^--ho(r|ri|riz|rizo|rizon|rizont|rizonta|rizontal)?$} {
                set OPTIONS(diff_layout) horizontal
                set WDG_OPTIONS(diff_layout,is_set) 1
            }
            "^--bytetag$" {
                incr argindex
                set OPTIONS(bytetag) [ lindex $argv $argindex ]
                set WDG_OPTIONS(bytetag,is_set) 1
            }
            "^--chdir$" {
                incr argindex
                set chdir [ lindex $argv $argindex ]
                cd $chdir
            }
            "^--diff-cmd$" {
                incr argindex
                set DIFF_CMD [ lindex $argv $argindex ]
            }
            "^--cvs-cmd$" {
                incr argindex
                set VCS_CMD [ lindex $argv $argindex ]
            }
            "^--git-cmd$" {
                incr argindex
                set VCS_CMD [ lindex $argv $argindex ]
            }
            "^--config$" {
                incr argindex
                set WDG_OPTIONS(config_file_path) [ lindex $argv $argindex ]
                set WDG_OPTIONS(config_file_path,is_set) 1
            }
            "^--difftag$" {
                incr argindex
                set OPTIONS(difftag) [ lindex $argv $argindex ]
                set WDG_OPTIONS(difftag,is_set) 1
            }
            "^--initline$" {
                incr argindex
                ::Yadt::Set_Initline [ lindex $argv $argindex ]
            }
            "^--inlinetag$" {
                incr argindex
                set OPTIONS(inlinetag) [ lindex $argv $argindex ]
                set WDG_OPTIONS(inlinetag,is_set) 1
            }
            "^--inlineinstag$" {
                incr argindex
                set OPTIONS(inlineinstag) [ lindex $argv $argindex ]
                set WDG_OPTIONS(inlineinstag,is_set) 1
            }
            "^--inlinechgtag$" {
                incr argindex
                set OPTIONS(inlinechgtag) [ lindex $argv $argindex ]
                set WDG_OPTIONS(inlinechgtag,is_set) 1
            }
            "^--merge$" -
            "^--merge1$" {
                set OPTIONS(preview_shown) 1
                set WDG_OPTIONS(preview_shown,is_set) 1
                set OPTIONS(show_diff_lines) 1
                set WDG_OPTIONS(show_diff_lines,is_set) 1

                incr argindex
                set DIFF_FILES(merge1) [ lindex $argv $argindex ]
                if { $DIFF_FILES(merge1) == "" } {
                    return -code $ERROR_CODES(argerror) "Missed file name for <$arg> argument."
                }
                set WDG_OPTIONS(merge1set) 1
            }
            "^--merge2$" {
                set OPTIONS(preview_shown) 1
                set WDG_OPTIONS(preview_shown,is_set) 1
                set OPTIONS(show_diff_lines) 1
                set WDG_OPTIONS(show_diff_lines,is_set) 1

                incr argindex
                set DIFF_FILES(merge2) [ lindex $argv $argindex ]
                if { $DIFF_FILES(merge2) == "" } {
                    return -code $ERROR_CODES(argerror) "Missed file name for <$arg> argument."
                }
                set WDG_OPTIONS(merge2set) 1
            }
            "^--merge_mode$" {
                incr argindex 
                set OPTIONS(merge_mode) [ lindex $argv $argindex ]
                set WDG_OPTIONS(merge_mode,is_set) 1
            }
            "^--module$" {
                # parameter specifies module in cvs repository
                #  - usefull when comparing file in CVS
                # without having local repository copy
                incr argindex
                set OPTIONS(cvsmodule) [ lindex $argv $argindex ]
            }
            "^--norc$" {
                set WDG_OPTIONS(sourcercfile) 0
            }
            "^--auto-merge$" {
                set OPTIONS(automerge) 1
                set WDG_OPTIONS(automerge,is_set) 1
            }
            "^--external-call$" {
                set OPTIONS(external_call) 1
            }
            "^--textopt$" {
                incr argindex
                set OPTIONS(textopt) [ lindex $argv $argindex ]
                set WDG_OPTIONS(textopt,is_set) 1
            }
            "^--title$" {
                incr argindex
                set custom_title [ lindex $argv $argindex ]
                set WDG_OPTIONS(yadt_title) $custom_title
            }
            "^--translation$" {
                incr argindex
                set OPTIONS(translation) [ lindex $argv $argindex ]
            }
            "^--conflict$" {
                set conflict 1
            }
            "^--diff3$" {
                set diff_option 3
            }
            "^--d$" {
                incr argindex
                set OPTIONS(cvsroot) [ lindex $argv $argindex ]
                set WDG_OPTIONS(cvsroot,is_set) 1
            }
            "^-d$" {
                incr argindex
                set OPTIONS(cvsroot) [ lindex $argv $argindex ]
                set WDG_OPTIONS(cvsroot,is_set) 1
            }
            "^-r$" {
                incr revs
                set next_arg [ expr $argindex + 1 ]

                if { $next_arg > $argc || \
                         [ ::Yadt::Is_Parameter [ lindex $argv $next_arg ] ] } {
                    set rev($revs) ""
                } else {
                    incr argindex
                    set rev($revs) [ lindex $argv $argindex ]
                }
                incr rev_index
                set rev_order($rev_index) $rev($revs)
            }
            "^-r.*" {
                incr revs
                set rev($revs) [ string range $arg 2 end ]
                incr rev_index
                set rev_order($rev_index) $rev($revs)
            }
            default {
                incr DIFF_TYPE
                set DIFF_FILES(path,$DIFF_TYPE) $arg
                incr rev_index
                set rev_order($rev_index) $DIFF_FILES(path,$DIFF_TYPE)
            }
        }
        incr argindex
    }

    set OPTIONS(textopt) "$OPTIONS(textopt) -wrap none"

    if { $conflict && $revs > 0 } {
        return -code $ERROR_CODES(argerror) "Number of CVS revisions <$revs> differs from 0 for '--conflict' option."
    }

    switch -- $diff_option {
        2 {
            # without --diff3 option
 
            switch -- $revs {
                0 {
                    switch -- $DIFF_TYPE {
                        1 {
                            if { $conflict } {
                                # yadt --conflict FILE

                                set filepath $DIFF_FILES(path,$DIFF_TYPE)
                                set DIFF_TYPE [ ::Yadt::Check_Conflict_Type $filepath secondname ]

                                lappend execute_list \
                                    [ list \
                                          ::Yadt::Split_CVS_Conflicts \
                                          $filepath \
                                          $chdir \
                                          $secondname ]
                            } else {
                                # yadt FILE
                                set fname $DIFF_FILES(path,$DIFF_TYPE)
                                set DIFF_TYPE 2
                                lappend execute_list [ list ::Yadt::Prepare_File_Rev $fname 1 ]
                                lappend execute_list [ list ::Yadt::Prepare_File $fname 2 ]
                            }
                        }
                        2 {
                            # yadt FILE1 FILE2
                            set fname1 $DIFF_FILES(path,1)
                            set fname2 $DIFF_FILES(path,2)

                            if { [ file isdirectory $fname1 ] && \
                                     [ file isdirectory $fname2 ] } {
                                return -code $ERROR_CODES(argerror) "Either <$fname1> or <$fname2> must be a plain file."
                            }

                            if [ file isdirectory $fname1 ] {
                                set fname1 [ file join $fname1 [ file tail $fname2 ] ]
                            } elseif [ file isdirectory $fname2 ] {
                                set fname2 [ file join $fname2 [ file tail $fname1 ] ]
                            }
                            lappend execute_list [ list ::Yadt::Prepare_File "$fname1" 1 ]
                            lappend execute_list [ list ::Yadt::Prepare_File "$fname2" 2 ]
                        }
                        3 {
                            # yadt FILE1 FILE2 FILE3
                            # in case of --diff? option is avoided
                            lappend execute_list [ list ::Yadt::Prepare_For_Diff3 ]
                        }
                        default {
                            return -code $ERROR_CODES(argerror) "DIFF-2: Wrong number of files <$DIFF_TYPE> given for the comparison:\
                                it can not be performed for more than three files."
                        }
                    }
                }
                1 {
                    switch -- $DIFF_TYPE {
                        0 {
                            # yadt -r FILE
                            set DIFF_TYPE 2
                            set fname $rev(1)
                            lappend execute_list [ list ::Yadt::Prepare_File_Rev $fname 1 ]
                            lappend execute_list [ list ::Yadt::Prepare_File $fname 2 ]
                        }
                        1 {
                            # yadt -rREV FILE
                            set fname $DIFF_FILES(path,$DIFF_TYPE)
                            set DIFF_TYPE 2
                            lappend execute_list [ list ::Yadt::Prepare_File_Rev $fname 1 $rev(1) ]
                            lappend execute_list [ list ::Yadt::Prepare_File $fname 2 ]
                        }
                        default {
                            return -code $ERROR_CODES(argerror) "DIFF-2: Wrong number of files <$DIFF_TYPE> given for the same CVS revision:\
                                comparison based on CVS revisions can be performed for one file only."
                        }
                    }
                }
                2 {
                    switch -- $DIFF_TYPE {
                        0 {
                            # yadt -rREV -r FILE
                            set DIFF_TYPE 2
                            set fname $rev(2)
                            lappend execute_list [ list ::Yadt::Prepare_File_Rev $fname 1 $rev(1) ]
                            lappend execute_list [ list ::Yadt::Prepare_File_Rev $fname 2 ]
                        }
                        1 {
                            # yadt -rREV1 -rREV2 FILE
                            set fname $DIFF_FILES(path,$DIFF_TYPE)
                            set DIFF_TYPE 2
                            lappend execute_list [ list ::Yadt::Prepare_File_Rev $fname 1 $rev(1) ]
                            lappend execute_list [ list ::Yadt::Prepare_File_Rev $fname 2 $rev(2) ]
                        }
                        default {
                            return -code $ERROR_CODES(argerror) "DIFF-2: Wrong number of files <$DIFF_TYPE> given for <$revs> CVS revisions:\
                                comparison based on CVS revisions can be performed for one file only."
                        }
                    }
                }
                default {
                    return -code $ERROR_CODES(argerror) "Wrong number of CVS revisions <$revs> given."
                }
            }
        }
        3 {
            # --diff3
            switch -- $revs {
                0 {
                    switch -- $DIFF_TYPE {
                        1 {
                            if { $conflict } {
                                # yadt [--diff3] --conflict FILE

                                set filepath $DIFF_FILES(path,$DIFF_TYPE)
                                set DIFF_TYPE [ ::Yadt::Check_Conflict_Type $filepath secondname ]

                                lappend execute_list \
                                    [ list \
                                          ::Yadt::Split_CVS_Conflicts \
                                          $filepath \
                                          $chdir \
                                          $secondname ]
                            } else {
                                # yadt --diff3 FILE
                                set fname $DIFF_FILES(path,$DIFF_TYPE)
                                set DIFF_TYPE 3
                                lappend execute_list [ list ::Yadt::Prepare_File_Rev $fname 1 "HEAD" ]
                                lappend execute_list [ list ::Yadt::Prepare_File_Rev $fname 2 ]
                                lappend execute_list [ list ::Yadt::Prepare_File $fname 3 ]
                            }
                        }
                        3 {
                            # yadt FILE1 FILE2 FILE3
                            lappend execute_list [ list ::Yadt::Prepare_For_Diff3 ]
                        }
                        default {
                            return -code $ERROR_CODES(argerror) "DIFF-3: Wrong number of files <$DIFF_TYPE> given for the comparison."
                        }
                    }
                }
                1 {
                    switch -- $DIFF_TYPE {
                        0 {
                            # yadt --diff3 -r FILE
                            set fname $rev(1)
                            set DIFF_TYPE 3
                            lappend execute_list [ list ::Yadt::Prepare_File_Rev $fname 1 "HEAD" ]
                            lappend execute_list [ list ::Yadt::Prepare_File_Rev $fname 2 ]
                            lappend execute_list [ list ::Yadt::Prepare_File $fname 3 ]
                        }
                        1 {
                            # yadt --diff3 -rREV FILE
                            set fname $DIFF_FILES(path,$DIFF_TYPE)
                            set DIFF_TYPE 3
                            lappend execute_list [ list ::Yadt::Prepare_File_Rev $fname 1 $rev(1) ]
                            lappend execute_list [ list ::Yadt::Prepare_File_Rev $fname 2 ]
                            lappend execute_list [ list ::Yadt::Prepare_File $fname 3 ]
                        }
                        default {
                            return -code $ERROR_CODES(argerror) "DIFF-3: Wrong number of files <$DIFF_TYPE> given for the same CVS revision:\
                                comparison based on CVS revisions can be performed for one file only."
                        }
                    }
                }
                2 {
                    switch -- $DIFF_TYPE {
                        0 {
                            # yadt --diff3 -r FILE -rREV1
                            # yadt --diff3 -rREV1 -r FILE
                            return -code $ERROR_CODES(argerror) "Invalid options: <$argv>\n\
                                Syntaxis like\n\
                                <yadt --diff3 -r FILE -rREV> or\n\
                                <yadt --diff3 -rREV -r FILE> is not supported"
                        }
                        1 {
                            # yadt --diff3 -rREV1 -rREV2 FILE
                            # yadt --diff3 -rREV1 FILE -rREV2
                            # yadt --diff3 -rREV1 FILE -r
                            # yadt --diff3 FILE -rREV1 -rREV2
                            # yadt --diff3 FILE -rREV -r
                            # yadt --diff3 FILE -r -rREV
                            set fname $DIFF_FILES(path,$DIFF_TYPE)
                            set DIFF_TYPE 3
                            set file_found 0
                            for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
                                if { $rev_order($i) == $fname } {
                                    if { $file_found } {
                                        return -code $ERROR_CODES(argerror) "Invalid options: <$argv>"
                                    }
                                    lappend execute_list [ list ::Yadt::Prepare_File $fname $i ]
                                    set file_found 1
                                } else {
                                    lappend execute_list [ list ::Yadt::Prepare_File_Rev $fname $i $rev_order($i) ]
                                }
                            }
                        }
                        default {
                            return -code $ERROR_CODES(argerror) "DIFF-3: Wrong number of files <$DIFF_TYPE> given for <$revs> CVS revisions:\
                                comparison based on CVS revisions can be performed for one file only."
                        }
                    }
                }
                3 {
                    switch -- $DIFF_TYPE {
                        0 {
                            # yadt --diff3 -rREV1 -rREV2 -r FILE
                            # yadt --diff3 -rREV1 -r FILE -rREV2
                            # yadt --diff3 -r FILE -rREV1 -rREV2
                            return -code $ERROR_CODES(argerror) "Invalid options: <$argv>\n\
                                Syntaxis like\n\
                                <yadt --diff3 -rREV1 -rREV2 -r FILE> or\n\
                                <yadt --diff3 -rREV1 -r FILE -rREV2> or\n\
                                <yadt --diff3 -r FILE -rREV1 -rREV2> is not supported"
                        }
                        1 {
                            # yadt --diff3 -rREV1 -rREV2 -rREV3 FILE
                            # yadt --diff3 -r -rREV1 -rREV2 FILE
                            # yadt --diff3 -rREV1 -r -rREV2 FILE
                            # yadt --diff3 -rREV1 -rREV2 FILE -r
                            # yadt --diff3 -rREV1 FILE -rREV2 -r
                            # yadt --diff3 FILE -r -rREV1 -rREV2
                            # yadt --diff3 FILE -rREV1 -r -rREV2
                            # yadt --diff3 FILE -rREV1 -rREV2 -r
                            # yadt --diff3 FILE -rREV1 -rREV2 -rREV3

                            set fname $DIFF_FILES(path,$DIFF_TYPE)
                            set DIFF_TYPE 3
                            set file_found 0
                            set j 1
                            for { set i 1 } { $i <= 4 } { incr i } {
                                if { $rev_order($i) != $fname } {
                                    lappend execute_list [ list ::Yadt::Prepare_File_Rev $fname $j $rev_order($i) ]
                                    incr j
                                } else {
                                    if { $file_found } {
                                        return -code $ERROR_CODES(argerror) "Invalid options: <$argv>"
                                    }
                                    set file_found 1
                                }
                            }
                        }
                        default {
                            return -code $ERROR_CODES(argerror) "DIFF3: Wrong number of files <$DIFF_TYPE> given for <$revs> CVS revisions:\
                                comparison based on CVS revisions can be performed for one file only."
                        }
                    }
                }
                default {
                    return -code $ERROR_CODES(argerror) "Wrong number of CVS revisions <$revs> given for <--diff3> option."
                }
            }
        }
    }

    if { $DIFF_TYPE == 2 } {
        set OPTIONS(merge_mode) "normal"
    }

    if { $OPTIONS(merge_mode) ni { normal expert } } {
        set OPTIONS(merge_mode) normal
    }

    set stand_alone [ ::Yadt::Is_Standalone_Call ]

    set OPTIONS(vcs) "files"
    foreach element $execute_list {
        if { [ lindex $element 0 ] == "::Yadt::Prepare_File_Rev" } {
            set fname  [ lindex $element 1 ]
            set OPTIONS(vcs_needed) 1
            ::Yadt::Detect_VCS [ file dirname $fname ]
            break
        }
    }

    if { $OPTIONS(vcs_needed) && $VCS_CMD == "" } {
        set VCS_CMD $OPTIONS(vcs)
        if { $stand_alone && $VCS_CMD == "cvs" } {
            set VCS_CMD [ ::Yadt::Extract_Tool_And_Update_Cmd -$OPTIONS(vcs) ]
        }
    }

    if { $DIFF_CMD == "" } {
        set DIFF_CMD diff
        if { $stand_alone } {
            set DIFF_CMD [ ::Yadt::Extract_Tool_And_Update_Cmd -diff ]
        }
    }

    set MERGE_START 2
    switch -- $DIFF_TYPE {
        2 {
            if [ info exists DIFF_FILES(merge2) ] {
                return -code $ERROR_CODES(argerror) "Invalid parameters specified (merge file is defined for diff2)."
            }
        }
        3 {
            if { [ info exists DIFF_FILES(merge2) ] && ![ info exists DIFF_FILES(merge1) ] } {
                return -code $ERROR_CODES(argerror) "Invalid parameters specified (merge file isn't defined)."
            }
            if ![ info exists DIFF_FILES(merge2) ] {
                set MERGE_START 3
            }
        }
        default {
            # This should not happen
            return -code $ERROR_CODES(error) "Internal error. Incorrect value <$DIFF_TYPE> for 'DIFF_TYPE' variable."
        }
    }

    return $execute_list
}

#===============================================================================

proc ::Yadt::Is_Standalone_Call {} {

    variable ::Yadt::OPTIONS

    if ![ info exists OPTIONS(is_standalone_call) ] {

        set OPTIONS(is_standalone_call) 0

        if { $OPTIONS(is_starkit) } {

            set difftools_path [ file join [ file dirname $OPTIONS(script_path) ] difftools ]

            if [ file isdirectory $difftools_path ] {
                set OPTIONS(difftools_path) $difftools_path
                set OPTIONS(difftools_subdir) .diff_for_yadt
                set OPTIONS(is_standalone_call) 1
            }
        }
    }

    return $OPTIONS(is_standalone_call)
}

#===============================================================================

proc ::Yadt::Extract_Tool_And_Update_Cmd { tool_name } {

    global tcl_platform
    variable ::Yadt::OPTIONS

    if { !$OPTIONS(is_starkit) } return

    if ![ ::Yadt::Is_Standalone_Call ] return

    set tool_name [ string trimleft $tool_name "-" ]

    if { $tool_name ni [ list cvs diff ] } {
        return -code error "Unsupported tool name <$tool_name>"
    }

    set difftools_topdir [ file dirname $::starkit::topdir ]
    if ![ file writable $difftools_topdir ] {
        set difftools_topdir $OPTIONS(tmpdir)
    }
    set tools_path [ file join $difftools_topdir $OPTIONS(difftools_subdir) ]

    set executable $tool_name
    if { $tcl_platform(platform) == "windows" } {
        set executable $executable.exe
    }

    set tools_rc [ file join $OPTIONS(difftools_path) .toolsrc ]
    set file_content [ ::Yadt::Read_File $tools_rc ]

    foreach line [ split $file_content \n ] {
        lassign [ split $line ] name exe
        if { $name == $tool_name } {
            set executable $exe
            break
        }
    }

    return [ ::Yadt::Extract_Tool $executable $tools_path ]
}

#===============================================================================

proc ::Yadt::Extract_Tool { tool path } {

    global tcl_platform
    variable ::Yadt::OPTIONS

    set replace 1

    set src_tool_path [ file join $OPTIONS(difftools_path) $tool ]
    set dest_tool_path [ file join $path $tool ]

    if { [ file exist $dest_tool_path ] && [ file isfile $dest_tool_path ] } {
        set src_file_size  [ file size $src_tool_path ]
        set dest_file_size [ file size $dest_tool_path ]

        if { $src_file_size == $dest_file_size } {
            set replace 0
        }
    }

    if { $replace } {
        if [ catch { 
            file mkdir [ file dirname $dest_tool_path ]
            file copy -force $src_tool_path $dest_tool_path
        } errmsg ] {
            # If copy fails under unix - suppose we work in read only env
            # Therefore, we will use default diff utils found in PATH
            if { $tcl_platform(platform) == "unix" } {
                return $tool
            } else {
                return -code error $errmsg
            }
        }
        if { $tcl_platform(platform) != "windows" } {
            file attributes $dest_tool_path -permissions +x
        }
    }

    return $dest_tool_path
}

#===============================================================================

proc ::Yadt::Is_Tag_Option { option } {

    return [ regexp {^.*tag$} $option ]
}

#===============================================================================

proc ::Yadt::Remove_Key_From_Option { option key } {

    variable ::Yadt::OPTIONS

    array set tmp_opt $OPTIONS($option)

    if [ info exists tmp_opt($key) ] {
        unset tmp_opt($key)
        set OPTIONS($option) [ array get tmp_opt ]
        return 1
    }
    return 0
}

#===============================================================================

proc ::Yadt::Check_Tags_Font { illegal_options } {

    # Only 'textopt' option may accept '-font' option.
    # Reason: all tags must use the same font as the 'textopt' does. It is 
    # necessary to make sure that lines match together in corresponding
    # textual widgets (TEXT_WDG, TEXT_NUM_WDG, TEXT_INFO_WDG).

    variable ::Yadt::OPTIONS
    upvar $illegal_options ill_opt

    set ill_opt {}

    foreach option [ array names OPTIONS ] {
        if [ ::Yadt::Is_Tag_Option $option ] {
            if [ ::Yadt::Remove_Key_From_Option $option -font ] {
                lappend ill_opt $option
            }
        }
    }

    return [ llength $ill_opt ]
}

#===============================================================================

proc ::Yadt::Update_Wm_Title {} {

    global CVS_REVISION
    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::DIFF_FILES
    variable ::Yadt::WDG_OPTIONS
    variable ::Yadt::WIDGETS

    switch -- $DIFF_TYPE {
        2 {
            set WDG_OPTIONS(yadt_rev_title) ": [ file tail $DIFF_FILES(label,1) ] vs.\
                [ file tail $DIFF_FILES(label,2) ]"
        }
        3 {
            set WDG_OPTIONS(yadt_rev_title) ": [ file tail $DIFF_FILES(label,1) ] vs.\
                [ file tail $DIFF_FILES(label,2) ] vs.\
                [ file tail $DIFF_FILES(label,3) ]"
        }
    }

    wm title $WIDGETS(window_name) "$WDG_OPTIONS(yadt_title) $CVS_REVISION $WDG_OPTIONS(yadt_rev_title)"
}

#===============================================================================

proc ::Yadt::Package_Tk_Require_And_Configure {} {

    global tcl_version

    package require Tk

    if { $tcl_version >= 8.5 } {
        package require Ttk
    }

    option add *Text.selectBorderWidth 1
    option add *Button.borderWidth 1
    option add *Label.borderWidth 1
    option add *Menubutton.borderWidth 1
    option add *Panedwindow.sashWidth 3
    option add *Panedwindow.sashRelief raised
}

#===============================================================================

proc ::Yadt::Run {} {

    global argc auto_path argv CVS_REVISION

    variable ::Yadt::WIDGETS
    variable ::Yadt::WDG_OPTIONS
    variable ::Yadt::TEXT_WDG
    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::OPTIONS
    variable ::Yadt::DIFF_FILES

    set Revision ""
    set CVS_REVISION [ lindex [ split "$Revision: 3.263 $" ] 1 ]

    set OPTIONS(is_starkit) 0
    if { ![ catch { package present starkit } ] && [ info exists ::starkit::topdir ] } {
        set OPTIONS(is_starkit) 1
    }

    if { $argc == 1 && $argv == "--version" } {
        puts stdout "Yadt CVS Revision: $CVS_REVISION"
        exit 0
    }

    ::Yadt::Package_Tk_Require_And_Configure
    wm withdraw .

    set OPTIONS(script_path) [ file normalize [ ::Yadt::Make_Absolute_Real_Path [ info script ] ] ]
    set cur_pwd [ file dirname $OPTIONS(script_path) ]
    lappend auto_path $cur_pwd
    lappend auto_path [ file join $cur_pwd tcllib1.18 ]

    set WDG_OPTIONS(yadt_title) "Yadt"

    set WIDGETS(window_name) .yadt
    set WIDGETS(pref) .yadt_pref
    set WIDGETS(help_name) .yadt_help
    set WIDGETS(pref_help) .yadt_pref_help

    package require BWidget 1.8
    package require CmnTools
    package require YaLcs
    package require struct::list

    ::Yadt::Init_Opts
    ::Yadt::Load_Images

    if { $argc == 0 || ( $argc == 1 && $argv == "--usage" ) } {
        ::Yadt::Usage
        exit 0
    }

    if { $argc == 1 && $argv == "--help" } {
        ::Yadt::Show_Help
        tkwait window $WIDGETS(help_name)
        exit 0
    }

    ::Yadt::Init_Graphic
    ::Yadt::Save_Default_Options

    set DIFF_FILES(prepare_files_queue) [ ::Yadt::Parse_Args ]

    if [ catch { ::Yadt::Read_Config_File } errmsg ] {
        ::Yadt::Msg_Box "Warning" \
            "There was an error in processing your config file.\n\
             $WDG_OPTIONS(yadt_title) will still run,\
             but some of your preferences may not be in effect.\n\nFile: <$WDG_OPTIONS(rcfile)>\n\
             Error: <$errmsg>" \
            "ok" \
            "warning"
    }

    switch -- $OPTIONS(translation) {
        "windows" -
        "unix" -
        "auto" {
        }
        default {
            ::Yadt::Msg_Box "Warning" \
                "Unsupported EOL translation is set: <$OPTIONS(translation)>.\
                 \nTranslation type <auto> will be used instead."\
                "ok" \
                "warning"
            set OPTIONS(translation) auto
        }
    }

    ::Yadt::Draw_Toplevel

    if [ ::Yadt::Check_Tags_Font illegal_tags ] {
        ::Yadt::Msg_Box "Warning" \
            "Either in command line or in the configuration file \
             option '-font' is defined for one or more text tags. \
             \n\nSetting font for text tags is forbidden and will be ignored. \
             \n\nOptions in question: \n[ join $illegal_tags \n ]" \
            "ok" \
            "warning"
    }

    ::Yadt::Draw_Carcas

    set wdgs [ concat [ ::Yadt::Get_Diff_Wdg_List ] \
                   [ ::Yadt::Get_Merge_Wdg_List ] ]

    ::Yadt::Watch_Cursor [ concat $WIDGETS(window_name) $wdgs ]

    ::Yadt::Prepare_Files_From_Queue_And_Update_Labels

    bind Text <Tab> { continue }
    bind Text <Shift-Tab> { continue }

    bind $WIDGETS(window_name) <Control-o> ::Yadt::Show_Preferences
    bind $WIDGETS(window_name) <Control-f> ::Yadt::Pack_Find_Bar
    bind $WIDGETS(window_name) <F3> "
        ::Yadt::Pack_Find_Bar
        ::Yadt::Find_In_Text -forward 1
    "
    bind $WIDGETS(window_name) <Shift-F3> "
        ::Yadt::Pack_Find_Bar
        ::Yadt::Find_In_Text -backward 1
    "

    bind $WIDGETS(window_name) <Configure> "
        ::Yadt::Main_Window_Configure_Event
    "

    set WDG_OPTIONS(active_window) $TEXT_WDG(1)

    ::Yadt::Create_Popup_Menu
    ::Yadt::Create_Popup_Merge_Mode_Switch_Menu

    ::Yadt::Toggle_Diff_Lines

    ::Yadt::Configure_Tooltips

    # The following proc looks like a hack, 
    # but I still have no other idea how to disable Paste via Mouse button
    # when text widget state is not disabled
    # At any time we can restore the default behavior 
    # by calling ::Yadt::Enable_Mouse_Paste
    ::Yadt::Disable_Mouse_Paste

    ::Yadt::Start_New_Diff

    update
    ::Yadt::Diff_Center
    ::Yadt::Restore_Cursor [ concat $WIDGETS(window_name) $wdgs ]

    # To establish file event when stdin handler must be called:
    if { $OPTIONS(external_call) } {
        fconfigure stdin -blocking 1 -buffering line -translation auto
        fileevent stdin readable [ list ::Yadt::Yadt_Stdin_Handler ]
    }
}

#===============================================================================

proc ::Yadt::Exit { { err_code 0 } { force 0 } } {

    variable ::Yadt::WIDGETS
    variable ::Yadt::OPTIONS
    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::MERGE_START
    variable ::Yadt::MERGE_TEXT_WDG

    if { !$force } {
        if { [ info exists OPTIONS(preview_shown) ] && $OPTIONS(preview_shown) } {
            set merge_modified 0
            for { set j $MERGE_START } { $j <= $DIFF_TYPE } { incr j } {
                if [ $MERGE_TEXT_WDG($j) edit modified ] {
                    set merge_modified 1
                    break
                }
            }
            if { $merge_modified } {
                set prompt 0
                if [ ::Yadt::Merge_Changed ] {
                    set prompt 1
                    set message "Some merge operations are not saved. Exit anyway?"
                }

                if { !$prompt } {
                    if ![ ::Yadt::Check_Resolved -confl ] {
                        set prompt 1
                        set message "Not all conflicts are marked as resolved!\n\nDo You really want to exit Yadt?"
                    }
                }

                if { $prompt } {
                    if { [ tk_messageBox \
                               -message $message \
                               -title "Warning" \
                               -icon question \
                               -type yesno \
                               -default no \
                               -parent $WIDGETS(window_name) ] != "yes" } {
                        return
                    }
                }
            }
        }
    }

    catch { ::Yadt::Clean_Tmp }

    exit $err_code
}

#===============================================================================

proc ::Yadt::Get_Usage_String { } {

    set me "yadt"

    return "Usage:\n\
        \n$me --usage
        \t- this usage\n\
        \n$me --help
        \t- graphic help\n\
        \n2-Way diffs:\n\
        $me \[<OPTIONS>\] <OLDFILE> <MYFILE>\n\
        \t- compares <OLDFILE> vs. <MYFILE>\n\n\
        $me \[<OPTIONS>\] -r <revision> <FILE>\n\
        \t- compares <revision> CVS revision of <FILE> vs. local <FILE>\n\n\
        $me \[<OPTIONS>\] -r <revision> -r <FILE>\n\
        \t- compares <revision> CVS revision of <FILE> vs. <working> CVS revision of <FILE>\n\n\
        $me \[<OPTIONS>\] -r <revision1> -r <revision2> <FILE>\n\
        \t- compares <revision1> CVS revision of <FILE> vs. <revision2> CVS revision of <FILE>\n\n\
        $me \[<OPTIONS>\] <FILE> -r <revision> -r\n\
        \t- compares <revision> CVS revision of <FILE> vs. <working> CVS revision of <FILE>\n\n\
        $me \[<OPTIONS>\] <FILE> -r -r <revision>\n\
        \t- compares <working> CVS revision of <FILE> vs. <revision> CVS revision of <FILE>\n\n\
        \n3-Way diffs:\n\
        $me \[<OPTIONS>\] \[--diff3\] <OLDFILE> <YOURFILE> <MYFILE>\n\
        \t- compares <OLDFILE> vs. <YOURFILE> vs. <MYFILE>\n\n\
        $me \[<OPTIONS>\] --diff3 <FILE>\n\
        \t- compares HEAD CVS revision vs. <working> CVS revision vs. local <FILE>\n\n\
        $me \[<OPTIONS>\] --diff3 -r <revision1> -r <revision2> -r <revision3> <FILE>\n\
        \t- compares <revision1> CVS revision of <FILE> vs. <revision2> CVS revision of <FILE> vs. <revision3> CVS revision of <FILE>\n\n\
        $me \[<OPTIONS>\] --diff3 -r <revision1> <FILE> -r <revision2>\n\
        \t- compares <revision1> CVS revision of <FILE> vs. local <FILE> vs. <revision2> CVS revision of <FILE>\n\n\
        $me \[<OPTIONS>\] --diff3 <FILE> -r <revision1> -r <revision2>\n\
        \t- compares local <FILE> vs. <revision1> CVS revision of <FILE> vs. <revision2> CVS revision of <FILE>\n\n\
        $me \[<OPTIONS>\] --diff3 <FILE> -r <revision1> -r <revision2> -r\n\
        \t- compares <revision1> CVS revision of <FILE> vs. <revision2> CVS revision of <FILE> vs. <working> CVS revision of <FILE>\n\n\
        \nCVS-conflicts for a file:\n\
        $me \[<OPTIONS>\] --conflict <FILE>\n\
        \t- Check <FILE> with conflict markers\n\n\
        Where <OPTIONS> can be:\n\
        \t --merge <MERGE_FILE>\n\
        \t\t- specify the name of merge file\n\n\
        \t --initline <line>\n\
        \t\t- specify the initline where to go after $me is started\n\n\
        \t --chdir <dir>\n\
        \t\t- if necessary specify the directory where files to be compared are located in\n\n\
        \t --diff-cmd <diff path>\n\
        \t\t- if necessary specify the alternative diff utility path\n\n\
        \t --cvs-cmd <cvs path>\n\
        \t\t- if necessary specify the alternative directory where cvs util is located\n\n\
        \t --git-cmd <git path>\n\
        \t\t- if necessary specify the alternative directory where git util is located\n\n\
        \t --d <cvsroot>\n\
        \t\t- if necessary specify the alternative CVS Root\n\n\
        \t --module <cvsmodule>\n\
        \t\t - if necessary specify cvs module. Usually used together with --d parameter.\n\n\
        \t --ge\[ometry\] <width>x<height>\n\
        \t\t- if necessary specify YaDT geometry as, e.g., 800x600\n\n\
        \t --ho\[rizontal\] | --ve\[rtical\]\n\
        \t\t- if necessary specify the $me layout, default - vertical\n\n\
        \t --config <config_file>\n\
        \t\t- if necessary specify path to the $me config file\n\n\
        \t --norc\n\
        \t\t- avoid using $me config file\n\n\
        \t --auto-merge\n\
        \t\t- for 3-way merge, try to resolve conflicts automatically\n\n
        \t--translation <translation>\n\
        \t\t - defines the way of handling line ending (EOL) in files being compared. Acceptable values: <windows>, <unix> or <auto>\n\n
        \t--merge_mode <merge_mode>\n\
         \t\t - defines a 3-way merge mode. Acceptable values: <normal> or <expert>. Default is <normal>"
}

#===============================================================================

proc ::Yadt::Usage { } {

    global CVS_REVISION
    variable ::Yadt::WDG_OPTIONS
    variable ::Yadt::MAP_COLOR

    set title "$WDG_OPTIONS(yadt_title) $CVS_REVISION Usage"

    set out_msg "$WDG_OPTIONS(yadt_title) $CVS_REVISION [ ::Yadt::Get_Usage_String ]"

    if ![ array size MAP_COLOR ] {
        ::Yadt::Init_Graphic
    }

    ::Yadt::Msg_Box $title $out_msg "ok" "info"
}

#===============================================================================

proc ::Yadt::Init_Tmp_Dir {} {

    variable ::Yadt::OPTIONS
    global tcl_platform env

    set OPTIONS(tmpdir) ""
    foreach tmp_dir [ list TMP TEMP TMPDIR ] {
        if { [ info exists env($tmp_dir) ] && $env($tmp_dir) != "" } {
            set OPTIONS(tmpdir) $env($tmp_dir)
            break
        }
    }

    if { $OPTIONS(tmpdir) == "" } {
        switch -- $tcl_platform(platform) {
            windows {
                if [ info exists env(SystemRoot) ] {
                    set tmp_dir [ file join $env(SystemRoot) temp ]
                    if { [ file isdirectory $tmp_dir ] && [ file writable $tmp_dir ] } {
                        set OPTIONS(tmpdir) $tmp_dir
                    }
                }
            }
            default {
                set OPTIONS(tmpdir) /tmp
            }
        }
    }

    if { $OPTIONS(tmpdir) == "" } {
        # actually your OS should be very broken if you get here
        return -code error "Could'n determine temp directory"
    }
}

#===============================================================================

proc ::Yadt::Init_Opts {} {

    variable ::Yadt::OPTIONS
    variable ::Yadt::WDG_OPTIONS
    variable ::Yadt::MAP_TITLE
    variable ::Yadt::MAP_TITLE_SHORT
    global tcl_platform

    ::Yadt::Init_Tmp_Dir

    switch -- $tcl_platform(platform) {
        windows {
            if { [ info exists ::env(path) ] && [ llength $::env(path) ] } {
                append ::env(path) ";[ file join C:/ usr local wbin ]"
            } else {
                set ::env(path) [ file join C:/ usr local wbin ]
            }
            set WDG_OPTIONS(basercfile) "_yadt.rc"
        }
        default {
            set WDG_OPTIONS(basercfile) ".yadtrc"
        }
    }

    # use_cvs_diff - defines the way of file retrieving and diffing
    # For CVS this option has sense only when comparing two files.
    # When comparing three files this option is always treated as set to 0
    #
    # if use_cvs_diff = 0
    #     we retrieve all files from VCS to tmp dir and run "diff" or "diff3" on them
    # if use_cvs_diff = 1
    #     we do not retrieve files, just load their content to widgets and then
    #     For CVS: run "cvs diff" to get diff information
    #         Note: - actual only for diff2,
    #                 for diff3 - use_cvs_diff = 0 will be used anyway
    #               - local copy of repository is mandatory;
    #               - if called outside of local repository dir - use --chdir
    #                 to get there, otherwise "cvs diff" will fail.
    #
    # cvs_ver_from_entry - the way of determining working CVS version
    #     1 - from CVS/Entries file
    #     0 - from "cvs status" output
    # Note: any operation with cvs can slow down the whole YaDT execution time
    #
    # Paramater merge_mode accepts the following values: normal, expert
    array set OPTIONS {
        autocenter   1
        automerge    0
        ignore_blanks 0
        cvsroot      ""
        cvsmodule   ""
        diff_layout  "vertical"
        geometry     ""
        merge_mode   "normal"
        use_cvs_diff 0
        use_diff     1
        preview_shown   0
        save_always_enabled 1
        show_diff_lines 1
        show_inline 1
        show_tooltips 0
        start_warn_msg  {}
        syncscroll   1
        external_call 0
        taginfo      1
        tagln        1
        tagtext      1
        vcs          ""
        cvs_ver_from_entry 1
    }

    switch -- $tcl_platform(platform) {
        "unix" -
        "windows" {
            set OPTIONS(translation) $tcl_platform(platform)
        }
        default {
            return -code error "Unsupported platform <$tcl_platform(platform)>"
        }
    }

    array set WDG_OPTIONS {
        config_file_path  ""
        counter            0
        initline           0
        initlineno         -1
        mapborder          0
        mapheight          0
        merge1set          0
        merge2set          0
        sourcercfile       1
        thumb_min_height   10
        thumb_height       10
        tempfiles ""
    }

    array set MAP_TITLE {
        1 "A (Base):"
        2 "B:"
        3 "C:"
    }

    array set MAP_TITLE_SHORT {
        1 "A:"
        2 "B:"
        3 "C:"
    }
}

#===============================================================================

proc ::Yadt::Init_Graphic {} {

    variable ::Yadt::OPTIONS
    variable ::Yadt::WDG_OPTIONS
    variable ::Yadt::MAP_COLOR
    global tcl_platform tk_version

    if { $tcl_platform(platform) == "windows" } {
        if { $tk_version >= 8.0 } {
            set OPTIONS(default_font) "{{Lucida Console} 8}"
            # Breaks if you're running
            set OPTIONS(default_title_font) "{ Helvetica 12 bold }"
            # Windows with a mono display.
        } else {
            # These XFDs are from Sun's font alias file
            set OPTIONS(default_font) -misc-fixed-medium-r-normal--14-130-75-75-c-70-iso8859-1
            set OPTIONS(default_title_font) -*-Helvetica-Bold-R-Normal-*-14-*
        }
    } else {
        set OPTIONS(default_font) 6x13
        set OPTIONS(default_title_font) -*-Helvetica-Bold-R-Normal-*-14-*
        # Make menus and buttons prettier
        option add *Font -*-Helvetica-Medium-R-Normal-*-12-*
    }

    if [ regexp "color" [ winfo visual . ] ] {
        array set MAP_COLOR {
            bg,1 "turquoise"
            bg,2 "turquoise4"
            bg,3 "magenta4"
            fg,1 "black"
            fg,2 "white"
            fg,3 "white"
            bg,bytetag "white"
            bg,chgtag "DeepSkyBlue1"
            bg,currtag "blue"
            bg,deltag "IndianRed2"
            bg,difftag "gray"
            bg,instag "SpringGreen3"
            bg,inlinechgtag "DeepSkyBlue1"
            bg,inlineinstag "PaleGreen"
            bg,inlinetag "LightSteelBlue"
            bg,overlaptag "khaki1"
            fg,bytetag "black"
            fg,chgtag "black" 
            fg,currtag "white"
            fg,deltag "black"
            fg,difftag "black"
            fg,instag "black"
            fg,inlinetag "black"
            fg,inlineinstag "black"
            fg,inlinechgtag "black"
            fg,overlaptag "black"
        }

        set tags_list [ subst {
            textopt    "-background white -foreground black -font $OPTIONS(default_font)"
            sel        "-background blue -foreground white"
            currtag    "-background $MAP_COLOR(bg,currtag) -foreground $MAP_COLOR(fg,currtag)"
            textcurrtag   "-borderwidth 2 -relief groove"
            difftag    "-background $MAP_COLOR(bg,difftag) -foreground $MAP_COLOR(fg,difftag)"
            deltag     "-background $MAP_COLOR(bg,deltag) -foreground $MAP_COLOR(fg,deltag)"
            instag     "-background $MAP_COLOR(bg,instag) -foreground $MAP_COLOR(fg,instag)"
            chgtag     "-background $MAP_COLOR(bg,chgtag) -foreground $MAP_COLOR(fg,chgtag)"
            overlaptag "-background $MAP_COLOR(bg,overlaptag) -foreground $MAP_COLOR(fg,overlaptag)"
            bytetag    "-underline 1 -foreground $MAP_COLOR(bg,bytetag) -background $MAP_COLOR(fg,bytetag)"
            inlinetag  "-background $MAP_COLOR(bg,inlinetag) -foreground $MAP_COLOR(fg,inlinetag)"
            inlineinstag "-background $MAP_COLOR(bg,inlineinstag) -foreground $MAP_COLOR(fg,inlineinstag)"
            inlinechgtag "-background $MAP_COLOR(bg,inlinechgtag) -foreground $MAP_COLOR(fg,inlinechgtag)"
            merge1tag  "-background $MAP_COLOR(bg,1) -foreground $MAP_COLOR(fg,1)"
            merge2tag  "-background $MAP_COLOR(bg,2) -foreground $MAP_COLOR(fg,2)"
            merge3tag  "-background $MAP_COLOR(bg,3) -foreground $MAP_COLOR(fg,3)"
        } ]
    } else {
        array set MAP_COLOR {
            bg,1 "grey82"
            bg,2 "grey64"
            bg,3 "grey48"
            fg,1 "black"
            fg,2 "black"
            fg,3 "black"
        }

        set tags_list [ subst {
            textopt    "-background white -foreground black -font $OPTIONS(default_font)"
            sel        "-background blue -foreground white"
            currtag    "-background black -foreground white"
            textcurrtag   "-borderwidth 2 -relief groove"
            difftag    "-background white -foreground black"
            deltag     "-background black -foreground white"
            instag     "-background black -foreground white"
            inlinetag  "-underline 1"
            inlineinstag "-underline 1"
            inlinechgtag "-underline 1"
            chgtag     "-background black -foreground white"
            overlaptag "-background black -foreground white"
            bytetag    "-underline 1"
            merge1tag  "-background $MAP_COLOR(bg,1) -foreground $MAP_COLOR(fg,1)"
            merge2tag  "-background $MAP_COLOR(bg,2) -foreground $MAP_COLOR(fg,2)"
            merge3tag  "-background $MAP_COLOR(bg,3) -foreground $MAP_COLOR(fg,3)"
        } ]
    }

    # All tag option names (except textopt) must contain the 'tag' substring.
    # It is used to verify list of text options for all tags.
    foreach { tag_name tag_dscr } $tags_list {
        if { $tag_name == "textopt" || $tag_name == "sel" } continue
        if ![ Is_Tag_Option $tag_name ] {
            return -code error "Internal error: <$tag_name> - illegal name of tag option"
        }
    }

    DynamicHelp::configure -background lightyellow -delay 250 -font $OPTIONS(default_font)

    array set OPTIONS $tags_list

    set WDG_OPTIONS(yadt_width) [ expr [ winfo screenwidth . ] * 2 / 3 ]
    set WDG_OPTIONS(yadt_height) [ expr [ winfo screenheight . ] * 2 / 3 ]
    set WDG_OPTIONS(yadt_width_default) $WDG_OPTIONS(yadt_width)
    set WDG_OPTIONS(yadt_height_default) $WDG_OPTIONS(yadt_height)

    set WDG_OPTIONS(yadt_x) [ expr { ( [ winfo screenwidth . ] - $WDG_OPTIONS(yadt_width_default) ) / 2 } ]
    set WDG_OPTIONS(yadt_y) [ expr { ( [ winfo screenheight . ] - $WDG_OPTIONS(yadt_height_default) ) / 2 } ]

    set WDG_OPTIONS(yadt_x_default) $WDG_OPTIONS(yadt_x)
    set WDG_OPTIONS(yadt_y_default) $WDG_OPTIONS(yadt_y)
    set OPTIONS(geometry) $WDG_OPTIONS(yadt_width)x$WDG_OPTIONS(yadt_height)
}

#===============================================================================

proc ::Yadt::Save_Default_Options {} {

    variable ::Yadt::OPTIONS
    variable ::Yadt::DEF_OPTIONS

    foreach key [ array names OPTIONS ] {
        set DEF_OPTIONS($key) $OPTIONS($key)
    }
}

#===============================================================================

proc ::Yadt::Yadt_Stdin_Handler {} {

    if [ eof stdin ]  return

    gets stdin line

    set line [ string trim $line ]
    if { $line == "" } return

    if ![ regexp "^INITLINE: (.+)$" $line dummy initline ] {
        return -code error "Unsupported standard input line: <$line>"
    }

    ::Yadt::Set_Initline $initline
    ::Yadt::Go_To_Initline
}

#===============================================================================

proc ::Yadt::Set_Initline { value } {

    variable ::Yadt::WDG_OPTIONS

    set WDG_OPTIONS(initline) 1

    if { $value != "default" } {
        if { ![ regexp -- {^([0-9]+)([+][0-9]+)?$} $value dummy \
                    WDG_OPTIONS(initlineno) initoffset ] } {
            return -code error "Malformed --initline option"
        }
    } else {
        set WDG_OPTIONS(initlineno) -1
    }
}

#===============================================================================

proc ::Yadt::Go_To_Initline {} {

    variable ::Yadt::WDG_OPTIONS
    variable ::Yadt::WIDGETS

    set diff [ ::Yadt::Find_Diff $WDG_OPTIONS(initlineno) -original ]
    ::Yadt::Set_Diff_Indicator $diff 0 1

    if ![ winfo ismapped $WIDGETS(window_name) ] {
        wm deiconify $WIDGETS(window_name)
    }
    raise $WIDGETS(window_name)
    focus -force $WIDGETS(window_name)
    ::Yadt::Focus_Active_Window
}

#===============================================================================

proc ::Yadt::Wipe {} {

    variable ::Yadt::DIFF2
    variable ::Yadt::DIFF3
    variable ::Yadt::DIFFS
    variable ::Yadt::DIFF_FILES
    variable ::Yadt::DIFF_INT
    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::CURRENT_MERGES
    variable ::Yadt::LCSDATA
    variable ::Yadt::WDG_OPTIONS
    variable ::Yadt::RANGES
    variable ::Yadt::RANGES2DIFF
    variable ::Yadt::DIFF2RANGES

    array unset DIFF_INT
    array unset CURRENT_MERGES
    array unset LCSDATA

    set DIFF_INT(pos) 0
    set DIFF_INT(count) 0

    set DIFF_INT(delta,1) 0
    set DIFF_INT(delta,2) 0
    set DIFF_INT(scrinline,0,1) 0
    set DIFF_INT(scrinline,0,2) 0

    set WDG_OPTIONS(mapheight) -1

    switch -- $DIFF_TYPE {
        2 {
            set DIFF2(diff) ""
        }
        3 {
            array unset DIFF3
            array unset DIFFS
            array unset DIFF_FILES strings,*
            array unset DIFF_FILES test_strings,*
            array unset DIFF_FILES content,*
            set DIFF_INT(delta,3) 0
            set DIFF_INT(scrinline,0,3) 0

            array unset RANGES
            array unset RANGES2DIFF
            array unset DIFF2RANGES
        }
    }
}

#===============================================================================

proc ::Yadt::Prepare_Files_From_Queue_And_Update_Labels {} {

    variable ::Yadt::DIFF_FILES

    foreach cmd_lst $DIFF_FILES(prepare_files_queue) {
        eval $cmd_lst
    }

    ::Yadt::Update_Wm_Title
    ::Yadt::Update_File_Labels
    ::Yadt::Update_Line_By_Line_Widget
}

#===============================================================================

proc ::Yadt::Get_Line_End_Translation {} {

    variable ::Yadt::OPTIONS

    set translation auto
    switch -- $OPTIONS(translation) {
        "windows" {
            set translation crlf
        }
        "unix" {
            set translation lf
        }
        "auto" {
            set translation auto
        }
        default {
            # actually, shouldn't be here as translation is checked in main proc
            return -code error "Unsupported EOL translation: <$OPTIONS(translation)>"
        }
    }
}

#===============================================================================

proc ::Yadt::Load_Files {} {

    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::DIFF_FILES
    variable ::Yadt::TEXT_WDG
    variable ::Yadt::OPTIONS
    variable ::Yadt::WIDGETS

    set translation [ ::Yadt::Get_Line_End_Translation ]

    for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
        if { ![ info exists DIFF_FILES(path,$i) ] && \
                 ![ info exists DIFF_FILES(content,$i) ] } {
            continue
        }

        set DIFF_FILE(content,$i) [ ::Yadt::Get_File_Content $i -translation $translation ]

        # load file in diff widget
        $TEXT_WDG($i) delete 1.0 end
        $TEXT_WDG($i) insert 1.0 $DIFF_FILE(content,$i)

        # In case content recieved from cvs diff,
        # it could have no newline at the end
        if { ![ regexp {\.0$} \
                    [ $TEXT_WDG($i) index "end-1lines lineend" ] ] } {
            $TEXT_WDG($i) insert end "\n"
        }

        if { $i == 1 } {
            ::Yadt::Load_Merge_File $DIFF_FILE(content,1)
        }
        update
    }
}

#===============================================================================

proc ::Yadt::Get_File_Content { i args } {

    variable ::Yadt::DIFF_FILES

    set nonewline   [ ::CmnTools::Get_Arg -nonewline   args -exists ]
    set translation [ ::CmnTools::Get_Arg -translation args -default "auto" ]

    if { $DIFF_FILES(path,$i) == "" } {
        set content $DIFF_FILES(content,$i)
    } else {
        set cmd [ list ::Yadt::Read_File $DIFF_FILES(path,$i) -translation $translation ]
        if { $nonewline } {
            lappend cmd -nonewline
        }
        set content [ eval $cmd ]
    }

    return $content
}

#===============================================================================

proc ::Yadt::Load_Merge_File { content } {

    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::MERGE_START
    variable ::Yadt::MERGE_INFO_WDG
    variable ::Yadt::MERGE_TEXT_WDG

    for { set j $MERGE_START } { $j <= $DIFF_TYPE } { incr j } {
        $MERGE_TEXT_WDG($j) delete 1.0 end
        $MERGE_TEXT_WDG($j) insert 1.0 $content
        $MERGE_TEXT_WDG($j) edit modified 0

        if { ![ regexp {\.0$} \
                    [ $MERGE_TEXT_WDG($j) index "end-1lines lineend" ] ] } {
            $MERGE_TEXT_WDG($j) insert end "\n"
        }

        set lines_num($j) [ lindex [ split [ $MERGE_TEXT_WDG($j) index end-1lines ] . ] 0 ]

        set lines {}
        for { set k 1 } { $k < $lines_num($j) } { incr k } {
            append lines " \n"
        }
        $MERGE_INFO_WDG($j) delete 1.0 end
        $MERGE_INFO_WDG($j) insert 1.0 $lines
    }
}

#===============================================================================

proc ::Yadt::Save_Merged_Files { args } {

    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::MERGE_START
    variable ::Yadt::WIDGETS
    variable ::Yadt::OPTIONS
    variable ::Yadt::CURRENT_MERGES

    set force   [ ::CmnTools::Get_Arg -force   args -exists ]
    set type    [ ::CmnTools::Get_Arg -type    args -default yesno ]
    set save_as [ ::CmnTools::Get_Arg -save_as args -default 0 ]

    if { !$force } {
        if ![ ::Yadt::Check_Resolved -confl ] {
            set answer [ tk_messageBox \
                             -message "Not all conflicts are marked as resolved!\n\nDo You really want to save merged file?" \
                             -title "Warning" \
                             -icon warning \
                             -type $type \
                             -default no \
                             -parent $WIDGETS(window_name) ]
            switch -- $answer {
                "yes" {
                }
                "no" {
                    return 1
                }
                "cancel" {
                    return 0
                }
            }
        }
    }

    $WIDGETS(tool_bar).save configure -state disabled

    set status 1

    for { set i 1 } { $i <= [ expr { $DIFF_TYPE - $MERGE_START + 1 } ] } { incr i } {

        if [ ::Yadt::Save_One_Merged_File $i -save_as $save_as ] {
            set status_msg "Merge File Saved"
        } else {
            set status 0
            set status_msg "Merge File Not Saved"
        }
        ::Yadt::Status_Msg menustatus $status_msg
    }

    array set CURRENT_MERGES [ ::Yadt::Save_Current_Merges ]

    $WIDGETS(tool_bar).save configure -state normal

    return $status
}

#===============================================================================

proc ::Yadt::Request_File_Name { ind } {

    variable ::Yadt::DIFF_FILES
    variable ::Yadt::WIDGETS
    variable ::Yadt::OPTIONS

    set file_types {
        { {All Files}         {*} }
    }

    if { $OPTIONS(external_call) } {
        set fname ""
        catch { regsub {\(.*\)$} $DIFF_FILES(path,$ind) "" fname }
    } else {
        set fname $DIFF_FILES(path,$ind)
    }

    set file_ext [ file extension $fname ]
    set file_ext_len [ string length $file_ext ]
    if { $file_ext_len > 0 && $file_ext_len <= 5 } {
        set file_ext_descr "[ string totitle [ string trimleft $file_ext "." ] ] files"
        set file_types [ linsert $file_types 0 [ list "$file_ext_descr" "$file_ext" ] ]
    }

    if [ info exists DIFF_FILES(merge$ind) ] {
        set initial_dir [ file dirname $DIFF_FILES(merge$ind) ]
    } elseif [ info exists ::env(HOME) ] {
        set initial_dir $::env(HOME)
    } else {
        set initial_dir "/"
    }

    set initial_file merged_[ file tail $DIFF_FILES(path,$ind) ]

    while { 1 } {
        set save_file [ tk_getSaveFile \
                            -filetypes $file_types \
                            -initialfile $initial_file \
                            -initialdir $initial_dir \
                            -parent $WIDGETS(window_name) ]

        if { $save_file == "" || [ string trim [ file tail $save_file ] ] != "" } break            
    }

    return $save_file
}

#===============================================================================

proc ::Yadt::Save_One_Merged_File { ind args } {

    variable ::Yadt::DIFF_FILES
    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::MERGE_TEXT_WDG
    variable ::Yadt::MERGE_START
    variable ::Yadt::WDG_OPTIONS

    set file_name [ ::CmnTools::Get_Arg -file_name args -default "" ]
    set save_as   [ ::CmnTools::Get_Arg -save_as   args -default 0 ]

    if { !$WDG_OPTIONS(merge${ind}set) || $save_as } {

        set save_file [ ::Yadt::Request_File_Name $ind ]

        if { [ string length $save_file ] == 0 } {
            return 0
        }

        set WDG_OPTIONS(merge${ind}set) 1
        set DIFF_FILES(merge$ind) $save_file
    }

    if { $file_name == "" } {
        set file_name $DIFF_FILES(merge$ind)
    }

    switch -- $DIFF_TYPE {
        2 {
            set i 2
        }
        3 {
            if { $MERGE_START == $DIFF_TYPE } {
                set i 3
            } else {
                set i [ expr { $DIFF_TYPE - $MERGE_START + $ind } ]
            }
        }
    }

    set dir_name [ file dirname $file_name ]
    if ![ file exists $dir_name ] {
        file mkdir $dir_name
    }
    if ![ file isdirectory $dir_name ] {
        return -code error "Specified directory <$dir_name> is not a directory."
    }

    set f_handle [ open "$file_name" w ]
    set content [ $MERGE_TEXT_WDG($i) get 1.0 end-1lines ]
    puts -nonewline $f_handle $content
    close $f_handle

    $MERGE_TEXT_WDG($i) edit modified 0
    ::Yadt::Update_Merge_Title $i

    return 1
}

#===============================================================================

proc ::Yadt::Save_CVS_Like_Merge_File {} {

    variable ::Yadt::DIFF_INT
    variable ::Yadt::DIFF_FILES
    variable ::Yadt::DIFF3
    variable ::Yadt::TEXT_WDG

    set save_file [ ::Yadt::Request_File_Name 3 ]

    if { [ string trim $save_file ] == "" } return

    set file_ancestor $DIFF_FILES(label,1)
    if [ regexp {^.*\(CVS r(.*)\)$} $file_ancestor dummy revision ] {
        set file_ancestor $revision
    }
    set file1 $DIFF_FILES(label,2)
    if [ regexp {^.*\(CVS r(.*)\)$} $file1 dummy revision ] {
        set file1 $revision
    }
    set file2 $DIFF_FILES(label,3)

    set start_line 1

    set num_diff [ llength [ array names DIFF3 *,which_file ] ]

    set fd [ open $save_file w ]

    for { set i 1 } { $i <= $num_diff } { incr i } {

        # Start diff line
        foreach [ list tmp_start tmp_end dt ] $DIFF_INT($i,scrdiff) {}

        switch -- $DIFF3($i,which_file) {
            0 {
                # Left content
                set add_content "<<<<<<< $file2"

                foreach [ list thisdiff s(3) e(3) type(3) ] \
                    $DIFF_INT($i,3,pdiff) {}
                set add_lines_num [ expr { $e(3) - $s(3) } ]
                if { $type(3) != "a" } {
                    incr add_lines_num
                }

                set content [ join [ lindex [ ::Yadt::Gather_File_Strings_By_Diff_Id $i 3 ] 0 ] \n ]
                if { $content != "" } {
                    append add_content "\n$content"
                }

                # Right content
                append add_content "\n======= $file_ancestor"

                foreach [ list thisdiff s(2) e(2) type(2) ] \
                    $DIFF_INT($i,2,pdiff) {}
                set add_lines_num [ expr { $e(2) - $s(2) } ]
                if { $type(2) != "a" } {
                    incr add_lines_num
                }

                set content [ join [ lindex [ ::Yadt::Gather_File_Strings_By_Diff_Id $i 2 ] 0 ] \n ]
                if { $content != "" } {
                    append add_content "\n$content"
                }

                append add_content "\n>>>>>>> $file1"
            }
            2 {
                # LINES num to add
                foreach [ list thisdiff s(2) e(2) type(2) ] \
                    $DIFF_INT($i,2,pdiff) {}
                set add_lines_num [ expr { $e(2) - $s(2) } ]
                if { $type(2) != "a" } {
                    incr add_lines_num
                }

                set add_content [ join [ lindex [ ::Yadt::Gather_File_Strings_By_Diff_Id $i 2 ] 0 ] \n ]
            }
            1 -
            3 {
                # LINES num to add
                foreach [ list thisdiff s(3) e(3) type(3) ] \
                    $DIFF_INT($i,3,pdiff) {}
                set add_lines_num [ expr { $e(3) - $s(3) } ]
                if { $type(3) != "a" } {
                    incr add_lines_num
                }

                set add_content [ join [ lindex [ ::Yadt::Gather_File_Strings_By_Diff_Id $i 3 ] 0 ] \n ]
            }
        }

        # puts content before diff
        if { $start_line < $tmp_start } {
            set content [ $TEXT_WDG(1) get $start_line.0 ${tmp_start}.0-1char ]
            puts $fd $content
        }

        # puts diff/conflict content
        if { $add_content != "" } {
            puts $fd $add_content
        }

        set start_line [ expr { $tmp_end + 1 } ]
    }

    # puts content after the last diff
    set content [ $TEXT_WDG(1) get $start_line.0 end-1lines ]
    puts -nonewline $fd $content

    close $fd
}

#===============================================================================

proc ::Yadt::Save_And_Exit {} {

    if [ ::Yadt::Save_Merged_Files -type yesnocancel ] {
        ::Yadt::Exit 0 1
    }
}

#===============================================================================



################################################################################
# Diff and merge related procs                                                 #
################################################################################

#===============================================================================

proc ::Yadt::Recompute_Diff_On_Bs_Change {} {

    variable ::Yadt::WIDGETS
    variable ::Yadt::OPTIONS
    variable ::Yadt::TMP_OPTIONS

    $WIDGETS(tool_bar).ignore_blanks configure -state disabled
    ::Yadt::Start_New_Diff_Wrapper
    $WIDGETS(tool_bar).ignore_blanks configure -state normal

    set TMP_OPTIONS(ignore_blanks) $OPTIONS(ignore_blanks)
}

#===============================================================================

proc ::Yadt::Recompute_Diffs {} {

    variable ::Yadt::WIDGETS
    variable ::Yadt::DIFF_INT

    set current_pos $DIFF_INT(pos)
    ::Yadt::Start_New_Diff_Wrapper
    ::Yadt::Set_Diff_Indicator $current_pos 0 1
}

#===============================================================================

proc ::Yadt::Start_New_Diff_Wrapper {} {

    variable ::Yadt::WIDGETS

    set wdgs [ concat [ ::Yadt::Get_Diff_Wdg_List ] \
                   [ ::Yadt::Get_Merge_Wdg_List ] ]

    ::Yadt::Watch_Cursor [ concat $WIDGETS(window_name) $wdgs ]

    ::Yadt::Prepare_Files_From_Queue_And_Update_Labels

    ::Yadt::Start_New_Diff
    ::Yadt::Restore_Cursor [ concat $WIDGETS(window_name) $wdgs ]
}

#===============================================================================

proc ::Yadt::Start_New_Diff {} {

    variable ::Yadt::WIDGETS
    variable ::Yadt::WDG_OPTIONS
    variable ::Yadt::OPTIONS

    ::Yadt::Enable_Num_Wdg
    ::Yadt::Enable_Info_Wdg
    ::Yadt::Enable_Merge_Info_Wdg

    ::Yadt::Wipe
    ::Yadt::Load_Files

    if [ llength $OPTIONS(start_warn_msg) ] {
        set msg [ join $OPTIONS(start_warn_msg) \n ]
        tk_messageBox \
            -message $msg \
            -type ok \
            -icon warning \
            -title "Warning" \
            -parent $WIDGETS(window_name)
    }

    ::Yadt::Do_Diff
    after 1000 { ::Yadt::Status_Msg menustatus "" }
    update

    ::Yadt::Go_To_Initline

    ::Yadt::Disable_Num_Wdg
    ::Yadt::Disable_Info_Wdg
    ::Yadt::Disable_Merge_Info_Wdg

    ::Yadt::Bind_Events

    if { $OPTIONS(automerge) } {
        ::Yadt::Auto_Merge3
    }
    ::Yadt::Focus_Active_Window
}

#===============================================================================

proc ::Yadt::Do_Diff {} {

    ::Yadt::Status_Msg menustatus "Calculating differences. Please Wait..."
    ::Yadt::Exec_Diff
    ::Yadt::Status_Msg menustatus "Calculating differences. Please Wait...Done"
    ::Yadt::Update_Num_Lines
    ::Yadt::Add_Lines
    ::Yadt::Mark_Diffs
    ::Yadt::Map_Resize
}

#===============================================================================

proc ::Yadt::Exec_Diff {} {

    variable ::Yadt::DIFF_FILES
    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::OPTIONS
    variable ::Yadt::DIFF2

    set file_check 0
    switch -- $OPTIONS(vcs) {
        "cvs" {
            if { $DIFF_TYPE == 3 || !$OPTIONS(use_cvs_diff) } {
                set file_check 1
            }
        }
        "git" {
            set file_check 1
        }
        "files" {
            set file_check 1
        }
        default {
            return -code error "Sorry, VCS <$OPTIONS(vcs)> not yet supported."
        }
    }

    if { $file_check } {
        for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
            if ![ info exists DIFF_FILES(path,$i) ] {
                return -code error "Internal error. Variable DIFF_FILES(path,$i) does not exist."
            }
            if { $DIFF_FILES(path,$i) == "" } {
                return -code error "Empty file path for <$i> file."
            }
        }
    }

    switch -- $DIFF_TYPE {
        2 {
            if { $OPTIONS(vcs) == "cvs" && $OPTIONS(vcs_needed) && $OPTIONS(use_cvs_diff) } {
                ::Yadt::CVS_Diff
            } else {
                set DIFF2(diff) [ ::Yadt::Exec_Diff2 1 2 ]
            }
        }
        3 {
            ::Yadt::Exec_Diff3
        }
        default {
            return -code error "Incorrect compare type: $DIFF_TYPE"
        }
    }
}

#===============================================================================

proc ::Yadt::Exec_Diff2 { id1 id2 { upvar_lcsdata "" } } {

    variable ::Yadt::DIFF_CMD
    variable ::Yadt::DIFF_IGNORE_SPACES_OPTION
    variable ::Yadt::DIFF_FILES
    variable ::Yadt::OPTIONS
    variable ::Yadt::DIFF_TYPE

    if { $upvar_lcsdata != "" } {
        upvar $upvar_lcsdata lcsdata
    }

    if { $OPTIONS(use_diff) } {
        set diff_stdout ""

        set cmd [ list $DIFF_CMD ]
        if { $OPTIONS(ignore_blanks) } {
            lappend cmd $DIFF_IGNORE_SPACES_OPTION
        }
        lappend cmd -- $DIFF_FILES(path,$id1) $DIFF_FILES(path,$id2)

        set result [ ::Yadt::Execute_Cmd $cmd ]

        lassign $result diff_stdout stderr exitcode

        if { $exitcode < 0 || $exitcode > 1 || $stderr != "" } {
            return -code error "Diff-utility failed:\nExitcode: <$exitcode>\nError message: <$stderr>"
        }

        set diffs [ ::Yadt::Analyze_Out_Diff2 $diff_stdout -diff ]

        if { $DIFF_TYPE == 2 } {
            return $diffs
        }

        ::Yadt::Get_File_Strings $id1 $id2

        set len($id1) [ llength $DIFF_FILES(strings,$id1) ]
        set len($id2) [ llength $DIFF_FILES(strings,$id2) ]

        set lcsdata [ ::YaLcs::Convert_Diff2_To_Lcs_Data $diffs $id1 $id2 $len($id1) $len($id2) ]

        while {1} {
            set test_lcsdata [ ::YaLcs::Try_To_Split_Diffs \
                                   $diffs $id1 $id2 $lcsdata \
                                   $DIFF_FILES(strings,$id1) $DIFF_FILES(strings,$id1) ]
            if { $test_lcsdata == $lcsdata } {
                break
            }
            set lcsdata $test_lcsdata
            set diffs [ ::YaLcs::Convert_Lcs_Data_To_Diff2 $lcsdata $len($id1) $len($id2) ]
        }
    } else {
        # Even in case we do not have diff, we can compare files manually
        # Although, in some cases performance is not good, see
        # ::struct::list::LlongestCommonSubsequence2 description for details
        set diffs [ ::YaLcs::Compare2 $id1 $id2 lcsdata ]
    }

    return $diffs
}

#===============================================================================

proc ::Yadt::Exec_Diff3 {} {

    variable ::Yadt::DIFFS
    variable ::Yadt::DIFF3
    variable ::Yadt::LCSDATA

    set DIFFS(12) [ ::Yadt::Exec_Diff2 1 2 LCSDATA(12) ]
    set DIFFS(13) [ ::Yadt::Exec_Diff2 1 3 LCSDATA(13) ]
    set DIFFS(13) [ ::Yadt::Exec_Diff2 2 3 LCSDATA(23) ]

    set LCSDATA(unchanged) [ ::YaLcs::Find_Unchanged_Diff3_Lines_From_Lcs_Data LCSDATA ]
}

#===============================================================================

proc ::Yadt::CVS_Diff {} {

    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::DIFF_FILES
    variable ::Yadt::OPTIONS
    variable ::Yadt::VCS_CMD
    variable ::Yadt::DIFF_IGNORE_SPACES_OPTION

    set cmd $VCS_CMD

    if { $OPTIONS(cvsroot) != "" } {
        lappend cmd -d $OPTIONS(cvsroot)
    }

    lappend cmd diff
    if { $OPTIONS(ignore_blanks) } {
        lappend cmd $DIFF_IGNORE_SPACES_OPTION
    }

    for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
        if [ info exists DIFF_FILES(rev,$i) ] {
            lappend cmd -r $DIFF_FILES(rev,$i)
        }
    }

    lappend cmd $DIFF_FILES(filename,1)

    set result [ ::Yadt::Run_Cmd_As_Pipe $cmd ]

    lassign $result diff_stdout stderr exitcode

    ::Yadt::Ignore_No_CVS_Tag_Error stderr

    if { $exitcode < 0 || $exitcode > 1 || [ regexp "diff aborted" $stderr ] } {
        return -code error "Diff-utility failed:\nExitcode: <$exitcode>\nError message: <$stderr>"
    }

    set diffs [ ::Yadt::Analyze_Out_Diff2 $diff_stdout -cvs ]

    return $diffs
}

#===============================================================================

proc ::Yadt::Analyze_Out_Diff2 { content from } {

    variable ::Yadt::DIFF_FILES

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
                set found_fname ""
                regexp "Index: (.*)" [ lindex $lines 0 ] dummy found_fname
                if { $found_fname == "" || \
                         [ file nativename $found_fname ] != \
                         [ file nativename $DIFF_FILES(filename,1) ] } {
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

proc ::Yadt::Update_Num_Lines {} {

    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::TEXT_WDG
    variable ::Yadt::TEXT_NUM_WDG
    variable ::Yadt::TEXT_INFO_WDG

    set min_num 0

    for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
        set lines_num($i) [ lindex [ split \
                                         [ $TEXT_WDG($i) index end-1lines ] . ] 0 ]
        if { $min_num == 0 } {
            set min_num $lines_num($i)
        } elseif { $lines_num($i) < $min_num } {
            set min_num $lines_num($i)
        }
    }

    set lines_text {}
    set info_text {}

    for { set i 1 } { $i < $min_num } { incr i } {
        append lines_text "$i\n"
        append info_text " \n"
    }

    for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
        $TEXT_NUM_WDG($i) delete 1.0 end
        $TEXT_INFO_WDG($i) delete 1.0 end

        $TEXT_NUM_WDG($i) insert end $lines_text
        $TEXT_INFO_WDG($i) insert end $info_text
    }

    for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
        set lines_text {}
        set info_text {}
        for { set j $min_num } { $j < $lines_num($i) } { incr j } {
            append lines_text "$j\n"
            append info_text " \n"
        }
        $TEXT_NUM_WDG($i) insert end $lines_text
        $TEXT_INFO_WDG($i) insert end $info_text
    }
}

#===============================================================================

proc ::Yadt::Analyze_Diff2 { line } {
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

proc ::Yadt::Analyze_Diff3 { diff_id file_id line } {

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

proc ::Yadt::Collect_Diff3_From_Lcs { prev_idx_arr idx_arr diff_count } {

    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::DIFF3
    variable ::Yadt::DIFF_INT

    upvar $prev_idx_arr prev_idx
    upvar $idx_arr idx
    upvar $diff_count count

    if { $idx(1) <= [ expr $prev_idx(1) + 1 ] && \
             $idx(2) <= [ expr $prev_idx(2) + 1 ] && \
             $idx(3) <= [ expr $prev_idx(3) + 1 ] } {
        return
    }

    incr count
    for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
        set diff_start($i) [ expr $prev_idx($i) + 2 ]
        set diff_end($i) $idx($i)
        set diff_size($i) [ expr $diff_end($i) - $diff_start($i) + 1 ]

        set op($i) "c"
        if { $diff_size($i) == 0 } {
            set op($i) "a"
            incr diff_start($i) -1
        }

        set ds($i) $diff_start($i)
        if { $diff_end($i) > $diff_start($i) && $op($i) != "a" } {
            append ds($i) ",$diff_end($i)"
        }

        set DIFF3($count,$i,diff) $ds($i)$op($i)
        set DIFF_INT($count,$i,pdiff) \
            [ ::Yadt::Analyze_Diff3 $count $i $DIFF3($count,$i,diff) ]

        foreach [ list DIFF_INT($count,$i,strings) DIFF_INT($count,$i,test_strings) ] \
            [ ::Yadt::Gather_File_Strings_By_Diff_Id $count $i ] { }
    }
    lappend DIFF3(diffs) :$ds(1)$op(1):$ds(2)$op(2):$ds(3)$op(3)

    set DIFF3($count,which_file) [ ::Yadt::Find_Which_File_For_Diff_Id $count ]
}

#===============================================================================

proc ::Yadt::Find_Which_File_For_Diff_Id { diff_id } {

    variable ::Yadt::DIFF_INT

    if { $DIFF_INT($diff_id,1,strings) == $DIFF_INT($diff_id,2,strings) } {
        return 3
    }
    if { $DIFF_INT($diff_id,1,strings) == $DIFF_INT($diff_id,3,strings) } {
        return 2
    }
    if { $DIFF_INT($diff_id,2,strings) == $DIFF_INT($diff_id,3,strings) } {
        return 1
    }

    return 0
}

#===============================================================================

proc ::Yadt::Align_One_Diff2 { diff_id { id1 1 } { id2 2 } } {

    variable ::Yadt::DIFF_INT
    variable ::Yadt::TEXT_WDG
    variable ::Yadt::TEXT_NUM_WDG
    variable ::Yadt::TEXT_INFO_WDG

    foreach "thisdiff s($id1) e($id1) s($id2) e($id2) type" $DIFF_INT($diff_id,pdiff) { }

    set size($id1) [ expr { $e($id1) - $s($id1) } ]
    set size($id2) [ expr { $e($id2) - $s($id2) } ]

    incr s($id1) $DIFF_INT(delta,$id1)
    incr s($id2) $DIFF_INT(delta,$id2)

    switch -- $type {
        "a" {
            set lefttext " " ;# insert
            set righttext "+"
            set idx $id1
            set count [ expr { $size($id2) + 1 } ]
            incr s($id1)
            incr size($id2)
        }
        "d" {
            set lefttext "-" ;# delete
            set righttext " "
            set idx $id2
            set count [ expr { $size($id1) + 1 } ]
            incr s($id2)
            incr size($id1)
        }
        "c" {
            set lefttext "!" ;# change
            set righttext "!" ;# change
            set idx [ expr { $size($id1) < $size($id2) ? $id1 : $id2 } ]
            set count [ expr { abs($size($id1) - $size($id2)) } ]
            incr size($id1)
            incr size($id2)
        }
    }

    set line [ expr $s($id1) + $size($idx) ]

    for { set i 0 } { $i < $count } { incr i } {
        foreach t_wdg "$TEXT_WDG($idx) $TEXT_INFO_WDG($idx) $TEXT_NUM_WDG($idx)" {
            $t_wdg insert $line.0 "\n"
        }
    }

    incr size($idx) $count
    set e($id1) [ expr { $s($id1) + $size($id1) - 1 } ]
    set e($id2) [ expr { $s($id2) + $size($id2) - 1 } ]
    incr DIFF_INT(delta,$idx) $count

    for { set i $s($id1) } { $i <= $e($id1) } { incr i } {
        $TEXT_INFO_WDG($id1) insert $i.0 $lefttext
        $TEXT_INFO_WDG($id2) insert $i.0 $righttext
    }

    set DIFF_INT($DIFF_INT(count),scrdiff) "$s($id1) $e($id1) $type"

    set DIFF_INT(scrinline,$diff_id,$id1) 0
    set DIFF_INT(scrinline,$diff_id,$id2) 0
    set numlines [ ::CmnTools::MaxN \
                       [ expr { $e($id1) - $s($id1) + 1 } ] \
                       [ expr { $e($id2) - $s($id2) + 1 } ] ]
    for { set i 0 } { $i < $numlines } { incr i } {
        set l($id1) [ expr $s($id1) + $i ]
        set l($id2) [ expr $s($id2) + $i ]
        ::Yadt::Find_Ratcliff_Diff2 $diff_id $l($id1) $l($id2) \
            [ $TEXT_WDG($id1) get $l($id1).0 $l($id1).end ] \
            [ $TEXT_WDG($id2) get $l($id2).0 $l($id2).end ]
    }
}

#===============================================================================

proc ::Yadt::Align_One_Diff3 { diff_id } {

    variable ::Yadt::DIFF_INT
    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::TEXT_WDG

    ::Yadt::Get_Diff3_Ranges_And_Sizes $diff_id thisdiff s e type size change_text

    set scr_start [ expr $s(1) + $DIFF_INT(delta,1) ]

    set scr_diff_size [ ::Yadt::Align_Diff3_Strings $diff_id s e type size change_text ]

    for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
        set DIFF_INT(scrinline,$diff_id,$i) 0
    }

    for { set i 0 } { $i < $scr_diff_size } { incr i } {
        set l1 [ expr $scr_start + $i ]
        set l2 [ expr $scr_start + $i ]
        set l3 [ expr $scr_start + $i ]
        ::Yadt::Find_Ratcliff_Diff3 $diff_id $l1 $l2 $l3 \
            [ $TEXT_WDG(1) get $l1.0 $l1.end ] \
            [ $TEXT_WDG(2) get $l2.0 $l2.end ] \
            [ $TEXT_WDG(3) get $l3.0 $l3.end ]
    }
}

#===============================================================================

proc ::Yadt::Add_Diff3_Info_Strings {} {

    variable ::Yadt::DIFF3

    set num_diff [ llength [ array names DIFF3 *,which_file ] ]

    for { set diff_id 1 } { $diff_id <= $num_diff } { incr diff_id } {
        ::Yadt::Get_Diff3_Ranges_And_Sizes $diff_id thisdiff s e type size change_text
        ::Yadt::Add_Info_Strings_In_Range s size change_text
    }
}

#===============================================================================

proc ::Yadt::Add_Info_Strings_In_Range { start diff_size ch_text } {

    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::TEXT_INFO_WDG

    upvar $start s
    upvar $diff_size size
    upvar $ch_text change_text

    for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
        for { set j 0 } { $j < $size($i) } { incr j } {
            set line($i) [ expr $s($i) + $j ]
            $TEXT_INFO_WDG($i) insert $line($i).0 $change_text($i)
        }
    }
}

#===============================================================================

proc ::Yadt::Get_Diff3_Ranges_And_Sizes { diff_id diff start end diff_type diff_size change_text } {

    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::DIFF_INT
    variable ::Yadt::DIFF3

    upvar $diff thisdiff
    upvar $start s
    upvar $end e
    upvar $diff_size size
    upvar $diff_type type
    upvar $change_text text

    foreach var [ list thisdiff s e size type text ] {
        array unset $var
    }

    for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
        foreach "thisdiff($i) s($i) e($i) type($i)" $DIFF_INT($diff_id,$i,pdiff) { }
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

    if { $DIFF3($diff_id,which_file) == 0 } {
        for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
            set text($i) "?"
        }
    } else {
        foreach [ list text(1) text(2) text(3) ] \
            [ ::Yadt::Get_Diff3_Info_Text $type(1) $type(2) $type(3) ] { }
    }
}

#===============================================================================

proc ::Yadt::Get_Border_Ranges { start diff_size shift } {

    upvar $start s
    upvar $diff_size size
    upvar $shift full_shift

    variable ::Yadt::DIFF_INT

    set shifted_size_max [ ::CmnTools::MaxN \
                               [ expr $size(1) + $full_shift(1) ] \
                               [ expr $size(2) + $full_shift(2) ] \
                               [ expr $size(3) + $full_shift(3) ] ]

    set r_start [ expr $s(1) + $DIFF_INT(delta,1) ]
    set r_end   [ expr $r_start + $shifted_size_max - 1 ]
    return [ list $r_start $r_end ]
}

#===============================================================================

proc ::Yadt::Create_Screen_Ranges { ranges diff_id start end } {

    variable ::Yadt::RANGES
    variable ::Yadt::RANGES2DIFF
    variable ::Yadt::DIFF2RANGES
    variable ::Yadt::DIFF3

    set ranges_ind [ llength [ array names RANGES ] ]

    if { [ llength $ranges ] == 2 && \
             [ lindex $ranges 0 ] == $start && \
             [ lindex $ranges 1 ] == $end && \
             $DIFF3($diff_id,which_file) == 0 } {
        # Split ranges by 1 line
        for { set i $start } { $i <= $end } { incr i } {
            incr ranges_ind
            set RANGES($ranges_ind) [ list $i $i ]
            set RANGES2DIFF($ranges_ind) $diff_id
            lappend DIFF2RANGES($diff_id) $ranges_ind
        }
    } else {
        # Get all ranges inside diff
        set scr_ranges [ ::YaLcs::Split_Region_By_Ranges $start $end $ranges ]
        foreach [ list r_start r_end ] $scr_ranges {
            incr ranges_ind
            set RANGES($ranges_ind) [ list $r_start $r_end ]
            set RANGES2DIFF($ranges_ind) $diff_id
            lappend DIFF2RANGES($diff_id) $ranges_ind
        }
    }
}

#===============================================================================

proc ::Yadt::Get_File_Strings { args } {

     variable ::Yadt::DIFF_FILES

     foreach i $args {
         set DIFF_FILES(content,$i) [ ::Yadt::Get_File_Content $i -translation [ ::Yadt::Get_Line_End_Translation ] -nonewline ]
         set DIFF_FILES(strings,$i) [ split $DIFF_FILES(content,$i) "\n" ]

         set DIFF_FILES(test_strings,$i) {}
         foreach element $DIFF_FILES(strings,$i) {
             set str ""
             set list1 [ regexp -all -inline {\S+|\s+} $element ]
             for { set j 0 } { $j < [ llength $list1 ] } { incr j } {
                 set el [ string trim [ lindex $list1 $j ] ]
                 if { $el == "" } continue
                 append str $el
                 if { $j < [ expr [ llength $list1 ] - 1 ] } {
                     append str " "
                 }
             }
             lappend DIFF_FILES(test_strings,$i) $str
         }
     }
}

#===============================================================================

proc ::Yadt::Gather_File_Strings_By_Diff_Id { diff_id file_num } {

    variable ::Yadt::DIFF_FILES
    variable ::Yadt::DIFF_INT

    foreach [ list thisdiff($file_num) s($file_num) e($file_num) type($file_num) ] \
        $DIFF_INT($diff_id,$file_num,pdiff) { }

    if { $type($file_num) == "a" } {
        return [ list {} {} ]
    }

    set start($file_num) [ expr $s($file_num) - 1 ]
    set end($file_num)   [ expr $e($file_num) - 1 ]

    return [ list \
                 [ lrange $DIFF_FILES(strings,$file_num)      $start($file_num) $end($file_num) ] \
                 [ lrange $DIFF_FILES(test_strings,$file_num) $start($file_num) $end($file_num) ] ]
}

#===============================================================================

proc ::Yadt::Align_Diff3_Strings { diff_id start end diff_type diff_size ch_text } {

    upvar $start s
    upvar $end e
    upvar $diff_size size
    upvar $diff_type type
    upvar $ch_text change_text

    if { [ regexp -all -- "a" $type(1)$type(2)$type(3) ] < 2 } {
        ::Yadt::Prepare_Lcs_Data_For_Diff_id lcsdata $diff_id s
    }

    switch -- $type(1)$type(2)$type(3) {
        "aac" {
            return [ ::Yadt::Align_Two_Third_Empty_Diff3 $diff_id 3 s type size change_text ]
        }
        "aca" {
            return [ ::Yadt::Align_Two_Third_Empty_Diff3 $diff_id 2 s type size change_text ]
        }
        "caa" {
            return [ ::Yadt::Align_Two_Third_Empty_Diff3 $diff_id 1 s type size change_text ]
        }
        "acc" {
            return [ ::Yadt::Align_One_Third_Empty_Diff3 $diff_id 1 lcsdata s type size change_text ]
        }
        "cac" {
            return [ ::Yadt::Align_One_Third_Empty_Diff3 $diff_id 2 lcsdata s type size change_text ]
        }
        "cca" {
            return [ ::Yadt::Align_One_Third_Empty_Diff3 $diff_id 3 lcsdata s type size change_text ]
        }
        "ccc" {
            return [ ::Yadt::Align_Conflict $diff_id lcsdata s type size change_text ]
        }
        "aaa" {
            return -code error "Unexpected diff3 type <$type(1)$type(2)$type(3)>"
        }
    }
}

#===============================================================================

proc ::Yadt::Align_Two_Third_Empty_Diff3 { diff_id id1 start diff_type diff_size ch_text } {

    variable ::Yadt::DIFF_INT
    variable ::Yadt::DIFF_TYPE

    upvar $start s
    upvar $diff_type type
    upvar $diff_size size
    upvar $ch_text change_text

    set ranges {}

    for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
        set full_shift($i) 0
        set scr_line($i) [ expr $s($i) + $DIFF_INT(delta,$i) ]
    }

    foreach { id2 id3 } [ ::YaLcs::Get_Other_Ids $id1 ] { }

    set shift($id1) 0
    set shift($id2) $size($id1)
    set shift($id3) $size($id1)

    ::Yadt::Move_Lines scr_line shift change_text
    for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
        incr full_shift($i) $shift($i)
    }

    foreach { r_start r_end } [ ::Yadt::Get_Border_Ranges s size full_shift ] { }
    lappend ranges $r_start $r_end

    for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
        incr DIFF_INT(delta,$i) $full_shift($i)
    }

    ::Yadt::Create_Screen_Ranges $ranges $diff_id $r_start $r_end
    set DIFF_INT($diff_id,scrdiff) [ list $r_start $r_end $type(1)$type(2)$type(3) ]

    return [ expr $r_end - $r_start + 1 ]
}

#===============================================================================

proc ::Yadt::Align_One_Third_Empty_Diff3 { diff_id id3 lcs start diff_type diff_size ch_text } {

    variable ::Yadt::DIFF_INT
    variable ::Yadt::DIFF_TYPE

    upvar $lcs lcsdata
    upvar $start s
    upvar $diff_type type
    upvar $diff_size size
    upvar $ch_text change_text

    set ranges {}

    for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
        set full_shift($i) 0
    }

    foreach { id1 id2 } [ ::YaLcs::Get_Other_Ids $id3 ] { }

    foreach f_line($id1) $lcsdata($id1$id2,$id1) {
        set idx($id2) [ lsearch $lcsdata($id1$id2,$id1) $f_line($id1) ]
        set f_line($id2) [ lindex $lcsdata($id1$id2,$id2) $idx($id2) ]

        set scr_line($id1) [ expr $f_line($id1) + $DIFF_INT(delta,$id1) + $full_shift($id1) ]
        set scr_line($id2) [ expr $f_line($id2) + $DIFF_INT(delta,$id2) + $full_shift($id2) ]
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

        ::Yadt::Move_Lines scr_line shift change_text
        incr full_shift($id1) $shift($id1)
        incr full_shift($id2) $shift($id2)
    }

    set scr_line($id1) [ expr $s($id1) + $DIFF_INT(delta,$id1) + $size($id1) + $full_shift($id1) ]
    set scr_line($id2) [ expr $s($id2) + $DIFF_INT(delta,$id2) + $size($id2) + $full_shift($id2) ]
    set scr_line($id3) [ expr $s($id3) + $DIFF_INT(delta,$id3) ]

    set max_shift [ ::CmnTools::MaxN \
                        [ expr $size($id1) + $full_shift($id1) ] \
                        [ expr $size($id2) + $full_shift($id2) ] ]

    set shift($id1) [ expr $max_shift - $size($id1) - $full_shift($id1) ]
    set shift($id2) [ expr $max_shift - $size($id2) - $full_shift($id2) ]
    set shift($id3) $max_shift

    ::Yadt::Move_Lines scr_line shift change_text
    for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
        incr full_shift($i) $shift($i)
    }

    foreach { r_start r_end } [ ::Yadt::Get_Border_Ranges s size full_shift ] { }
    ::YaLcs::Append_Border_Ranges ranges $r_start $r_end

    for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
        incr DIFF_INT(delta,$i) $full_shift($i)
    }

    ::Yadt::Create_Screen_Ranges $ranges $diff_id $r_start $r_end
    set DIFF_INT($diff_id,scrdiff) [ list $r_start $r_end $type(1)$type(2)$type(3) ]

    return [ expr $r_end - $r_start + 1 ]
}

#===============================================================================

proc ::Yadt::Align_Conflict { diff_id lcs start diff_type diff_size ch_text } {

    variable ::Yadt::DIFF_INT
    variable ::Yadt::DIFF_TYPE

    upvar $lcs lcsdata
    upvar $start s
    upvar $diff_type type
    upvar $diff_size size
    upvar $ch_text change_text

    set ranges {}

    for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
        set full_shift($i) 0
    }

    set l_start [ ::CmnTools::MinN $s(1) $s(2) $s(3) ]
    set size_max [ ::CmnTools::MaxN \
                       [ expr $s(1) + $size(1) - 1 ] \
                       [ expr $s(2) + $size(2) - 1 ] \
                       [ expr $s(3) + $size(3) - 1 ] ]

    for { set line $l_start } { $line <= $size_max } { incr line } {

        for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
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

        if [ ::YaLcs::Find_Lcs_Corresponding_Lines lcsdata f_line $line ] {

            for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
                if { $f_line($i) != 0 } {
                    set scr_line($i) [ expr $f_line($i) + $DIFF_INT(delta,$i) + $full_shift($i) ]
                }
            }

            set scr_line_max [ ::CmnTools::MaxN $scr_line(1) $scr_line(2) $scr_line(3) ]
            for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
                if { $scr_line($i) != 0 } {
                    set shift($i) [ expr $scr_line_max - $scr_line($i) ]
                }
            }

            ::Yadt::Move_Lines scr_line shift change_text

            for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
                incr full_shift($i) $shift($i)
            }

            for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
                set sh($i) 0
                if { $prev_line($i) != 0 } {
                    set sh($i) [ expr $f_line($i) - $prev_line($i) - 1 ]
                }

                if { $sh($i) > 0 } {
                    ::YaLcs::Combine_Ranges ranges [ expr $prev_scr_line($i) + 1 ] [ expr $scr_line($i) - 1 ]
                }

                set prev_line($i) $f_line($i)
                set prev_scr_line($i) $scr_line($i)

                if { $shift($i) > 0 } {
                    ::YaLcs::Combine_Ranges ranges $scr_line($i) [ expr $scr_line($i) + $shift($i) - 1 ]
                }
            }
        }
    }

    set max_args {}
    for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
        set scr_line($i) [ expr $s($i) + $DIFF_INT(delta,$i) + $size($i) + $full_shift($i) ]
        set shifted_size($i) [ expr $size($i) + $full_shift($i) ]
        lappend max_args $shifted_size($i)
    }

    set shifted_size_max [ eval ::CmnTools::MaxN $max_args ]

    for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
        set shift($i) [ expr $shifted_size_max - $shifted_size($i) ]
        if { $shift($i) > 0 } {
            ::YaLcs::Combine_Ranges ranges $scr_line($i) [ expr $scr_line($i) + $shift($i) - 1 ]
        }
    }

    ::Yadt::Move_Lines scr_line shift change_text
    for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
        incr full_shift($i) $shift($i)
    }

    foreach { r_start r_end } [ ::Yadt::Get_Border_Ranges s size full_shift ] { }
    ::YaLcs::Append_Border_Ranges ranges $r_start $r_end

    for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
        incr DIFF_INT(delta,$i) $full_shift($i)
    }

    ::Yadt::Create_Screen_Ranges $ranges $diff_id $r_start $r_end
    set DIFF_INT($diff_id,scrdiff) [ list $r_start $r_end $type(1)$type(2)$type(3) ]

    return [ expr $r_end - $r_start + 1 ]
}


#===============================================================================

proc ::Yadt::Prepare_Lcs_Data_For_Diff_id { lcs diff_id shift_up } {

    upvar $lcs lcsdata
    upvar $shift_up shift

    foreach { lcsdata(12) lcsdata(13) lcsdata(23) } [ ::Yadt::Get_Bs_Lcs_For_Diff_Id $diff_id ] { }

    set lcsdata(12,1) [ ::YaLcs::Convert_Lcs_Data_To_Line_Nums [ lindex $lcsdata(12) 0 ] $shift(1) ]
    set lcsdata(12,2) [ ::YaLcs::Convert_Lcs_Data_To_Line_Nums [ lindex $lcsdata(12) 1 ] $shift(2) ]

    set lcsdata(13,1) [ ::YaLcs::Convert_Lcs_Data_To_Line_Nums [ lindex $lcsdata(13) 0 ] $shift(1) ]
    set lcsdata(13,3) [ ::YaLcs::Convert_Lcs_Data_To_Line_Nums [ lindex $lcsdata(13) 1 ] $shift(3) ]

    set lcsdata(23,2) [ ::YaLcs::Convert_Lcs_Data_To_Line_Nums [ lindex $lcsdata(23) 0 ] $shift(2) ]
    set lcsdata(23,3) [ ::YaLcs::Convert_Lcs_Data_To_Line_Nums [ lindex $lcsdata(23) 1 ] $shift(3) ]

    unset lcsdata(12)
    unset lcsdata(13)
    unset lcsdata(23)
}

#===============================================================================

proc ::Yadt::Move_Lines { lines shift_up ch_text } {

    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::TEXT_WDG
    variable ::Yadt::TEXT_INFO_WDG
    variable ::Yadt::TEXT_NUM_WDG

    upvar $lines ln
    upvar $shift_up shift
    upvar $ch_text change_text

    for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
        for { set j 0 } { $j < $shift($i) } { incr j } {
            set mv_line $ln($i)
            foreach t_wdg "$TEXT_WDG($i) $TEXT_NUM_WDG($i) $TEXT_INFO_WDG($i)" {
                $t_wdg insert $mv_line.0 "\n"
            }
        }
    }

    ::Yadt::Add_Info_Strings_In_Range ln shift change_text
}

#===============================================================================

proc ::Yadt::Append_Final_Lcs_Lines { nums_up } {

    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::TEXT_WDG
    variable ::Yadt::TEXT_INFO_WDG
    variable ::Yadt::TEXT_NUM_WDG

    upvar $nums_up nums

    set test_nums {}

    for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
        lappend test_nums $nums($i)
    }

    set max_num [ eval ::CmnTools::MaxN $test_nums ]

    for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
        for { set j $nums($i) } { $j < $max_num } { incr j } {
            foreach t_wdg "$TEXT_WDG($i) $TEXT_NUM_WDG($i) $TEXT_INFO_WDG($i)" {
                $t_wdg insert [ expr $j + 1 ].0 "\n"
            }
        }
    }
}

#===============================================================================

proc ::Yadt::Get_Bs_Lcs_For_Diff_Id { diff_id args } {

    variable ::Yadt::DIFF_TYPE

    set ignore_blanks [ ::CmnTools::Get_Arg -ignore_blanks args -default 1 ]

    for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
        foreach "str($i) str_bs($i)" [ ::Yadt::Gather_File_Strings_By_Diff_Id $diff_id $i ] { }
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

proc ::Yadt::Diff_Size { diff_id method } {

    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::OPTIONS

    switch -- $DIFF_TYPE {
        2 {
            return [ ::Yadt::Diff2_Size $diff_id $method ]
        }
        3 {
            switch -- $OPTIONS(merge_mode) {
                normal {
                    return [ ::Yadt::Diff3_Size $diff_id $method ]
                }
                expert {
                    return [ ::Yadt::Range3_Size $diff_id $method ]
                }
            }
        }
    }
}

#===============================================================================

proc ::Yadt::Diff2_Size { diff_id method } {

    variable ::Yadt::DIFF_INT

    foreach { thisdiff s(1) e(1) s(2) e(2) type } $DIFF_INT($diff_id,pdiff) { }

    switch -- $method {
        -1 {
            set lines 0
        }
        1 {
            set lines [ expr { $e(1) - $s(1) + 1 } ]
            if { $type == "a" } {
                incr lines -1
            }
        }
        2 {
            set lines [ expr { $e(2) - $s(2) + 1 } ]
            if { $type == "d" } {
                incr lines -1
            }
        }
        12 -
        21 {
            set lines [ expr { $e(1) - $s(1) + $e(2) - $s(2) + 2 } ]
            if { $type == "a" } {
                incr lines -1
            }
        }
        default {
            return -code error "Internal error: incorrect merge type <$method>\
                in [ lindex [ info level 0 ] 0 ]"
        }
    }

    return $lines
}

#===============================================================================

proc ::Yadt::Diff3_Size { diff_id method } {

    variable ::Yadt::DIFF_INT
    variable ::Yadt::DIFF_TYPE

    for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
        foreach [ list thisdiff($i) s($i) e($i) type($i) ] \
            $DIFF_INT($diff_id,$i,pdiff) { }
    }

    switch -- $method {
        -1 {
            set lines 0
        }
        1 -
        3 -
        2 {
            set lines [ expr { $e($method) - $s($method) + 1 } ]
            if { $type($method) == "a" } {
                incr lines -1
            }
        }

        12 -
        21 {
            set lines [ expr { $e(1) - $s(1) + $e(2) - $s(2) + 2 } ]
            for { set i 1 } { $i <= 2 } { incr i } {
                if { $type($i) == "a" } {
                    incr lines -1
                }
            }
        }

        13 -
        31 {
            set lines [ expr { $e(1) - $s(1) + $e(3) - $s(3) + 2 } ]
            if { $type(1) == "a" } {
                incr lines -1
            }
            if { $type(3) == "a" } {
                incr lines -1
            }
        }

        32 -
        23 {
            set lines [ expr { $e(2) - $s(2) + $e(3) - $s(3) + 2 } ]
            for { set i 2 } { $i <= 3 } { incr i } {
                if { $type($i) == "a" } {
                    incr lines -1
                }
            }
        }

        123 -
        132 -
        213 - 
        231 -
        312 -
        321 {
            set lines [ expr { $e(1) - $s(1) + $e(2) - $s(2) + $e(3) - $s(3) + 3 } ]
            for { set i 1 } { $i <= 3 } { incr i } {
                if { $type($i) == "a" } {
                    incr lines -1
                }
            }
        }
        default {
            return -code error "Internal error: incorrect merge type <$method>\
                in [ lindex [ info level 0 ] 0 ]"
        }
    }

    return $lines
}

#===============================================================================

proc ::Yadt::Range3_Size { diff_id method } {

    variable ::Yadt::RANGES
    variable ::Yadt::TEXT_NUM_WDG

    foreach { start end type } $RANGES($diff_id) { }

    set lines 0

    if { $method == -1 } {
        return $lines
    }

    foreach m [ split $method "" ] {
        incr lines [ ::Yadt::One_Range3_Size $start $end $m ]
    }

    return $lines
}

#===============================================================================

proc ::Yadt::One_Range3_Size { start end method } {

    variable ::Yadt::TEXT_NUM_WDG

    set lines 0

    switch -- $method {
        1 -
        2 -
        3 {
            for { set i $start } { $i <= $end } { incr i } {
                set num_text [ $TEXT_NUM_WDG($method) get $i.0 $i.end ]
                if { $num_text == "" } continue
                incr lines
            }
        }
        default {
            return -code error "Internal error: incorrect merge type <$method>\
                in [ lindex [ info level 0 ] 0 ]"
        }
    }

    return $lines
}

#===============================================================================

proc ::Yadt::Merge2 { new_method args } {

    variable ::Yadt::OPTIONS
    variable ::Yadt::DIFF_INT

    set pos  [ ::CmnTools::Get_Arg -pos  args -default $DIFF_INT(pos) ]
    set mark [ ::CmnTools::Get_Arg -mark args -default 1 ]

    ::Yadt::Merge2_By_Method $new_method -pos $pos -mark $mark
    set DIFF_INT(normal_merge$pos) $new_method

    if { $OPTIONS(autocenter) } {
        ::Yadt::Merge_Center
    }
}

#===============================================================================

proc ::Yadt::Merge2_By_Method { new_method args } {

    variable ::Yadt::DIFF_INT
    variable ::Yadt::MERGE_TEXT_WDG
    variable ::Yadt::MERGE_INFO_WDG
    variable ::Yadt::TEXT_WDG
    variable ::Yadt::DIFF_TYPE

    set diff_id [ ::CmnTools::Get_Arg -pos args -default $DIFF_INT(pos) ]
    set mark [ ::CmnTools::Get_Arg -mark args -default 1 ]

    set oldmethod $DIFF_INT(normal_merge$diff_id)

    if { $oldmethod != -1 } {
        set oldlines 0
        foreach i [ split $oldmethod {} ] {
            incr oldlines [ ::Yadt::Diff_Size $diff_id $i ]
        }

        if { $oldlines > 0 } {
            ::Yadt::Enable_Merge_Info_Wdg
            $MERGE_INFO_WDG(2) delete mark${diff_id} "mark${diff_id}+${oldlines}lines"
            ::Yadt::Disable_Merge_Info_Wdg
            $MERGE_TEXT_WDG(2) delete mark${diff_id} "mark${diff_id}+${oldlines}lines"
            update
        }
    }

    if { $new_method == -1 } {
        # No lines to add
        return
    }

    foreach { start end type } $DIFF_INT($diff_id,scrdiff) { }

    for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
        set new_lines($i) 0
    }

    set newlines 0
    set newtext ""

    foreach i [ split $new_method {} ] {
        set new_lines($i) [ ::Yadt::Diff_Size $diff_id $i ]
        set addtext  [ $TEXT_WDG($i) get $start.0 $start.0+$new_lines($i)lines ]

        incr newlines $new_lines($i)

        if { $newtext == "" } {
            set newtext $addtext
        } else {
            append newtext $addtext
        }
    }

    set info_lines {}

    for { set i 1 } { $i <= $newlines } { incr i } {
        append info_lines " \n"
    }

    $MERGE_TEXT_WDG(2) insert mark${diff_id} $newtext diff
    ::Yadt::Enable_Merge_Info_Wdg
    $MERGE_INFO_WDG(2) insert mark${diff_id} $info_lines diff
    ::Yadt::Disable_Merge_Info_Wdg
    update

    # Coloring merge preview
    ::Yadt::Color_Merge_Tag $diff_id 2 $new_method $new_lines(1) $new_lines(2) 0

    if { $mark } {
        ::Yadt::Enable_Merge_Info_Wdg
        $MERGE_INFO_WDG(2) tag add \
            currtag mark${diff_id} "mark${diff_id}+${newlines}lines"
        ::Yadt::Disable_Merge_Info_Wdg
    }
}

#===============================================================================

proc ::Yadt::Merge3 { target new_method args } {

    variable ::Yadt::OPTIONS
    variable ::Yadt::DIFF_INT

    set pos  [ ::CmnTools::Get_Arg -pos  args -default $DIFF_INT(pos) ]
    set mark [ ::CmnTools::Get_Arg -mark args -default 1 ]

    switch -- $OPTIONS(merge_mode) {
        normal {
            ::Yadt::Merge_Diff3_By_Method $target $new_method -pos $pos -mark $mark
            set DIFF_INT($OPTIONS(merge_mode)_merge$pos,$target) $new_method
        }
        expert {
            ::Yadt::Merge_Range3_By_Method $target $new_method -pos $pos -mark $mark
            set DIFF_INT($OPTIONS(merge_mode)_merge$pos,$target) $new_method
        }
    }

    if { $OPTIONS(autocenter) } {
        ::Yadt::Merge_Center
    }
}

#===============================================================================

proc ::Yadt::Merge_Diff3_By_Method { target new_method args } {

    variable ::Yadt::DIFF_INT
    variable ::Yadt::MERGE_TEXT_WDG
    variable ::Yadt::MERGE_INFO_WDG
    variable ::Yadt::TEXT_WDG
    variable ::Yadt::TEXT_NUM_WDG
    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::OPTIONS

    set diff_id [ ::CmnTools::Get_Arg -pos  args -default $DIFF_INT(pos) ]
    set mark [ ::CmnTools::Get_Arg -mark args -default 1 ]

    ::Yadt::Enable_Merge_Info_Wdg

    # Delete lines for oldmethod if any
    set oldmethod $DIFF_INT($OPTIONS(merge_mode)_merge$diff_id,$target)
    set oldlines [ ::Yadt::Diff_Size $diff_id $oldmethod ]

    if { $oldlines > 0 } {
        $MERGE_INFO_WDG($target) delete mark${target}_${DIFF_INT(pos)} \
            "mark${target}_${DIFF_INT(pos)}+${oldlines}lines"
        $MERGE_TEXT_WDG($target) delete mark${target}_${DIFF_INT(pos)} \
            "mark${target}_${DIFF_INT(pos)}+${oldlines}lines"
    }

    if { $new_method == -1 } {
        # No lines to add
        return
    }

    foreach { start end type } [ ::Yadt::Get_Diff_Scr_Params $diff_id ] { }
    if { $start == -1 && $end == -1 && $type == -1 } return

    # Add lines for new method
    for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
        set new_lines($i) 0
    }

    set newlines 0
    set newtext ""

    foreach i [ split $new_method {} ] {
        set new_lines($i) [ ::Yadt::Diff_Size $diff_id $i ]

        set addtext ""
        for { set j $start } { $j <= $end } { incr j } {
            set num_txt [ $TEXT_NUM_WDG($i) get $j.0 $j.end ]
            if { $num_txt == "" } continue
            append addtext [ $TEXT_WDG($i) get $j.0 $j.0+1lines ]
        }

        incr newlines $new_lines($i)

        if { $newtext == "" } {
            set newtext $addtext
        } else {
            append newtext $addtext
        }
    }

    set info_lines {}

    for { set i 1 } { $i <= $newlines } { incr i } {
        append info_lines " \n"
    }

    # Actually inserting newtext in merge widget
    $MERGE_TEXT_WDG($target) insert mark${target}_${DIFF_INT(pos)} $newtext diff
    $MERGE_INFO_WDG($target) insert mark${target}_${DIFF_INT(pos)} $info_lines diff
    update

    # Coloring merge preview
    ::Yadt::Color_Merge_Tag $diff_id $target $new_method $new_lines(1) $new_lines(2) $new_lines(3)

    if { $mark } {
        $MERGE_INFO_WDG($target) tag add \
            currtag mark${target}_${DIFF_INT(pos)} \
            "mark${target}_${DIFF_INT(pos)}+${newlines}lines"
    }
    ::Yadt::Disable_Merge_Info_Wdg
}

#===============================================================================

proc ::Yadt::Merge_Range3_By_Method { target new_method args } {

    variable ::Yadt::DIFF_INT
    variable ::Yadt::MERGE_TEXT_WDG
    variable ::Yadt::MERGE_INFO_WDG
    variable ::Yadt::TEXT_WDG
    variable ::Yadt::TEXT_NUM_WDG
    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::OPTIONS
    variable ::Yadt::RANGES
    variable ::Yadt::RANGES2DIFF
    variable ::Yadt::DIFF2RANGES

    set diff_id [ ::CmnTools::Get_Arg -pos  args -default $DIFF_INT(pos) ]
    set mark [ ::CmnTools::Get_Arg -mark args -default 1 ]

    ::Yadt::Enable_Merge_Info_Wdg

    # Clean lines at first if we have to
    set oldlines 0
    foreach range $DIFF2RANGES($RANGES2DIFF($diff_id)) {
        set method $DIFF_INT(expert_merge$range,$target)
        if { $method != -1 } {
            foreach i [ split $method {} ] {
                incr oldlines [ ::Yadt::Diff_Size $range $i ]
            }
        }
    }

    if { $oldlines > 0 } {
        $MERGE_INFO_WDG($target) delete mark${target}_$RANGES2DIFF($diff_id) \
            "mark${target}_$RANGES2DIFF($diff_id)+${oldlines}lines"

        $MERGE_TEXT_WDG($target) delete mark${target}_$RANGES2DIFF($diff_id) \
            "mark${target}_$RANGES2DIFF($diff_id)+${oldlines}lines"
    }

    set newlines 0
    set newtext ""

    foreach { start end type } [ ::Yadt::Get_Diff_Scr_Params $diff_id ] { }
    if { $start == -1 && $end == -1 && $type == -1 } return

    foreach range $DIFF2RANGES($RANGES2DIFF($diff_id)) {
        foreach { r_start r_end r_type } $RANGES($range) { }

        set method $DIFF_INT(expert_merge$range,$target)
        if { $r_start == $start && $r_end == $end } {
            set method $new_method
        }

        if { $method == -1 } continue

        foreach i [ split $method {} ] {

            incr newlines [ ::Yadt::Diff_Size $range $i ]

            set addtext ""
            for { set j $r_start } { $j <= $r_end } { incr j } {
                set num_txt [ $TEXT_NUM_WDG($i) get $j.0 $j.end ]
                if { $num_txt == "" } continue
                append addtext [ $TEXT_WDG($i) get $j.0 $j.0+1lines ]
            }

            if { $newtext == "" } {
                set newtext $addtext
            } else {
                append newtext $addtext
            }
        }
    }

    set info_lines {}
    for { set i 1 } { $i <= $newlines } { incr i } {
        append info_lines " \n"
    }

    # Actually inserting newtext in merge widget
    $MERGE_TEXT_WDG($target) insert mark${target}_$RANGES2DIFF($diff_id) $newtext diff
    $MERGE_INFO_WDG($target) insert mark${target}_$RANGES2DIFF($diff_id) $info_lines diff
    update

    # Coloring merge preview
    ::Yadt::Color_Range_Tags_Inside_Diff $target $diff_id $new_method

    if { $mark } {
        set range_size [ ::Yadt::Diff_Size $diff_id $new_method ]
        set offset [ ::Yadt::Get_Range_Offset_Inside_Diff $diff_id $target ]

        set m_start "mark${target}_$RANGES2DIFF($diff_id)+${offset}lines"
        set m_end "mark${target}_$RANGES2DIFF($diff_id)+${offset}lines+${range_size}lines"

        $MERGE_INFO_WDG($target) tag add currtag $m_start $m_end
        if { $OPTIONS(merge_mode) == "expert" } {
            $MERGE_INFO_WDG($target) tag add textcurrtag $m_start $m_end
            $MERGE_TEXT_WDG($target) tag add textcurrtag $m_start $m_end
        }
    }
    ::Yadt::Disable_Merge_Info_Wdg
}

#===============================================================================

proc ::Yadt::Get_Diff_Scr_Params { diff_id } {

    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::OPTIONS
    variable ::Yadt::DIFF_INT
    variable ::Yadt::RANGES

    set start -1
    set end -1
    set type -1

    if { $DIFF_TYPE == 3 && $OPTIONS(merge_mode) == "expert" } {
        if [ info exists RANGES($diff_id) ] {
            foreach [ list start end type ] $RANGES($diff_id) { }
        }
    } else {
        if [ info exists DIFF_INT($diff_id,scrdiff) ] {
            foreach [ list start end type ] $DIFF_INT($diff_id,scrdiff) { }
        }
    }

    return [ list $start $end $type ]
}

#===============================================================================

proc ::Yadt::Color_Merge_Tag { diff_id target method lines1 lines2 lines3 } {

    variable ::Yadt::MERGE_TEXT_WDG
    variable ::Yadt::TEXT_WDG
    variable ::Yadt::DIFF_TYPE

    set offset 0

    foreach i [ split $method {} ] {
        set cur_lines [ set lines$i ]
        if { $cur_lines == 0 } {
            continue
        }

        switch -- $DIFF_TYPE {
            2 {
                set start [ $MERGE_TEXT_WDG($target) dump -mark mark${diff_id} ]
            }
            3 {
                set start [ $MERGE_TEXT_WDG($target) dump -mark mark${target}_$diff_id ]
            }
        }

        set start [ lindex $start 2 ]
        set start [ lindex [ split $start . ] 0 ]

        incr start $offset

        set end [ expr { $start + $cur_lines } ]
        incr offset $cur_lines

        $MERGE_TEXT_WDG($target) tag add \
            merge${i}tag $start.0 $end.0
    }
}

#===============================================================================

proc ::Yadt::Color_Range_Tags_Inside_Diff { target range new_method } {

    variable ::Yadt::RANGES2DIFF
    variable ::Yadt::DIFF2RANGES
    variable ::Yadt::RANGES
    variable ::Yadt::DIFF_INT
    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::MERGE_START
    variable ::Yadt::MERGE_TEXT_WDG

    foreach { start end type } [ ::Yadt::Get_Diff_Scr_Params $range ] { }

    set diff_id $RANGES2DIFF($range)

    for { set j $MERGE_START } { $j <= $DIFF_TYPE } { incr j } {
        set offset($j) 0
    }

    foreach r $DIFF2RANGES($diff_id) {
        array unset lines

        foreach { r_start r_end r_type } $RANGES($r) { }

        set method $DIFF_INT(expert_merge$r,$target)
        if { $r_start == $start && $r_end == $end } {
            set method $new_method
        }
        if { $method == -1 } continue

        foreach i [ split $method {} ] {

            set lines($i) [ ::Yadt::Diff_Size $r $i ]

            set m_start "mark${target}_$diff_id+$offset($target)lines"
            set m_end "mark${target}_$diff_id+$offset($target)lines+$lines($i)lines"

            $MERGE_TEXT_WDG($target) tag add merge${i}tag $m_start $m_end
            update
            incr offset($target) $lines($i)
        }
    }
}
    
#===============================================================================

proc ::Yadt::Merge_All { target new_method } {

    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::WIDGETS

    set wdgs [ concat [ ::Yadt::Get_Diff_Wdg_List ] \
                   [ ::Yadt::Get_Merge_Wdg_List ] ]

    ::Yadt::Watch_Cursor [ concat $WIDGETS(window_name) $wdgs ]

    switch -- $DIFF_TYPE {
        2 {
            ::Yadt::Merge2_All $new_method
        }
        3 {
            ::Yadt::Merge3_All $target $new_method
        }
    }

    ::Yadt::Restore_Cursor [ concat $WIDGETS(window_name) $wdgs ]
}

#===============================================================================

proc ::Yadt::Merge2_All { new_method } {

    variable ::Yadt::DIFF2
    variable ::Yadt::DIFF_INT

    set num_diff [ llength $DIFF2(diff) ]

    for { set i 1 } { $i <= $num_diff } { incr i } {
        ::Yadt::Merge2 $new_method -pos $i -mark 0
        set DIFF_INT(normal_merge$i) $new_method
    }

    ::Yadt::Set_Diff_Indicator $DIFF_INT(pos) 0 1
}

#===============================================================================

proc ::Yadt::Merge3_All { target new_method } {

    variable ::Yadt::DIFF3
    variable ::Yadt::DIFF_INT
    variable ::Yadt::OPTIONS
    variable ::Yadt::RANGES

    switch -- $OPTIONS(merge_mode) {
        normal {
            set num_diff [ llength [ array names DIFF3 *,which_file ] ]
        }
        expert {
            set num_diff [ llength [ array names RANGES ] ]
        }
    }

    for { set i 1 } { $i <= $num_diff } { incr i } {
        ::Yadt::Merge3 $target $new_method -pos $i -mark 0
        set DIFF_INT($OPTIONS(merge_mode)_merge$i,$target) $new_method
        set DIFF_INT($i,$target,$OPTIONS(merge_mode)_resolved) 1
    }

    ::Yadt::Set_Diff_Indicator $DIFF_INT(pos) 0 1
}

#===============================================================================

proc ::Yadt::Change_Layout {} {

    variable ::Yadt::WIDGETS
    variable ::Yadt::OPTIONS
    variable ::Yadt::TMP_OPTIONS

    switch -- $OPTIONS(diff_layout) {
        "vertical" {
            set orient "horizontal"
        }
        "horizontal" {
            set orient "vertical"
        }
    }

    ::Yadt::Yadt_Paned -configure $WIDGETS(diff_paned) -orient $orient

    set TMP_OPTIONS(diff_layout) $OPTIONS(diff_layout)
}

#===============================================================================

proc ::Yadt::Save_Current_Merges {} {

    variable ::Yadt::DIFF_TYPE

    switch -- $DIFF_TYPE {
        2 {
            return [ ::Yadt::Save_Current_Merges2 ]
        }
        3 {
            return [ ::Yadt::Save_Current_Merges3 ]
        }
    }
}

#===============================================================================

proc ::Yadt::Save_Current_Merges2 {} {

    variable ::Yadt::DIFF2
    variable ::Yadt::DIFF_INT
    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::MERGE_START

    array unset current_merges

    set num_diff [ llength $DIFF2(diff) ]

    for { set i 1 } { $i <= $num_diff } { incr i } {
        set current_merges(merge$i) $DIFF_INT(normal_merge$i)
    }

    return [ array get current_merges ]
}

#===============================================================================

proc ::Yadt::Save_Current_Merges3 {} {

    variable ::Yadt::DIFF3
    variable ::Yadt::DIFF_INT
    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::MERGE_START
    variable ::Yadt::OPTIONS
    variable ::Yadt::RANGES

    array unset current_merges

    switch -- $OPTIONS(merge_mode) {
        normal {
            set num_diff [ llength [ array names DIFF3 *,which_file ] ]
        }
        expert {
            set num_diff [ llength [ array names RANGES ] ]
        }
    }

    for { set i 1 } { $i <= $num_diff } { incr i } {

        for { set j $MERGE_START } { $j <= $DIFF_TYPE } { incr j } {
            set current_merges(merge$i,$j) $DIFF_INT(normal_merge$i,$j)
        }
    }

    return [ array get current_merges ]
}

#===============================================================================

proc ::Yadt::Mark_Resolve_Handle { target item action type { update 1 } } {

    variable ::Yadt::WIDGETS

    set current_label [ $WIDGETS(menu_merge$target) entrycget $WIDGETS(menu_item,merge$target,$item) -label ]

    switch -- $action {
        -mark {
            set new_label [ lreplace $current_label 0 0 "Unmark" ]
            set new_command "::Yadt::Mark_Resolve_Handle $target $item -unmark $type"
            set new_image unmarkImage
        }
        -unmark {
            set new_label [ lreplace $current_label 0 0 "Mark" ]
            set new_command "::Yadt::Mark_Resolve_Handle $target $item -mark $type"
            switch -- $type {
                -current {
                    set new_image markImage
                }
                -all {
                    set new_image markAllImage
                }
                -conflict {
                    set new_image markAllConflictImage
                }
            }
        }
    }

    $WIDGETS(menu_merge$target) entryconfigure $WIDGETS(menu_item,merge$target,$item) \
        -label $new_label \
        -command $new_command \
        -image $new_image

    set WIDGETS(menu_item,merge$target,$item) $new_label

    if { !$update } {
        return
    }

    if { $type == "-current" } {
        $WIDGETS(mark$target) invoke
    } else {
        ::Yadt::Diffs_As_Resolved $target $action $type
        if { $type == "-all" } {
            ::Yadt::Mark_Resolve_Handle $target mark_all_confl_resolved $action -conflict 0
        }
    }
}

#===============================================================================

proc ::Yadt::Diffs_As_Resolved { target action { type -all } } {

    variable ::Yadt::DIFF3
    variable ::Yadt::DIFF_INT
    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::MERGE_START
    variable ::Yadt::OPTIONS
    variable ::Yadt::RANGES
    variable ::Yadt::RANGES2DIFF

    switch -- $OPTIONS(merge_mode) {
        normal {
            set num_diff [ llength [ array names DIFF3 *,which_file ] ]
        }
        expert {
            set num_diff [ llength [ array names RANGES ] ]
        }
    }

    if { $num_diff == 0 } return

    switch -- $action {
        -mark {
            set resolve_value 1
        }
        -unmark {
            set resolve_value 0
        }
        default {
            return -code error "Unknown action <$action> in [ lindex [ info level 0 ] 0 ]"
        }
    }

    for { set i 1 } { $i <= $num_diff } { incr i } {

        switch -- $type {
            -conflict {
                set diff_id $i
                if { $OPTIONS(merge_mode) == "expert" } {
                    set diff_id $RANGES2DIFF($diff_id)
                }
                if { $DIFF3($diff_id,which_file) != 0 } continue
            }
            -all -
            default {
            }
        }
        foreach j [ split $target {} ] {
            set DIFF_INT($i,$j,$OPTIONS(merge_mode)_resolved) $resolve_value
        }
    }
    ::Yadt::Update_Widgets
}

#===============================================================================

proc ::Yadt::Resolve_Diff { diff_id } {

    variable ::Yadt::DIFF3
    variable ::Yadt::DIFF_INT
    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::MERGE_START
    variable ::Yadt::OPTIONS
    variable ::Yadt::RANGES2DIFF

    set pos $diff_id
    if { $OPTIONS(merge_mode) == "expert" } {
        set pos $RANGES2DIFF($diff_id)
    }

    switch -- $DIFF3($pos,which_file) {
        0 {
            # It is a conflict
            set resolve(2) 2
            set resolve(3) 3
            set status 0
        }
        1 {
            # The first file differs -> decision: take the 3rd file fragment
            set resolve(2) 2
            set resolve(3) 3
            set status 1
        }

        2 {
            # The second file differs -> decision: take the 2nd file fragment
            set resolve(2) 2
            set resolve(3) 2
            set status 1
        }

        3 {
            # The third file differs -> decision: take the 3rd file fragment
            set resolve(2) 3
            set resolve(3) 3
            set status 1
        }
        default {
            return -code error "Internal error: Invalid DIFF3 format found: <$DIFF3($diff_id,which_file)>"
        }
    }

    for { set j $MERGE_START } { $j <= $DIFF_TYPE } { incr j } {
        ::Yadt::Merge3 $j $resolve($j) -pos $pos -mark 0
        set DIFF_INT($OPTIONS(merge_mode)_merge$diff_id,$j) $resolve($j)
        set DIFF_INT($diff_id,$j,$OPTIONS(merge_mode)_resolved) $status
    }

    return $status
}

#===============================================================================

proc ::Yadt::Check_Resolved { type { target all } { check_confl_exist "" } { num_diff -1 } } {
    # type: -all or -confl
    variable ::Yadt::DIFF3
    variable ::Yadt::DIFF_INT
    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::MERGE_START
    variable ::Yadt::OPTIONS
    variable ::Yadt::RANGES
    variable ::Yadt::RANGES2DIFF

    if { $check_confl_exist != "" } {
        upvar $check_confl_exist confl_exist
        set confl_exist 0
    }

    set resolved 1

    if { $DIFF_TYPE != 3 } {
        return $resolved
    }

    if { $num_diff == -1 } {
        switch -- $OPTIONS(merge_mode) {
            normal {
                set num_diff [ llength [ array names DIFF3 *,which_file ] ]
            }
            expert {
                set num_diff [ llength [ array names RANGES ] ]
            }
        }
    }

    if { $num_diff == 0 } {
        return $resolved
    }

    for { set i 1 } { $i <= $num_diff } { incr i } {

        set diff_id $i
        if { $OPTIONS(merge_mode) == "expert" } {
            set diff_id $RANGES2DIFF($diff_id)
        }

        if { $target == "all" } {
            for { set j $MERGE_START } { $j <= $DIFF_TYPE } { incr j } {
                if { $type == "-confl" && $DIFF3($diff_id,which_file) != 0 } {
                    continue
                } else {
                    set confl_exist 1
                }
                if { !$DIFF_INT($i,$j,$OPTIONS(merge_mode)_resolved) } {
                    set resolved 0
                    break
                }
            }
        } else {
            if { $type == "-confl" && $DIFF3($diff_id,which_file) != 0 } {
                continue
            } else {
                set confl_exist 1
            }
            if { !$DIFF_INT($i,$target,$OPTIONS(merge_mode)_resolved) } {
                set resolved 0
                break
            }
        }
    }    

    return $resolved
}

#===============================================================================

proc ::Yadt::Merge_Changed {} {

    variable ::Yadt::CURRENT_MERGES
    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::MERGE_START
    variable ::Yadt::DIFF2
    variable ::Yadt::DIFF3

    set modified 0

    if { ![ info exists CURRENT_MERGES ] || ![ array size CURRENT_MERGES ] } {
        return $modified
    }

    array set new_merges [ ::Yadt::Save_Current_Merges ]

    switch -- $DIFF_TYPE {
        2 {
            set num_diff [ llength $DIFF2(diff) ]
            for { set i 1 } { $i<=$num_diff } { incr i } {
                if { $new_merges(merge$i) != $CURRENT_MERGES(merge$i) } {
                    set modified 1
                    break
                }
            }
        }
        3 {
            set num_diff [ llength [ array names DIFF3 *,which_file ] ]
            for { set i 1 } { $i<=$num_diff } { incr i } {
                for { set j $MERGE_START } { $j <= $DIFF_TYPE } { incr j } {
                    if { $new_merges(merge$i,$j) != $CURRENT_MERGES(merge$i,$j) } {
                        set modified 1
                        break
                    }
                }
            }
        }
    }

    return $modified
}

#===============================================================================

proc ::Yadt::Auto_Merge3 {} {

    variable ::Yadt::DIFF3
    variable ::Yadt::DIFF_INT
    variable ::Yadt::OPTIONS
    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::MERGE_START
    variable ::Yadt::WIDGETS
    variable ::Yadt::RANGES

    if { $DIFF_TYPE != 3 } return

    switch -- $OPTIONS(merge_mode) {
        normal {
            set num_diff [ llength [ array names DIFF3 *,which_file ] ]
            set units "Differences"
        }
        expert {
            set num_diff [ llength [ array names RANGES ] ]
            set units "Ranges"
        }
    }

    if { $num_diff == 0 } return

    set wdgs [ concat [ ::Yadt::Get_Diff_Wdg_List ] \
                   [ ::Yadt::Get_Merge_Wdg_List ] ]

    ::Yadt::Watch_Cursor [ concat $WIDGETS(window_name) $wdgs ]

    set num_resolved 0
    set num_conflicts 0

    set saved_pos $DIFF_INT(pos)

    for { set i 1 } { $i <= $num_diff } { incr i } {
        if [ ::Yadt::Resolve_Diff $i ] { 
            incr num_resolved 
        } else { 
            incr num_conflicts 
        }
    }

    set DIFF_INT(pos) $saved_pos

    ::Yadt::Set_Diff_Indicator $DIFF_INT(pos) 0
    ::Yadt::Update_Widgets

    if { $num_conflicts } {
        ::Yadt::Goto_Conflict 1
    }

    set msg "\tAuto merge finished:\n\n\
                  $num_diff\tTotal Number of $units\n\n\
                  $num_resolved\t$units Resolved\n\
                  $num_conflicts\tConflicts Found"

    if { !$OPTIONS(preview_shown) } {
        append msg "\n\nTo see the result, press merge preview window button."
    }

    tk_messageBox \
        -title "Auto merge result" \
        -icon info \
        -type ok \
        -message $msg \
        -parent $WIDGETS(window_name)

    ::Yadt::Restore_Cursor [ concat $WIDGETS(window_name) $wdgs ]

    return [ list $num_resolved $num_conflicts ]
}

#===============================================================================


################################################################################
# Mark procs                                                                   #
################################################################################

#===============================================================================

proc ::Yadt::Mark_Diffs {} {

    ::Yadt::Clear_Mark_Diffs
    ::Yadt::Prepare_Mark_Diffs
    ::Yadt::Update_Merge_Marks
    ::Yadt::Set_All_Tags
    ::Yadt::Define_Tags_Priority
}

#===============================================================================

proc ::Yadt::Clear_Mark_Diffs {} {

    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::TEXT_WDG
    variable ::Yadt::TEXT_NUM_WDG
    variable ::Yadt::TEXT_INFO_WDG

    for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
        eval $TEXT_WDG($i) tag delete [ $TEXT_WDG($i) tag names ]
        eval $TEXT_NUM_WDG($i) tag delete [ $TEXT_NUM_WDG($i) tag names ]
        eval $TEXT_INFO_WDG($i) tag delete [ $TEXT_INFO_WDG($i) tag names ]
    }
}

#===============================================================================

proc ::Yadt::Prepare_Mark_Diffs {} {

    variable ::Yadt::OPTIONS
    variable ::Yadt::WIDGETS
    variable ::Yadt::MAP_COLOR

    foreach tag { currtag textcurrtag difftag deltag instag inlinetag inlineinstag inlinechgtag chgtag overlaptag sel } {
        foreach win [ concat [ ::Yadt::Get_Diff_Wdg_List ] $WIDGETS(diff_lines_text) ] {
            eval $win tag configure $tag $OPTIONS($tag)
        }
    }
    eval $WIDGETS(diff_lines_files) tag configure sel $OPTIONS(sel)
}

#===============================================================================

proc ::Yadt::Add_Lines {} {

    variable ::Yadt::DIFF2
    variable ::Yadt::DIFF3
    variable ::Yadt::DIFF_INT
    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::WIDGETS
    variable ::Yadt::LCSDATA
    variable ::Yadt::DIFF_FILES

    set combo_values {}
    set combo_width 10

    switch -- $DIFF_TYPE {

        2 {
            set num_diff [ llength $DIFF2(diff) ]
            set DIFF_INT(count) 0

            foreach diff $DIFF2(diff) {
                set result [ ::Yadt::Analyze_Diff2 $diff ]

                if { $result != "" } {
                    incr DIFF_INT(count)
                    set DIFF_INT($DIFF_INT(count),pdiff) "$result"
                    ::Yadt::Align_One_Diff2 $DIFF_INT(count)
                    set combo_value [ format "%-6d: %s" $DIFF_INT(count) $diff ]
                    lappend combo_values $combo_value
                    set combo_width [ ::CmnTools::MaxN $combo_width [ string length $combo_value ] ]
                }
            }
            set diff_num $DIFF_INT(count)
        }

        3 {
            foreach { lines(1) lines(2) lines(3) } $LCSDATA(unchanged) { }

            for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
                set prev_idx($i) -1
                set idx($i) -1
            }

            set count 0
            for { set i 0 } { $i < [ llength $lines(1) ] } { incr i } {

                for { set j 1 } { $j <= $DIFF_TYPE } { incr j } {
                    set idx($j) [ lindex $lines($j) $i ]
                }

                ::Yadt::Collect_Diff3_From_Lcs prev_idx idx count
                set prev_idx(1) $idx(1)
                set prev_idx(2) $idx(2)
                set prev_idx(3) $idx(3)
            }

            # Last diff, if any
            for { set j 1 } { $j <= $DIFF_TYPE } { incr j } {
                set prev_idx($j) $idx($j)
                set idx($j) [ llength $DIFF_FILES(strings,$j) ]
            }
            ::Yadt::Collect_Diff3_From_Lcs prev_idx idx count

            set num_diff [ llength [ array names DIFF3 *,which_file ] ]
            set DIFF_INT(count) 0

            ::Yadt::Add_Diff3_Info_Strings

            for { set i 1 } { $i <= $num_diff } { incr i } {

                incr DIFF_INT(count)
                ::Yadt::Status_Msg menustatus "Analyzing difference $i of $num_diff ..."
                ::Yadt::Align_One_Diff3 $i
                ::Yadt::Status_Msg menustatus "Analyzing difference $i of $num_diff ...Done"
                set combo_value [ format "%-6d: %s: %s: %s" \
                                      $DIFF_INT(count) \
                                      $DIFF3($i,1,diff) \
                                      $DIFF3($i,2,diff) \
                                      $DIFF3($i,3,diff) ]
                lappend combo_values $combo_value
                set combo_width [ ::CmnTools::MaxN $combo_width [ string length $combo_value ] ]
            }

            for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
                set len($i) [ llength $DIFF_FILES(strings,$i) ]
            }
            for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
                set fnum($i) [ expr $len($i) + $DIFF_INT(delta,$i) ]
            }

            ::Yadt::Append_Final_Lcs_Lines fnum

            set diff_num $DIFF_INT(count)
        }
    }

    $WIDGETS(diff_combo) configure -width $combo_width -values $combo_values

    return $diff_num
}

#===============================================================================

proc ::Yadt::Update_Merge_Marks {} {

    variable ::Yadt::DIFF2
    variable ::Yadt::DIFF3
    variable ::Yadt::DIFF_INT
    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::MERGE_START
    variable ::Yadt::MERGE_TEXT_WDG
    variable ::Yadt::MERGE_INFO_WDG
    variable ::Yadt::OPTIONS
    variable ::Yadt::RANGES

    for { set i $MERGE_START } { $i <= $DIFF_TYPE } { incr i } {
        eval $MERGE_TEXT_WDG($i) tag delete [ $MERGE_TEXT_WDG($i) tag names ]
        eval $MERGE_INFO_WDG($i) tag delete [ $MERGE_INFO_WDG($i) tag names ]
    }

    foreach tag { merge1tag merge2tag merge3tag textcurrtag sel } {
        foreach win [ ::Yadt::Get_Merge_Wdg_List ] {
            eval $win tag configure $tag $OPTIONS($tag)
        }
    }

    foreach tag { currtag } {
        foreach win [ ::Yadt::Get_Merge_Wdg_List 0 "info" ] {
            eval $win tag configure $tag $OPTIONS($tag)
        }
    }

    switch -- $DIFF_TYPE {
        2 {
            set num_diff [ llength $DIFF2(diff) ]
            for { set i 1 } { $i <= $num_diff } { incr i } {
                foreach [ list thisdiff s1 e1 s2 e2 type ] $DIFF_INT($i,pdiff) { }
                if { $type == "a" } {
                    incr s1
                }
                $MERGE_INFO_WDG(2) mark set mark$i $s1.0
                $MERGE_INFO_WDG(2) mark gravity mark$i left
                $MERGE_TEXT_WDG(2) mark set mark$i $s1.0
                $MERGE_TEXT_WDG(2) mark gravity mark$i left
            }

            for { set i 1 } { $i <= $num_diff } { incr i } {
                set DIFF_INT(normal_merge$i) 1
            }

            for { set i 1 } { $i <= $num_diff } { incr i } {
                foreach [ list thisdiff s1 e1 s2 e2 type ] $DIFF_INT($i,pdiff) { }
                if { $DIFF_INT(normal_merge$i) == 1 } {
                    if { $type != "a" } {
                        set lines [ expr { $e1 - $s1 + 1 } ]
                        $MERGE_TEXT_WDG(2) tag add merge1tag mark$i mark$i+${lines}lines
                    }
                }
            }

            if { $num_diff > 0 } {
                set pos $DIFF_INT(pos)
                if { $pos == 0 } {
                    set pos 1
                }
                set lines [ ::Yadt::Diff_Size $pos $DIFF_INT(normal_merge$pos) ]
                $MERGE_INFO_WDG(2) tag add \
                    currtag mark$pos "mark$pos+${lines}lines"
            }
        }
        3 {
            ::Yadt::Set_Diffs_Merge_Marks
            set num_diff [ llength [ array names RANGES ] ]
            for { set i 1 } { $i <= $num_diff } { incr i } {
                for { set j $MERGE_START } { $j <= $DIFF_TYPE } { incr j } {
                    set DIFF_INT(expert_merge$i,$j) 1
                    set DIFF_INT($i,$j,expert_resolved) 0
                }
            }
        }
    }
}

#===============================================================================

proc ::Yadt::Set_Diffs_Merge_Marks {} {

    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::MERGE_START
    variable ::Yadt::MERGE_INFO_WDG
    variable ::Yadt::MERGE_TEXT_WDG
    variable ::Yadt::DIFF_INT
    variable ::Yadt::DIFF3

    set num_diff [ llength [ array names DIFF3 *,which_file ] ]
    for { set i 1 } { $i <= $num_diff } { incr i } {
        for { set j $MERGE_START } { $j <= $DIFF_TYPE } { incr j } {
            foreach [ list thisdiff($j) s($j) e($j) type($j) ] $DIFF_INT($i,1,pdiff) { }
            if { $type($j) == "a" } {
                incr s($j)
            }
            $MERGE_INFO_WDG($j) mark set mark${j}_$i $s($j).0
            $MERGE_INFO_WDG($j) mark gravity mark${j}_$i left
            $MERGE_TEXT_WDG($j) mark set mark${j}_$i $s($j).0
            $MERGE_TEXT_WDG($j) mark gravity mark${j}_$i left
        }
    }

    # Default merge methods - from file A (Base)
    for { set i 1 } { $i <= $num_diff } { incr i } {
        for { set j $MERGE_START } { $j <= $DIFF_TYPE } { incr j } {
            set DIFF_INT(normal_merge$i,$j) 1
            set DIFF_INT($i,$j,normal_resolved) 0
        }
    }

    for { set i 1 } { $i <= $num_diff } { incr i } {
        for { set j $MERGE_START } { $j <= $DIFF_TYPE } { incr j } {
            foreach [ list thisdiff($j) s($j) e($j) type($j) ] $DIFF_INT($i,1,pdiff) { }
            if { $DIFF_INT(normal_merge$i,$j) == 1 } {
                if { $type($j) != "a" } {
                    set lines [ expr $e($j) - $s($j) + 1 ]
                    $MERGE_TEXT_WDG($j) tag add merge1tag mark${j}_$i mark${j}_$i+${lines}lines
                }
            }
        }
    }

    if { $num_diff > 0 } {
        set pos $DIFF_INT(pos)
        if { $pos == 0 } {
            set pos 1
        }
        for { set j $MERGE_START } { $j <= $DIFF_TYPE } { incr j } {
            set lines [ ::Yadt::Diff_Size $pos $DIFF_INT(normal_merge${pos},$j) ]
            $MERGE_INFO_WDG($j) tag add \
                currtag mark${j}_$pos "mark${j}_${pos}+${lines}lines"
        }
    }
}

#===============================================================================

proc ::Yadt::Set_All_Tags {} {

    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::DIFF2
    variable ::Yadt::DIFF3
    variable ::Yadt::OPTIONS
    variable ::Yadt::RANGES

    switch -- $DIFF_TYPE {
        2 {
            set num_diff [ llength $DIFF2(diff) ]
        }
        3 {
            switch -- $OPTIONS(merge_mode) {
                normal {
                    set num_diff [ llength [ array names DIFF3 *,which_file ] ]
                }
                expert {
                    set num_diff [ llength [ array names RANGES ] ]
                }
            }
        }
    }

    for { set i 1 } { $i <= $num_diff } { incr i } {
        ::Yadt::Set_Tag $i difftag
    }

    ::Yadt::Toggle_Inline_Tags
}

#===============================================================================

proc ::Yadt::Toggle_Inline_Tags {} {

    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::DIFF2
    variable ::Yadt::DIFF3
    variable ::Yadt::OPTIONS

    ::Yadt::Prepare_Mark_Diffs

    switch -- $DIFF_TYPE {
        2 {
            set num_diff [ llength $DIFF2(diff) ]
        }
        3 {
            set num_diff [ llength [ array names DIFF3 *,which_file ] ]
        }
    }

    if { $OPTIONS(show_inline) } {
        ::Yadt::Text_Tags remove
    }

    if { $OPTIONS(show_inline) } {
        set action add
    } else {
        set action remove
    }

    for { set i 1 } { $i <= $num_diff } { incr i } {
        ::Yadt::Inline_Tags $action $i
    }

    if { !$OPTIONS(show_inline) } {
        ::Yadt::Text_Tags add
    }
}

#===============================================================================

proc ::Yadt::Inline_Tags { action diff_id } {

    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::DIFF_INT
    variable ::Yadt::TEXT_WDG

    switch -- $action {
        remove -
        add {}
        default {
            return -code error "Unknown action <$action>"
        }
    }

    for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
        for { set j 0 } { $j < $DIFF_INT(scrinline,$diff_id,$i) } { incr j } {
            foreach { line startcol endcol tag } $DIFF_INT(scrinline,$diff_id,$i,$j) { }
            ::Yadt::Inline_Tag $action $TEXT_WDG($i) $tag $line $startcol $endcol
        }
    }
}

#===============================================================================

proc ::Yadt::Inline_Tag { action wdg tag line startcol endcol } {
    switch -- $action {
        remove -
        add {
            $wdg tag $action $tag $line.$startcol $line.$endcol
        }
        default {
            return -code error "Unknown action <$action>"
        }
    }
}

#===============================================================================

proc ::Yadt::Set_Tag { diff_id tag } {

    variable ::Yadt::DIFF_TYPE

    switch -- $DIFF_TYPE {
        2 {
            ::Yadt::Set_Tag2 $diff_id $tag
        }
        3 {
            ::Yadt::Set_Tag3 $diff_id $tag
        }
    }
}

#===============================================================================

proc ::Yadt::Set_Tag2 { diff_id tag } {

    variable ::Yadt::DIFF_INT
    variable ::Yadt::TEXT_WDG
    variable ::Yadt::TEXT_NUM_WDG
    variable ::Yadt::TEXT_INFO_WDG
    variable ::Yadt::MERGE_TEXT_WDG
    variable ::Yadt::MERGE_INFO_WDG
    variable ::Yadt::OPTIONS

    if ![ info exists DIFF_INT($diff_id,scrdiff) ] return

    foreach { start end type } $DIFF_INT($diff_id,scrdiff) { }

    switch -- $type {
        "d" {
            set coltag deltag
        }
        "a" {
            set coltag instag
        }
        "c" {
            set coltag chgtag
        }
    }

    # Create tag: only create, it will be shown or not later
    ::Yadt::Create_Line_Tag $diff_id 1 $tag $start $end
    ::Yadt::Create_Line_Tag $diff_id 2 $coltag $start $end

    if { $OPTIONS(tagln) } {
        ::Yadt::Add_Tag $TEXT_NUM_WDG(1) $tag $start $end
        ::Yadt::Add_Tag $TEXT_NUM_WDG(2) $tag $start $end
        ::Yadt::Add_Tag $TEXT_NUM_WDG(2) $coltag $start $end
    }
    if { $OPTIONS(taginfo) } {
        ::Yadt::Add_Tag $TEXT_INFO_WDG(1) $tag $start $end
        ::Yadt::Add_Tag $TEXT_INFO_WDG(2) $tag $start $end
        ::Yadt::Add_Tag $TEXT_INFO_WDG(2) $coltag $start $end
    }

    # If there is no merge window variables DIFF_INT($OPTUIONS(merge_mode)_merge...) do not exist
    if [ info exists DIFF_INT(normal_merge${diff_id}) ] {
        set lines [ ::Yadt::Diff_Size $diff_id $DIFF_INT(normal_merge${diff_id}) ]
        $MERGE_INFO_WDG(2) tag add $tag mark${diff_id} "mark${diff_id}+${lines}lines"
        $MERGE_TEXT_WDG(2) tag add $tag mark${diff_id} "mark${diff_id}+${lines}lines"
    }
}

#===============================================================================

proc ::Yadt::Set_Tag3 { diff_id tag } {

    variable ::Yadt::DIFF3
    variable ::Yadt::DIFF_INT
    variable ::Yadt::TEXT_WDG
    variable ::Yadt::TEXT_NUM_WDG
    variable ::Yadt::TEXT_INFO_WDG
    variable ::Yadt::MERGE_TEXT_WDG
    variable ::Yadt::MERGE_INFO_WDG
    variable ::Yadt::OPTIONS
    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::MERGE_START
    variable ::Yadt::RANGES2DIFF

    foreach { start end type } [ ::Yadt::Get_Diff_Scr_Params $diff_id ] { }
    if { $start == -1 && $end == -1 && $type == -1 } return

    set oper "a"
    if { $type == "ccc" } {
        set oper "c"
    }

    for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
        set coltag($i) chgtag
    }

    set i 0
    foreach t [ split $type {} ] {
        incr i
        switch -- $t {
            "a" {
                set coltag($i) deltag
            }
            "c" {
                switch -- $oper {
                    "a" {
                        set coltag($i) instag
                    }
                    "c" {
                        set coltag($i) chgtag
                    }
                }
            }
        }
    }

    switch -- $OPTIONS(merge_mode) {
        normal {
            #set which_diff_id $diff_id
        }
        expert {
            set diff_id $RANGES2DIFF($diff_id)
        }
    }

    # Check differences of fragments
    switch -- $DIFF3($diff_id,which_file) {
        0 {
            # all files differ - conflict
            set coltag(2) overlaptag
            set coltag(3) overlaptag
        }
        1 {
            # Only base file differ
        }
        2 {
            set coltag(3) difftag
        }
        3 {
            set coltag(2) difftag
        }
    }    

    ::Yadt::Create_Line_Tag $diff_id 1 $tag $start $end
    ::Yadt::Mark_Only_Different3_Lines $diff_id $start $end $coltag(2) $coltag(3)

    if { $OPTIONS(tagln) } {
        for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
            ::Yadt::Add_Tag $TEXT_NUM_WDG($i) $tag $start $end
        }
        ::Yadt::Add_Tag $TEXT_NUM_WDG(2) $coltag(2) $start $end
        ::Yadt::Add_Tag $TEXT_NUM_WDG(3) $coltag(3) $start $end
    }

    if { $OPTIONS(taginfo) } {
        for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
            ::Yadt::Add_Tag $TEXT_INFO_WDG($i) $tag $start $end
        }

        ::Yadt::Add_Tag $TEXT_INFO_WDG(2) $coltag(2) $start $end
        ::Yadt::Add_Tag $TEXT_INFO_WDG(3) $coltag(3) $start $end
    }

    for { set j $MERGE_START } { $j <= $DIFF_TYPE } { incr j } {
        # If there is no merge window variables DIFF_INT(normal_merge...) do not exist
        if [ info exists DIFF_INT(normal_merge${DIFF_INT(pos)},$j) ] {
            set lines [ ::Yadt::Diff_Size $DIFF_INT(pos) $DIFF_INT(normal_merge${DIFF_INT(pos)},$j) ]
            $MERGE_INFO_WDG($j) tag add $tag mark${j}_${DIFF_INT(pos)} \
                "mark${j}_${DIFF_INT(pos)}+${lines}lines"
            $MERGE_TEXT_WDG($j) tag add $tag mark${j}_${DIFF_INT(pos)} \
                "mark${j}_${DIFF_INT(pos)}+${lines}lines"
        }
    }
}

#===============================================================================

proc ::Yadt::Current_Tag { action diff_id { setpos 1 } } {

    variable ::Yadt::DIFF_INT
    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::MERGE_START
    variable ::Yadt::OPTIONS
    variable ::Yadt::TEXT_WDG
    variable ::Yadt::MERGE_TEXT_WDG

    switch -- $action {
        remove -
        add {}
        default {
            return -code error "Unsupported action <$action>"
        }
    }

    ::Yadt::Current_Text_Tag $action $diff_id
    ::Yadt::Current_Merge_Tag $action $diff_id

    if { $setpos } {
        if { $OPTIONS(autocenter) } {
            ::Yadt::Diff_Center
        } else {
            for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
                $TEXT_WDG($i) see $s($i).0
                $TEXT_WDG($i) mark set insert $s($i).0
            }
            for { set j $MERGE_START } { $j <= $DIFF_TYPE } { incr j } {
                if [ info exists DIFF_INT(normal_merge$diff_id,$j) ] {
                    $MERGE_TEXT_WDG($j) see mark${j}_${diff_id}
                }
            }
        }
    }
}

#===============================================================================

proc ::Yadt::Current_Text_Tag { action diff_id } {

    variable ::Yadt::DIFF_INT
    variable ::Yadt::TEXT_WDG
    variable ::Yadt::TEXT_NUM_WDG
    variable ::Yadt::TEXT_INFO_WDG
    variable ::Yadt::OPTIONS
    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::RANGES

    foreach { start end type } [ ::Yadt::Get_Diff_Scr_Params $diff_id ] { }
    if { $start == -1 && $end == -1 && $type == -1 } return

    switch -- $action {
        remove {
            for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {

                ::Yadt::Remove_Tag $TEXT_WDG($i) currtag $start $end
                ::Yadt::Remove_Tag $TEXT_WDG($i) textcurrtag $start $end

                if { $OPTIONS(taginfo) } {
                    ::Yadt::Remove_Tag $TEXT_INFO_WDG($i) currtag $start $end
                    ::Yadt::Remove_Tag $TEXT_INFO_WDG($i) textcurrtag $start $end
                }
                if { $OPTIONS(tagln) } {
                    ::Yadt::Remove_Tag $TEXT_NUM_WDG($i) currtag $start $end
                    ::Yadt::Remove_Tag $TEXT_NUM_WDG($i) textcurrtag $start $end
                }
            }
        }
        add {
            for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {

                if { $OPTIONS(merge_mode) == "expert" } {
                    ::Yadt::Add_Tag $TEXT_WDG($i) textcurrtag $start $end
                }

                if { $OPTIONS(taginfo) } {
                    ::Yadt::Add_Tag $TEXT_INFO_WDG($i) currtag $start $end
                    if { $OPTIONS(merge_mode) == "expert" } {
                        ::Yadt::Add_Tag $TEXT_INFO_WDG($i) textcurrtag $start $end
                    }
                }
                if { $OPTIONS(tagln) } {
                    ::Yadt::Add_Tag $TEXT_NUM_WDG($i) currtag $start $end
                    if { $OPTIONS(merge_mode) == "expert" } {
                        ::Yadt::Add_Tag $TEXT_NUM_WDG($i) textcurrtag $start $end
                    }
                }
            }
        }
    }
}

#===============================================================================

proc ::Yadt::Current_Merge_Tag { action diff_id } {

    variable ::Yadt::DIFF_INT
    variable ::Yadt::MERGE_TEXT_WDG
    variable ::Yadt::MERGE_INFO_WDG
    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::MERGE_START
    variable ::Yadt::OPTIONS
    variable ::Yadt::RANGES2DIFF
    variable ::Yadt::RANGES

    if { $diff_id == 0 } return

    switch -- $DIFF_TYPE {
        2 {
            for { set j $MERGE_START } { $j <= $DIFF_TYPE } { incr j } {
                # If there is no merge window variables DIFF_INT(normal_merge...) do not exist
                if [ info exists DIFF_INT(normal_merge$diff_id) ] {
                    set lines [ ::Yadt::Diff_Size $diff_id $DIFF_INT(normal_merge${diff_id}) ]
                    $MERGE_INFO_WDG($j) tag $action \
                        currtag mark${diff_id} "mark${diff_id}+${lines}lines"
                    $MERGE_TEXT_WDG($j) tag $action \
                        currtag mark${diff_id} "mark${diff_id}+${lines}lines"
                }
            }
        }
        3 {

            switch -- $OPTIONS(merge_mode) {
                normal {
                    for { set j $MERGE_START } { $j <= $DIFF_TYPE } { incr j } {
                        set offset($j) 0
                        set lines($j) [ ::Yadt::Diff_Size $diff_id $DIFF_INT($OPTIONS(merge_mode)_merge$diff_id,$j) ]
                    }
                }
                expert {
                    for { set j $MERGE_START } { $j <= $DIFF_TYPE } { incr j } {
                        set offset($j) [ ::Yadt::Get_Range_Offset_Inside_Diff $diff_id $j ]
                        set lines($j) [ ::Yadt::Diff_Size $diff_id $DIFF_INT($OPTIONS(merge_mode)_merge$diff_id,$j) ]
                    }
                    set diff_id $RANGES2DIFF($diff_id)
                }
            }

            for { set j $MERGE_START } { $j <= $DIFF_TYPE } { incr j } {
                if [ info exists DIFF_INT(normal_merge$diff_id,$j) ] {
                    set m_start "mark${j}_$diff_id+$offset($j)lines"
                    set m_end "mark${j}_$diff_id+$offset($j)lines+$lines($j)lines"
                    $MERGE_TEXT_WDG($j) tag remove textcurrtag $m_start $m_end
                    $MERGE_INFO_WDG($j) tag remove textcurrtag $m_start $m_end
                    $MERGE_INFO_WDG($j) tag $action currtag $m_start $m_end
                    if { $OPTIONS(merge_mode) == "expert" } {
                        $MERGE_INFO_WDG($j) tag $action textcurrtag $m_start $m_end
                        $MERGE_TEXT_WDG($j) tag $action textcurrtag $m_start $m_end
                    }
                }
            }
        }
    }
}

#===============================================================================

proc ::Yadt::Get_Range_Offset_Inside_Diff { range target } {

    variable ::Yadt::RANGES
    variable ::Yadt::DIFF2RANGES
    variable ::Yadt::RANGES2DIFF
    variable ::Yadt::DIFF_INT

    foreach { start end type } [ ::Yadt::Get_Diff_Scr_Params $range ] { }

    set diff_id $RANGES2DIFF($range)

    set lines 0

    foreach r $DIFF2RANGES($diff_id) {
        foreach { r_start r_end r_type } $RANGES($r) { }

        if { $r_start == $start && $r_end == $end } break

        set method $DIFF_INT(expert_merge$r,$target)

        if { $method == -1 } continue

        foreach i [ split $method {} ] {
            incr lines [ ::Yadt::Diff_Size $r $i ]

        }
    }

    return $lines
}

#===============================================================================

proc ::Yadt::Mark_Only_Different3_Lines { diff_id start end tag2 tag3 } {

    variable ::Yadt::TEXT_WDG
    variable ::Yadt::TEXT_NUM_WDG

    set size [ expr $end - $start + 1 ]

    for { set i 0 } { $i < $size } { incr i } {

        set t1 ""
        set t2 ""
        set t3 ""

        set next_line [ expr $start + $i ]
        set t1 [ $TEXT_WDG(1) get $next_line.0 $next_line.end ]
        set num_t1 [ $TEXT_NUM_WDG(1) get $next_line.0 $next_line.end ]

        set t2 [ $TEXT_WDG(2) get $next_line.0 $next_line.end ]
        set num_t2 [ $TEXT_NUM_WDG(2) get $next_line.0 $next_line.end ]

        set t3 [ $TEXT_WDG(3) get $next_line.0 $next_line.end ]
        set num_t3 [ $TEXT_NUM_WDG(3) get $next_line.0 $next_line.end ]

        set curtag2 $tag2
        set curtag3 $tag3

        ::Yadt::Tune_Different3_Tags $diff_id $t1 $t2 $t3 $num_t1 $num_t2 $num_t3 curtag2 curtag3

        if { $curtag2 != "overlaptag" } {
            ::Yadt::Create_Line_Tag $diff_id 2 $curtag2 $next_line $next_line
        }
        if { $curtag3 != "overlaptag" } {
            ::Yadt::Create_Line_Tag $diff_id 3 $curtag3 $next_line $next_line
        }
    }
}

#===============================================================================

proc ::Yadt::Tune_Different3_Tags { diff_id t1 t2 t3 num_t1 num_t2 num_t3 tag2 tag3 } {

    upvar $tag2 curtag2
    upvar $tag3 curtag3
    variable ::Yadt::DIFF3

    if { $num_t1 == "" } {
        if { $num_t2 == "" || $num_t3 == "" } {
            if { $num_t2 == "" } {
                set curtag3 instag
            }
            if { $num_t3 == "" } {
                set curtag2 instag
            }
            return
        }

        if { $t2 == $t3 } {
            if { $DIFF3($diff_id,which_file) != 0 } {
                set curtag2 instag
                set curtag3 instag
            }
        } else {
            if { $t2 != "" } {
                set curtag2 chgtag
            }
            if { $t3 != "" } {
                set curtag3 chgtag
            }
        }
        return
    }

    if { $num_t2 == "" || $num_t3 == "" } {
        if { $num_t2 == "" } {
            set curtag2 deltag
        }
        if { $num_t3 == ""} {
            set curtag3 deltag
        }
    }

    if { $t1 != $t2 || $t1 != $t3 } {
        if { $t1 != $t2 && $num_t2 != "" } {
            set curtag2 chgtag
        }
        if { $t1 != $t3 && $num_t3 != "" } {
            set curtag3 chgtag
        }
    }
}

#===============================================================================

proc ::Yadt::Define_Tags_Priority {} {

    variable ::Yadt::WIDGETS

    foreach element [ concat [ ::Yadt::Get_Diff_Wdg_List ] $WIDGETS(diff_lines_text) ] {
        $element tag raise inlinetag
        $element tag raise chgtag
        $element tag raise inlineinstag
        $element tag raise inlinechgtag
        $element tag raise instag
    }

    foreach element [ concat [ ::Yadt::Get_Diff_Wdg_List ] \
                          [ ::Yadt::Get_Merge_Wdg_List ] \
                          $WIDGETS(diff_lines_text) ] {
        $element tag raise sel
    }

    foreach element [ ::Yadt::Get_Diff_Wdg_List 0 "num" ] {
        $element tag raise currtag
    }
}

#===============================================================================

proc ::Yadt::Add_Tag { wdg tag start end } {
    $wdg tag add $tag $start.0 [ expr $end + 1 ].0
}

#===============================================================================

proc ::Yadt::Remove_Tag { wdg tag start end } {
    $wdg tag remove $tag $start.0  [ expr $end + 1 ].0
}

#===============================================================================

proc ::Yadt::Create_Line_Tag { diff_id file_id tag from to } {

    variable ::Yadt::DIFF_INT

    lappend DIFF_INT(scrtag,$diff_id,$file_id) [ list $tag $from $to ]
}

#===============================================================================

proc ::Yadt::Text_Tags { action } {

    variable ::Yadt::DIFF_INT
    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::TEXT_WDG
    variable ::Yadt::OPTIONS

    switch -- $action {
        add -
        remove {
        }
        default {
            return -code error "Unsupported action <$action>"
        }
    }

    if { !$OPTIONS(tagtext) } return

    foreach element [ array names DIFF_INT scrtag,* ] {
        foreach { dummy diff_id file_id } [ split $element "," ] { }

        for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
            if ![ info exists DIFF_INT(scrtag,$diff_id,$file_id) ] continue

            foreach single_tag $DIFF_INT(scrtag,$diff_id,$file_id) {

                foreach { tag from to } $single_tag { }

                switch -- $action {
                    add {
                        ::Yadt::Add_Tag $TEXT_WDG($file_id) $tag $from $to
                    }
                    remove {
                        ::Yadt::Remove_Tag $TEXT_WDG($file_id) $tag $from $to
                    }
                }
            }
        }
    }
}

#===============================================================================

################################################################################
# Draw widgets procs                                                           #
################################################################################

#===============================================================================

proc ::Yadt::Draw_Toplevel {} {

    global CVS_REVISION
    variable ::Yadt::WIDGETS
    variable ::Yadt::WDG_OPTIONS
    variable ::Yadt::OPTIONS

    toplevel $WIDGETS(window_name)
    wm withdraw $WIDGETS(window_name)

    wm resizable $WIDGETS(window_name) 1 1
    wm minsize $WIDGETS(window_name) 300 300
    wm title $WIDGETS(window_name) "$WDG_OPTIONS(yadt_title) $CVS_REVISION"
    wm protocol $WIDGETS(window_name) WM_DELETE_WINDOW "Yadt::Exit"

    # One more geometry check is needed if we got options from config file
    # but not from command line
    if [ ::CmnTools::Parse_WM_Geometry $OPTIONS(geometry) -width width -height height -left x -top y ] {
        if { [ info exists width ] && [ info exists height ] } {
            set WDG_OPTIONS(yadt_width)  [ expr { $width  <= [ winfo screenwidth  . ] ? $width  : [ winfo screenwidth  . ] } ]
            set WDG_OPTIONS(yadt_height) [ expr { $height <= [ winfo screenheight . ] ? $height : [ winfo screenheight . ] } ]
            if { [ info exists WDG_OPTIONS(geometry,is_set) ] && $WDG_OPTIONS(geometry,is_set) } {
                set WDG_OPTIONS(size,is_set) 1
            }
        }
        if { [ info exists x ] && [ info exists y ] } {
            set WDG_OPTIONS(yadt_x) [ expr { $x <= [ expr { [ winfo screenwidth . ] - 100 } ] ? $x : 100 } ]
            set WDG_OPTIONS(yadt_y) [ expr { $y <= [ expr { [ winfo screenheight . ] - 100 } ] ? $y : 100 } ]
            set WDG_OPTIONS(position,is_set) 1
        }
    }

    set w $WDG_OPTIONS(yadt_width)
    set h $WDG_OPTIONS(yadt_height)
    set x $WDG_OPTIONS(yadt_x)
    set y $WDG_OPTIONS(yadt_y)

    if { [ info exists WDG_OPTIONS(position,is_set) ] && $WDG_OPTIONS(position,is_set) } {
        BWidget::place $WIDGETS(window_name) $w $h at $x $y
    } else {
        BWidget::place $WIDGETS(window_name) $w $h center
    }
    wm deiconify $WIDGETS(window_name)
    ::Yadt::Watch_Cursor $WIDGETS(window_name)
    update
}

#===============================================================================

proc ::Yadt::Draw_Carcas {} {

    ::Yadt::Draw_Toolbar_Elements
    ::Yadt::Draw_Status_Bar
    ::Yadt::Draw_Main
    ::Yadt::Draw_Menu
    ::Yadt::Draw_Find_Bar
}

#===============================================================================

proc ::Yadt::Set_Main_Widgets {} {

    variable ::Yadt::WIDGETS

    set WIDGETS(main_part) $WIDGETS(window_name).data
    set WIDGETS(diff_lines_frame) $WIDGETS(window_name).diff_lines
    set WIDGETS(diff_lines_files) $WIDGETS(diff_lines_frame).file
    set WIDGETS(diff_lines_text) $WIDGETS(diff_lines_frame).text
    set WIDGETS(main_paned) $WIDGETS(main_part).main_paned

    set WIDGETS(main_widgets) \
        [ list \
              $WIDGETS(main_part) \
              $WIDGETS(diff_lines_frame) \
              $WIDGETS(diff_lines_files) \
              $WIDGETS(diff_lines_text) \
              $WIDGETS(main_paned) \
             ]
}

#===============================================================================

proc ::Yadt::Destroy_Main_Widgets {} {

    variable ::Yadt::WIDGETS

    if ![ info exists WIDGETS(main_widgets) ] {
        return
    }

    foreach wdg $WIDGETS(main_widgets) {
        if [ winfo exists $wdg] {
            destroy $wdg
        }
    }
}

#===============================================================================

proc ::Yadt::Draw_Main {} {

    global tcl_version
    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::MERGE_START
    variable ::Yadt::TEXT_WDG
    variable ::Yadt::TEXT_NUM_WDG
    variable ::Yadt::TEXT_INFO_WDG
    variable ::Yadt::MERGE_TEXT_WDG
    variable ::Yadt::MERGE_INFO_WDG
    variable ::Yadt::MAP_TITLE
    variable ::Yadt::MAP_COLOR
    variable ::Yadt::WIDGETS
    variable ::Yadt::WDG_OPTIONS
    variable ::Yadt::OPTIONS

    set disabled_state readonly
    if { [ info tclversion ] < 8.4 } {
        set disabled_state disabled
    }

    ::Yadt::Set_Main_Widgets
    ::Yadt::Destroy_Main_Widgets

    frame $WIDGETS(main_part) -relief groove -bd 2
    pack $WIDGETS(main_part) -side top -fill both -expand 1

    # Diff Lines frame and diff text
    frame $WIDGETS(diff_lines_frame)
    ::Yadt::Toggle_Diff_Lines

    text $WIDGETS(diff_lines_files) \
        -wrap none \
        -borderwidth 0 \
        -height $DIFF_TYPE \
        -width 3 \
        -state disabled
    if { $tcl_version >= 8.5 } {
        $WIDGETS(diff_lines_files) configure -inactiveselectbackground gray20
    }
    eval "$WIDGETS(diff_lines_files) configure $OPTIONS(textopt)"
    pack $WIDGETS(diff_lines_files) -side left -fill y -expand 0

    text $WIDGETS(diff_lines_text) \
        -wrap none \
        -borderwidth 0 \
        -height $DIFF_TYPE \
        -state disabled \
        -width 0
    if { $tcl_version >= 8.5 } {
        $WIDGETS(diff_lines_text) configure -inactiveselectbackground gray20
    }
    eval "$WIDGETS(diff_lines_text) configure $OPTIONS(textopt)"
    pack $WIDGETS(diff_lines_text) -side left -fill both -expand 1

    ::Yadt::Yadt_Paned -create $WIDGETS(main_paned) -orient vertical -opaqueresize 0 -showhandle 0
    ::Yadt::Yadt_Paned -pack $WIDGETS(main_paned) -side top -fill both -expand yes -pady 0 -padx 0
    set WIDGETS(top_wnd) [ ::Yadt::Yadt_Paned -add $WIDGETS(main_paned) top_wnd ]
    set WIDGETS(bottom_wnd) [ ::Yadt::Yadt_Paned -add $WIDGETS(main_paned) bottom_wnd ]

    if { !$OPTIONS(preview_shown) } {
        ::Yadt::Yadt_Paned -hide $WIDGETS(main_paned) $WIDGETS(bottom_wnd)
    }

    ::Yadt::Yadt_Paned -init $WIDGETS(main_paned)

    frame $WIDGETS(top_wnd).scr_frame 
    pack $WIDGETS(top_wnd).scr_frame -side right -expand 0 -fill y

    set WIDGETS(v_scroll) [ scrollbar $WIDGETS(top_wnd).scr_frame.v_scroll \
                                -borderwidth 1 \
                                -orient vertical \
                                -command [ list ::Yadt::V_Scrollbar_Event yview ] ]

    set canvas_width [ winfo reqwidth $WIDGETS(v_scroll) ]
    set canvas_color [ $WIDGETS(v_scroll) cget -troughcolor ]

    frame $WIDGETS(top_wnd).map_frame 
    pack $WIDGETS(top_wnd).map_frame -side left -expand 0 -fill y

    frame $WIDGETS(top_wnd).map_frame.top_space -height $canvas_width
    pack $WIDGETS(top_wnd).map_frame.top_space \
        -side top \
        -fill y \
        -expand 0

    frame $WIDGETS(top_wnd).map_frame.bottom_space -height $canvas_width
    pack $WIDGETS(top_wnd).map_frame.bottom_space \
        -side bottom \
        -fill y \
        -expand 0

    set WIDGETS(map) [ frame $WIDGETS(top_wnd).map_frame.map \
                           -bd 1 \
                           -relief sunken \
                           -takefocus 0 \
                           -highlightthickness 0 ]
    pack $WIDGETS(map) -side bottom -fill y -expand 1

    set WDG_OPTIONS(map_image) mapImage
    image create photo $WDG_OPTIONS(map_image)

    set WIDGETS(mapCanvas) $WIDGETS(map).canvas
    canvas $WIDGETS(mapCanvas) \
        -width $canvas_width \
        -yscrollcommand ::Yadt::Map_Resize \
        -background $canvas_color \
        -bd 0 \
        -relief sunken \
        -highlightthickness 0

    $WIDGETS(mapCanvas) create image 1 1 \
        -image $WDG_OPTIONS(map_image) \
        -anchor nw

    pack $WIDGETS(mapCanvas) \
        -side top \
        -fill both \
        -expand y

    switch -- $OPTIONS(diff_layout) {
        horizontal {
            set orient "vertical"
        }
        vertical {
            set orient "horizontal"
        }
        default {
            return -code error "Internal error: incorrect layout <$OPTIONS(diff_layout)>"
        }        
    }

    set WIDGETS(diff_paned) $WIDGETS(top_wnd).diff_paned
    ::Yadt::Yadt_Paned -create $WIDGETS(diff_paned) -orient $orient -opaqueresize 0 -showhandle 0
    ::Yadt::Yadt_Paned -pack $WIDGETS(diff_paned) -side top -fill both -expand yes -pady 0 -padx 0

    bind $WIDGETS(mapCanvas) <ButtonPress-1>   \
        [ list ::Yadt::Handle_Map_Event B1-Press   %y ]
    bind $WIDGETS(mapCanvas) <Button1-Motion>  \
        [ list ::Yadt::Handle_Map_Event B1-Motion  %y ]
    bind $WIDGETS(mapCanvas) <ButtonRelease-1> \
        [ list ::Yadt::Handle_Map_Event B1-Release %y ]

    for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
        
        set p_frame [ ::Yadt::Yadt_Paned -add $WIDGETS(diff_paned) file$i ]

        set title_frame [ frame $p_frame.frame$i ]
        pack $title_frame -side top -fill x -expand 0

        set WIDGETS(h_scroll_$i) [ scrollbar $p_frame.h_scroll_$i \
                                       -borderwidth 1 \
                                       -orient horizontal ]
        pack $WIDGETS(h_scroll_$i) -side bottom -expand 0 -fill x

        set diff_frame [ frame $p_frame.diff$i -relief sunken -bd 1 ]
        pack $diff_frame -side top -fill both -expand 1

        set WIDGETS(file_title_$i) [ entry $title_frame.title$i \
                                         -state readonly \
                                         -takefocus 0 \
                                         -relief flat \
                                         -justify center ]

        ::Yadt::Update_File_Color $i

        pack $title_frame.title$i -side left -fill x -expand 1

        set TEXT_NUM_WDG($i) [ text $diff_frame.info$i \
                                   -bg white \
                                   -width 6 \
                                   -relief sunken \
                                   -bd 0 \
                                   -highlightthickness 1 \
                                   -highlightcolor white \
                                   -font $OPTIONS(default_font) \
                                   -takefocus 0 ]
        if { $tcl_version >= 8.5 } {
            $TEXT_NUM_WDG($i) configure -inactiveselectbackground gray20
        }
        eval "$TEXT_NUM_WDG($i) configure $OPTIONS(textopt)"
        pack $TEXT_NUM_WDG($i) -fill both -side left -expand 0

        set TEXT_INFO_WDG($i) [ text $diff_frame.change$i \
                                    -bg white \
                                    -width 2 \
                                    -relief sunken \
                                    -bd 0 \
                                    -highlightthickness 1 \
                                    -highlightcolor white \
                                    -font $OPTIONS(default_font) \
                                    -takefocus 0 ]
        if { $tcl_version >= 8.5 } {
            $TEXT_INFO_WDG($i) configure -inactiveselectbackground gray20
        }
        eval "$TEXT_INFO_WDG($i) configure $OPTIONS(textopt)"
        pack $TEXT_INFO_WDG($i) -fill both -side left -expand 0

        set TEXT_WDG($i) [ text $diff_frame.text$i \
                               -bg white \
                               -relief sunken \
                               -bd 0 \
                               -font $OPTIONS(default_font) \
                               -highlightthickness 1 \
                               -exportselection 1 ]
        if { $tcl_version >= 8.5 } {
            $TEXT_WDG($i) configure -inactiveselectbackground gray20
        }
        set WDG_OPTIONS($TEXT_WDG($i)) "Source file $MAP_TITLE($i)"
        eval "$TEXT_WDG($i) configure $OPTIONS(textopt)"
        pack $TEXT_WDG($i) -fill both -side left -expand 1
    }

    ::Yadt::Yadt_Paned -init $WIDGETS(diff_paned)

    frame $WIDGETS(top_wnd).scr_frame.top_space -height $canvas_width
    pack $WIDGETS(top_wnd).scr_frame.top_space \
        -side top \
        -fill y \
        -expand 0

    frame $WIDGETS(top_wnd).scr_frame.bottom_space -height $canvas_width
    pack $WIDGETS(top_wnd).scr_frame.bottom_space \
        -side bottom \
        -fill y \
        -expand 0

    pack $WIDGETS(v_scroll) \
        -side bottom \
        -expand 1 \
        -fill y \
        -after $WIDGETS(top_wnd).scr_frame.bottom_space

    for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
        $WIDGETS(h_scroll_$i) configure \
            -command [ list $TEXT_WDG($i) xview ]
        $TEXT_WDG($i) configure \
            -xscrollcommand [ list ::Yadt::Horizontal_Scroll_Sync text $i ]

        foreach wdg [ ::Yadt::Get_Diff_Wdg_List $i "all" ] {
            $wdg configure -yscrollcommand [ list ::Yadt::Vertical_Scroll_Sync text $i $wdg $WIDGETS(v_scroll) 1 ]
        }
    }

    ::Yadt::Draw_Merge_Frame

    for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
        rename ::$TEXT_WDG($i) ::$TEXT_WDG($i)_
        proc ::$TEXT_WDG($i) { command args } $::Yadt::Text_Widget_Proc
    }

    for { set i $MERGE_START } { $i <= $DIFF_TYPE } { incr i } {
        rename ::$MERGE_TEXT_WDG($i) ::$MERGE_TEXT_WDG($i)_
        proc ::$MERGE_TEXT_WDG($i) { command args } $::Yadt::Merge_Text_Widget_Proc
    }

    update
    update idletasks
}

#===============================================================================

proc ::Yadt::Update_File_Labels {} {

    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::DIFF_FILES
    variable ::Yadt::MAP_TITLE
    variable ::Yadt::WIDGETS
    variable ::Yadt::OPTIONS

    for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
        $WIDGETS(file_title_$i) configure -state normal
        $WIDGETS(file_title_$i) delete 0 end
        $WIDGETS(file_title_$i) insert end "$MAP_TITLE($i) $DIFF_FILES(label,$i)"
        $WIDGETS(file_title_$i) configure -state readonly

        DynamicHelp::add $WIDGETS(file_title_$i) -type balloon -variable ::Yadt::DIFF_FILES(full_path,$i)
    }
}

#===============================================================================

proc ::Yadt::Update_File_Color { i } {

    variable ::Yadt::WIDGETS
    variable ::Yadt::MAP_COLOR

    $WIDGETS(file_title_$i) configure -state normal
    $WIDGETS(file_title_$i) configure \
        -bd 0 \
        -bg $MAP_COLOR(bg,$i) \
        -fg $MAP_COLOR(fg,$i) \
        -readonlybackground $MAP_COLOR(bg,$i)
    $WIDGETS(file_title_$i) configure -state readonly
}

#===============================================================================

proc ::Yadt::Draw_Merge_Frame {} {

    global tcl_version
    variable ::Yadt::DIFF_FILES
    variable ::Yadt::WIDGETS
    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::MERGE_START
    variable ::Yadt::MERGE_INFO_WDG
    variable ::Yadt::MERGE_TEXT_WDG
    variable ::Yadt::OPTIONS

    set canvas_width [ winfo reqwidth $WIDGETS(v_scroll) ]

    frame $WIDGETS(bottom_wnd).scr_frame
    pack $WIDGETS(bottom_wnd).scr_frame -side right -expand 0 -fill y

    frame $WIDGETS(bottom_wnd).scr_frame.top_space -height $canvas_width
    pack $WIDGETS(bottom_wnd).scr_frame.top_space \
        -side top \
        -fill y \
        -expand 0

    frame $WIDGETS(bottom_wnd).scr_frame.bottom_space -height $canvas_width
    pack $WIDGETS(bottom_wnd).scr_frame.bottom_space \
        -side bottom \
        -fill y \
        -expand 0

    set WIDGETS(v_scroll_merge) [ scrollbar $WIDGETS(bottom_wnd).scr_frame.v_scroll \
                                      -borderwidth 1 -orient vertical \
                                      -command [ list ::Yadt::V_Merge_Scrollbar_Event yview ] ]
    pack $WIDGETS(v_scroll_merge) -side bottom -expand 1 -fill y

    ::Yadt::Yadt_Paned -create $WIDGETS(bottom_wnd).merge_paned -orient horizontal -opaqueresize 0 -showhandle 0
    ::Yadt::Yadt_Paned -pack $WIDGETS(bottom_wnd).merge_paned -side top -fill both -expand yes -pady 0 -padx 0

    for { set i $MERGE_START } { $i <= $DIFF_TYPE } { incr i } {

        set p_frame [ ::Yadt::Yadt_Paned -add $WIDGETS(bottom_wnd).merge_paned fr$i ]

        set title_frame [ frame $p_frame.frame ]
        pack $title_frame -side top -fill x -expand 0

        set WIDGETS(merge_title_$i) [ label $title_frame.title -justify center ]

        pack $WIDGETS(merge_title_$i) \
            -side left \
            -fill x \
            -expand 1

        set WIDGETS(h_scroll_merge_$i) \
            [ scrollbar $p_frame.h_scroll \
                  -borderwidth 1 \
                  -orient horizontal ]
        pack $WIDGETS(h_scroll_merge_$i) -side bottom -expand 0 -fill x

        set txt_frame [ frame $p_frame.container -relief sunken -bd 1 ]
        pack $txt_frame -side bottom -expand 1 -fill both

        set MERGE_INFO_WDG($i) [ text $txt_frame.info \
                                     -width 1 \
                                     -bg white \
                                     -relief sunken \
                                     -bd 0 \
                                     -font $OPTIONS(default_font) \
                                     -highlightthickness 1 \
                                     -takefocus 0 \
                                     -state normal ]
        if { $tcl_version >= 8.5 } {
            $MERGE_INFO_WDG($i) configure -inactiveselectbackground gray20
        }
        eval "$MERGE_INFO_WDG($i) configure $OPTIONS(textopt)"

        set MERGE_TEXT_WDG($i) [ text $txt_frame.text \
                                     -bg white \
                                     -relief sunken \
                                     -bd 0 \
                                     -font $OPTIONS(default_font) \
                                     -highlightthickness 1 \
                                     -exportselection 1 ]
        if { $tcl_version >= 8.5 } {
            $MERGE_TEXT_WDG($i) configure -inactiveselectbackground gray20
        }
        eval "$MERGE_TEXT_WDG($i) configure $OPTIONS(textopt)"

        pack $MERGE_INFO_WDG($i) -fill both -side left -expand 0
        pack $MERGE_TEXT_WDG($i) -fill both -side left -expand 1

        ::Yadt::Update_Merge_Title $i
    }

    ::Yadt::Yadt_Paned -init $WIDGETS(bottom_wnd).merge_paned

    for { set i $MERGE_START } { $i <= $DIFF_TYPE } { incr i } {
        $WIDGETS(h_scroll_merge_$i) configure \
            -command [ list $MERGE_TEXT_WDG($i) xview ]
        $MERGE_TEXT_WDG($i) configure \
            -xscrollcommand [ list ::Yadt::Horizontal_Scroll_Sync merge $i ]

        foreach wdg [ ::Yadt::Get_Merge_Wdg_List $i ] {
            $wdg configure -yscrollcommand [ list ::Yadt::Vertical_Scroll_Sync merge $i $wdg $WIDGETS(v_scroll_merge) 0 ]
        }
    }
}

#===============================================================================

proc ::Yadt::Update_Merge_Title { i } {

    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::MERGE_START
    variable ::Yadt::WIDGETS
    variable ::Yadt::WDG_OPTIONS
    variable ::Yadt::MERGE_TEXT_WDG
    variable ::Yadt::DIFF_FILES

    switch -- $DIFF_TYPE {
        2 {
            if ![ info exists DIFF_FILES(merge1) ] {
                set DIFF_FILES(merge1) "*preview*"
            }
            set merge_text "Merge Preview: $DIFF_FILES(merge1)"
        }
        3 {
            if { $MERGE_START == $DIFF_TYPE } {
                if ![ info exists DIFF_FILES(merge1) ] {
                    set DIFF_FILES(merge1) "*preview*"
                }
                set merge_text "Merge Preview: $DIFF_FILES(merge1)"
            } else {
                set ind [ expr $i - $DIFF_TYPE + 2 ]
                if ![ info exists DIFF_FILES(merge$ind) ] {
                    set DIFF_FILES(merge$ind) "*preview*"
                }
                set merge_text "Merge Preview: $DIFF_FILES(merge$ind)"
            }
        }
    }

    $WIDGETS(merge_title_$i) configure -text $merge_text
    set WDG_OPTIONS($MERGE_TEXT_WDG($i)) $merge_text
}

#===============================================================================

set ::Yadt::Text_Widget_Proc {

    variable ::Yadt::TEXT_WDG
    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::WIDGETS
    variable ::Yadt::MAP_TITLE_SHORT
    variable ::Yadt::WDG_OPTIONS

    set real "[ lindex [ info level [ info level ] ] 0 ]_"

    set result [ eval $real $command $args ]
    if { $command == "mark" } {
        if { [ lindex $args 0 ] == "set" && [ lindex $args 1 ] == "insert" } {
            set line [ lindex $args 2 ]
            set line_start "$line linestart"
            set line_end "$line lineend"

            set result_files ""
            set result_text ""

            set WDG_OPTIONS(cursor_position) ""
            for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
                if { "${WDG_OPTIONS(active_window)}_" == "$TEXT_WDG($i)_" } {
                    foreach { ln col } [ split [ $WDG_OPTIONS(active_window) index insert ] "." ] { }
                    set WDG_OPTIONS(cursor_position) "L: $ln C: $col"
                }

                append result_files $MAP_TITLE_SHORT($i)

                if { $WDG_OPTIONS(active_window) != "" } {
                    if { "${WDG_OPTIONS(active_window)}_" != "$TEXT_WDG($i)_" } {
                        set l1 [ $WDG_OPTIONS(active_window) index insert ]
                        set l1 [ lindex [ split $l1 "." ] 0 ]
                        $TEXT_WDG($i)_ mark set insert $l1.0
                    }
                }
             
                if [ info exists l1 ] {
                    set text_cont($i) [ $TEXT_WDG($i)_ get $l1.0 $l1.end ]
                } else {
                    set text_cont($i) [ $TEXT_WDG($i)_ get $line_start $line_end ]
                }

                append result_text $text_cont($i)
                if { $i < $DIFF_TYPE } {
                    append result_files "\n"
                    append result_text "\n"
                }
            }

            ::Yadt::Update_Line_By_Line_Widget $result_files $result_text

            set lines_equal 1
            for { set i 2 } { $i <= $DIFF_TYPE } { incr i } {
                if { $text_cont(1) != $text_cont($i) } {
                    set lines_equal 0
                    break
                }
            }

            if { !$lines_equal } {
                ::Yadt::Purge_All_Tags $WIDGETS(diff_lines_text) 1.0 end
                switch -- $DIFF_TYPE {
                    2 {
                        ::Yadt::Find_Ratcliff_Diff2 0 1 1 $text_cont(1) $text_cont(2)
                    }
                    3 {
                        ::Yadt::Find_Ratcliff_Diff3 0 1 1 1 $text_cont(1) $text_cont(2) $text_cont(3)
                    }
                }
            }
        }
    }
    return $result
}

#===============================================================================

set ::Yadt::Merge_Text_Widget_Proc {

    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::MERGE_START
    variable ::Yadt::WDG_OPTIONS
    variable ::Yadt::MERGE_TEXT_WDG

    set real "[ lindex [ info level [ info level ] ] 0 ]_"

    set result [ eval $real $command $args ]
    if { $command == "mark" } {
        if { [ lindex $args 0 ] == "set" && [ lindex $args 1 ] == "insert" } {
            set WDG_OPTIONS(cursor_position) ""
            for { set i $MERGE_START } { $i <= $DIFF_TYPE } { incr i } {
                if { "${WDG_OPTIONS(active_window)}_" == "$MERGE_TEXT_WDG($i)_" } {
                    foreach { ln col } [ split [ $WDG_OPTIONS(active_window) index insert ] "." ] { }
                    set WDG_OPTIONS(cursor_position) "Line: $ln Col: $col"
                }
            }
        }
    }

    return $result
}

#===============================================================================

proc ::Yadt::Update_Line_By_Line_Widget { { title "" } { content "" } } {

    variable ::Yadt::WIDGETS

    $WIDGETS(diff_lines_files) configure -state normal
    $WIDGETS(diff_lines_files) delete 1.0 end
    $WIDGETS(diff_lines_files) insert end $title
    $WIDGETS(diff_lines_files) configure -state disabled

    $WIDGETS(diff_lines_text) configure -state normal
    $WIDGETS(diff_lines_text) delete 1.0 end
    $WIDGETS(diff_lines_text) insert end $content
    $WIDGETS(diff_lines_text) configure -state disabled
}

#===============================================================================

proc ::Yadt::Draw_Menu { } {

    global CVS_REVISION
    variable ::Yadt::WIDGETS
    variable ::Yadt::OPTIONS
    variable ::Yadt::WDG_OPTIONS
    variable ::Yadt::MERGE_START
    variable ::Yadt::DIFF_TYPE

    # Setting menu labels
    set WIDGETS(menu_item,file) "File"
    set WIDGETS(menu_item,file,recompute) "Recompute Diffs"
    set WIDGETS(menu_item,file,save) "Save Merged File"
    set WIDGETS(menu_item,file,save_as) "Save Merged File As..."
    set WIDGETS(menu_item,file,write_cvs) "Write CVS-like Merge File"
    set WIDGETS(menu_item,file,save_exit) "Save Merged File and Exit"
    set WIDGETS(menu_item,file,exit) "Exit"

    set WIDGETS(menu_item,edit) "Edit"
    set WIDGETS(menu_item,edit,copy) "Copy"
    set WIDGETS(menu_item,edit,find) "Find..."
    set WIDGETS(menu_item,edit,preferences) "Preferences..."

    set WIDGETS(menu_item,view) "View"
    set WIDGETS(menu_item,view,split_view) "Split View"
    set WIDGETS(menu_item,view,split_view,vertically) "Vertically"
    set WIDGETS(menu_item,view,split_view,horizontaly) "Horizontally"
    set WIDGETS(menu_item,view,show_diff_lines) "Show Line Comparison"
    set WIDGETS(menu_item,view,show_inline) "Show Differences Inline"
    set WIDGETS(menu_item,view,sync_scroll) "Synchronize Scrollbars"
    set WIDGETS(menu_item,view,prev_conflict) "Prev Conflict"
    set WIDGETS(menu_item,view,first_diff) "First Diff"
    set WIDGETS(menu_item,view,prev_diff) "Prev Diff"
    set WIDGETS(menu_item,view,center_cur) "Center Current Diff"
    set WIDGETS(menu_item,view,next_diff) "Next Diff"
    set WIDGETS(menu_item,view,last_diff) "Last Diff"
    set WIDGETS(menu_item,view,next_conflict) "Next Conflict"

    for { set i $MERGE_START } { $i <= $DIFF_TYPE } { incr i } {

        set WIDGETS(menu_item,merge$i,mode) "Mode"
        set WIDGETS(menu_item,merge$i,mode,normal) "Normal"
        set WIDGETS(menu_item,merge$i,mode,expert) "Expert"

        if { $MERGE_START == $DIFF_TYPE } {
            set WIDGETS(menu_item,merge$i) "Merge"
        } else {
            set WIDGETS(menu_item,merge$i) "Merge[ expr $i - 1 ]"
        }
        if { $OPTIONS(preview_shown) } {
            set WIDGETS(menu_item,merge$i,show_merge) "Hide Merge Window"
        } else {
            set WIDGETS(menu_item,merge$i,show_merge) "Show Merge Window"
        }
        set WIDGETS(menu_item,merge$i,all_diff_from_a) "Take All Diffs From File A"
        set WIDGETS(menu_item,merge$i,all_diff_from_b) "Take All Diffs From File B"
        set WIDGETS(menu_item,merge$i,all_diff_from_c) "Take All Diffs From File C"
        set WIDGETS(menu_item,merge$i,mark_resolved) "Mark Current Diff As Resolved"
        set WIDGETS(menu_item,merge$i,mark_all_diff_resolved) "Mark All Diffs As Resolved"
        set WIDGETS(menu_item,merge$i,mark_all_confl_resolved) "Mark All Conflicts As Resolved"
        set WIDGETS(menu_item,merge$i,auto_merge) "Try auto-merge"
    }

    set WIDGETS(menu_item,help) "Help"
    set WIDGETS(menu_item,help,about) "About"
    set WIDGETS(menu_item,help,usage) "Usage"
    set WIDGETS(menu_item,help,help) "Show $WDG_OPTIONS(yadt_title) Help"

    menu $WIDGETS(window_name).menu \
        -tearoff 0 \
        -relief raised \
        -bd 1 \
        -activeborder 1

    # Menu File
    set WIDGETS(menu_file) $WIDGETS(window_name).menu.file
    menu $WIDGETS(menu_file) \
        -tearoff 0 \
        -relief raised \
        -bd 1 \
        -activeborder 1 \
        -activebackground black \
        -activeforeground yellow

    $WIDGETS(window_name).menu add cascade \
        -label $WIDGETS(menu_item,file) \
        -menu $WIDGETS(menu_file) \
        -underline 0
    $WIDGETS(menu_file) add command \
        -label $WIDGETS(menu_item,file,recompute) \
        -command "::Yadt::Recompute_Diffs" \
        -state normal \
        -image refreshImage \
        -compound left \
        -underline 0
    $WIDGETS(menu_file) add separator

    set state [ expr { $OPTIONS(save_always_enabled) ? "normal" : "disabled" } ]
    $WIDGETS(menu_file) add command \
        -label $WIDGETS(menu_item,file,save) \
        -command "::Yadt::Save_Merged_Files" \
        -image saveImage \
        -compound left \
        -state $state \
        -underline 0

    $WIDGETS(menu_file) add command \
        -label $WIDGETS(menu_item,file,save_as) \
        -command [ list ::Yadt::Save_Merged_Files -save_as 1 ] \
        -image saveImage \
        -compound left \
        -state $state \
        -underline 0

    if { $DIFF_TYPE == 3 } {
        $WIDGETS(menu_file) add command \
            -label $WIDGETS(menu_item,file,write_cvs) \
            -command "::Yadt::Save_CVS_Like_Merge_File" \
            -image saveImage \
            -compound left \
            -state disabled \
            -underline 14
    }

    $WIDGETS(menu_file) add separator
    $WIDGETS(menu_file) add command \
        -label $WIDGETS(menu_item,file,save_exit) \
        -command "::Yadt::Save_And_Exit" \
        -image saveExitImage \
        -compound left \
        -state $state \
        -underline 1
    $WIDGETS(menu_file) add command \
        -label $WIDGETS(menu_item,file,exit) \
        -image stopImage \
        -compound left \
        -command "Yadt::Exit" \
        -underline 1

    # Menu Edit
    set WIDGETS(menu_edit) $WIDGETS(window_name).menu.edit
    menu $WIDGETS(menu_edit) \
        -tearoff 0 \
        -relief raised \
        -bd 1 \
        -activeborder 1 \
        -activebackground black \
        -activeforeground yellow

    $WIDGETS(window_name).menu add cascade \
        -label $WIDGETS(menu_item,edit) \
        -menu $WIDGETS(menu_edit) \
        -underline 0

    $WIDGETS(menu_edit) add command \
        -label $WIDGETS(menu_item,edit,copy) \
        -image copyImage \
        -compound left \
        -underline 0 \
        -accelerator "Control-C" \
        -command [ list ::Yadt::Edit_Copy ]
    $WIDGETS(menu_edit) add separator
    $WIDGETS(menu_edit) add command \
        -label $WIDGETS(menu_item,edit,find) \
        -image findImage \
        -compound left \
        -underline 0 \
        -accelerator "Control-F" \
        -command "
               ::Yadt::Pack_Find_Bar
               ::Yadt::Find_In_Text -forward 1
           "
    $WIDGETS(menu_edit) add separator
    $WIDGETS(menu_edit) add command \
        -label $WIDGETS(menu_item,edit,preferences) \
        -image preferencesImage \
        -compound left \
        -underline 0 \
        -accelerator "Control-O" \
        -command "::Yadt::Show_Preferences"

    # Menu View
    set WIDGETS(menu_view) $WIDGETS(window_name).menu.view
    menu $WIDGETS(menu_view) \
        -tearoff 0 \
        -relief raised \
        -bd 1 \
        -activeborder 1 \
        -activebackground black \
        -activeforeground yellow

    $WIDGETS(window_name).menu add cascade \
        -label $WIDGETS(menu_item,view) \
        -menu $WIDGETS(menu_view) \
        -underline 0

    set WIDGETS(menu_view_layout) $WIDGETS(window_name).menu.view.layout
    menu $WIDGETS(menu_view_layout) \
        -tearoff 0 \
        -relief raised \
        -bd 1 \
        -activeborder 1 \
        -activebackground black \
        -activeforeground yellow

    $WIDGETS(menu_view_layout) add radiobutton \
        -label $WIDGETS(menu_item,view,split_view,vertically) \
        -underline 0 \
        -value "vertical" \
        -variable ::Yadt::OPTIONS(diff_layout) \
        -command "::Yadt::Change_Layout"

    $WIDGETS(menu_view_layout) add radiobutton \
        -label $WIDGETS(menu_item,view,split_view,horizontaly) \
        -underline 0 \
        -value "horizontal" \
        -variable ::Yadt::OPTIONS(diff_layout) \
        -command "::Yadt::Change_Layout"

    $WIDGETS(menu_view) add cascade \
        -label $WIDGETS(menu_item,view,split_view) \
        -menu $WIDGETS(menu_view_layout) \
        -underline 11

    $WIDGETS(menu_view) add checkbutton \
        -label $WIDGETS(menu_item,view,show_diff_lines) \
        -underline 11 \
        -variable ::Yadt::OPTIONS(show_diff_lines) \
        -command ::Yadt::Toggle_Diff_Lines

    $WIDGETS(menu_view) add checkbutton \
        -label $WIDGETS(menu_item,view,show_inline) \
        -underline 17 \
        -variable ::Yadt::OPTIONS(show_inline) \
        -command ::Yadt::Toggle_Inline_Tags

    $WIDGETS(menu_view) add separator

    $WIDGETS(menu_view) add checkbutton \
        -label $WIDGETS(menu_item,view,sync_scroll) \
        -underline 0 \
        -variable ::Yadt::OPTIONS(syncscroll) \
        -command ::Yadt::Toggle_Sync_Scroll
    $WIDGETS(menu_view) add separator

    if { $DIFF_TYPE == 3 } {
        $WIDGETS(menu_view) add command \
            -label $WIDGETS(menu_item,view,prev_conflict) \
            -image prevConflImage \
            -compound left \
            -accelerator "Control-P" \
            -command [ list ::Yadt::Goto_Conflict -1 ]
    }

    $WIDGETS(menu_view) add command \
        -label $WIDGETS(menu_item,view,first_diff) \
        -image firstDiffImage \
        -compound left \
        -underline 0 \
        -accelerator "F" \
        -command [ list ::Yadt::Set_Diff_Indicator first ]

    $WIDGETS(menu_view) add command \
        -label $WIDGETS(menu_item,view,prev_diff) \
        -image prevDiffImage \
        -compound left \
        -underline 0 \
        -accelerator "P" \
        -command [ list ::Yadt::Set_Diff_Indicator -1 ]
    $WIDGETS(menu_view) add command \
        -label $WIDGETS(menu_item,view,center_cur) \
        -image centerDiffImage \
        -compound left \
        -underline 0 \
        -accelerator "C" \
        -command ::Yadt::Diff_Center
    $WIDGETS(menu_view) add command \
        -label $WIDGETS(menu_item,view,next_diff) \
        -image nextDiffImage \
        -compound left \
        -underline 0 \
        -accelerator "N" \
        -command [ list ::Yadt::Set_Diff_Indicator 1 ]
    $WIDGETS(menu_view) add command \
        -label $WIDGETS(menu_item,view,last_diff) \
        -image lastDiffImage \
        -compound left \
        -underline 0 \
        -accelerator "L" \
        -command [ list ::Yadt::Set_Diff_Indicator last ]

    if { $DIFF_TYPE == 3 } {
        $WIDGETS(menu_view) add command \
            -label $WIDGETS(menu_item,view,next_conflict) \
            -image nextConflImage \
            -compound left \
            -accelerator "Control-N" \
            -command [ list ::Yadt::Goto_Conflict 1 ]
    }

    # Menu Merge
    for { set i $MERGE_START } { $i <= $DIFF_TYPE } { incr i } {
        set WIDGETS(menu_merge$i) $WIDGETS(window_name).menu.merge$i

        menu $WIDGETS(menu_merge$i) \
            -tearoff 0 \
            -relief raised \
            -bd 1 \
            -activeborder 1 \
            -activebackground black \
            -activeforeground yellow

        if { $DIFF_TYPE == 3 } {

            set WIDGETS(menu_mode) $WIDGETS(window_name).menu.merge$i.mode
            menu $WIDGETS(menu_mode) \
                -tearoff 0 \
                -relief raised \
                -bd 1 \
                -activeborder 1 \
                -activebackground black \
                -activeforeground yellow

            $WIDGETS(menu_mode) add radiobutton \
                -label  $WIDGETS(menu_item,merge$i,mode,normal) \
                -underline 1 \
                -accelerator "O" \
                -value "normal" \
                -variable ::Yadt::OPTIONS(merge_mode) \
                -command [ list ::Yadt::Toggle_Merge_Mode ]

            $WIDGETS(menu_mode) add radiobutton \
                -label  $WIDGETS(menu_item,merge$i,mode,expert) \
                -underline 1 \
                -accelerator "X" \
                -value "expert" \
                -variable ::Yadt::OPTIONS(merge_mode) \
                -command [ list ::Yadt::Toggle_Merge_Mode ]

            $WIDGETS(menu_merge$i) add cascade \
                -label $WIDGETS(menu_item,merge$i,mode) \
                -menu  $WIDGETS(menu_mode) \
                -underline 0
        }

        $WIDGETS(menu_merge$i) add checkbutton \
            -label $WIDGETS(menu_item,merge$i,show_merge) \
            -image previewImage \
            -compound left \
            -indicatoron 0 \
            -underline 11 \
            -state normal \
            -variable ::Yadt::OPTIONS(preview_shown) \
            -command "::Yadt::Toggle_Merge_Window"

        $WIDGETS(menu_merge$i) add command \
            -label $WIDGETS(menu_item,merge$i,all_diff_from_a) \
            -image A_ch_Image \
            -compound left \
            -underline 25 \
            -command "::Yadt::Merge_All $i 1"

        $WIDGETS(menu_merge$i) add command \
            -label $WIDGETS(menu_item,merge$i,all_diff_from_b) \
            -image B_ch_Image \
            -compound left \
            -underline 25 \
            -command "::Yadt::Merge_All $i 2"

        if { $DIFF_TYPE == 3 } {
            $WIDGETS(menu_merge$i) add command \
                -label $WIDGETS(menu_item,merge$i,all_diff_from_c) \
                -image C_ch_Image \
                -compound left \
                -underline 25 \
                -command "::Yadt::Merge_All $i 3"
        }

        $WIDGETS(window_name).menu add cascade \
            -menu $WIDGETS(menu_merge$i) \
            -label $WIDGETS(menu_item,merge$i) \
            -underline 0

        if { $DIFF_TYPE == 3 } {
            $WIDGETS(menu_merge$i) add separator

            $WIDGETS(menu_merge$i) add command \
                -label $WIDGETS(menu_item,merge$i,mark_resolved) \
                -image markImage \
                -compound left \
                -underline 0 \
                -command "::Yadt::Mark_Resolve_Handle $i mark_resolved -mark -current"

            $WIDGETS(menu_merge$i) add command \
                -label $WIDGETS(menu_item,merge$i,mark_all_diff_resolved) \
                -image markAllImage \
                -compound left \
                -underline 9 \
                -command "::Yadt::Mark_Resolve_Handle $i mark_all_diff_resolved -mark -all"

            $WIDGETS(menu_merge$i) add command \
                -label $WIDGETS(menu_item,merge$i,mark_all_confl_resolved) \
                -image markAllConflictImage \
                -compound left \
                -underline 12 \
                -command "::Yadt::Mark_Resolve_Handle $i mark_all_confl_resolved -mark -conflict"

            $WIDGETS(menu_merge$i) add separator
            $WIDGETS(menu_merge$i) add command \
                -label $WIDGETS(menu_item,merge$i,auto_merge) \
                -image automergeImage \
                -compound left \
                -underline 0 \
                -command "::Yadt::Auto_Merge3"
        }
    }

    # Menu Help
    set WIDGETS(menu_help) $WIDGETS(window_name).menu.help
    menu $WIDGETS(menu_help) \
        -tearoff 0 \
        -relief raised \
        -bd 1 \
        -activeborder 1 \
        -activebackground black \
        -activeforeground yellow

    $WIDGETS(window_name).menu add cascade \
        -label $WIDGETS(menu_item,help) \
        -menu $WIDGETS(menu_help) \
        -underline 0

    set about_msg "YaDT - yet-another-diff-tool.\n\
                  Revision: $CVS_REVISION\n\n\
                  Allows to compare two or three files with merge possibility."
    $WIDGETS(menu_help) add command \
        -label $WIDGETS(menu_item,help,about) \
        -image aboutImage \
        -compound left \
        -underline 0 \
        -command [ list tk_messageBox -parent $WIDGETS(window_name) \
                       -title "About Yadt" \
                       -icon info \
                       -type ok \
                       -message $about_msg ]
    $WIDGETS(menu_help) add command \
        -label $WIDGETS(menu_item,help,usage) \
        -image helpImage \
        -compound left \
        -underline 0 \
        -command ::Yadt::Usage
    $WIDGETS(menu_help) add command \
        -label $WIDGETS(menu_item,help,help) \
        -image showHelpImage \
        -compound left \
        -underline 0 \
        -command ::Yadt::Show_Help

    $WIDGETS(window_name) configure -menu $WIDGETS(window_name).menu

    bind Menu <<MenuSelect>> {
        ::Yadt::Show_Tooltip menu %W
    }
}

#===============================================================================

proc ::Yadt::Create_Popup_Merge_Mode_Switch_Menu {} {

    variable ::Yadt::WIDGETS
    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::OPTIONS

    if { $DIFF_TYPE == 2 } return

    set WIDGETS(popup_merge_mode_menu) .yadt_merge_mode_popupMenu
    if [ winfo exists $WIDGETS(popup_merge_mode_menu) ] {
        destroy $WIDGETS(popup_merge_mode_menu)
    }

     menu $WIDGETS(popup_merge_mode_menu) \
        -tearoff 0 \
        -relief raised \
        -bd 1 \
        -activeborder 1 \
        -activebackground black \
        -activeforeground yellow

    $WIDGETS(popup_merge_mode_menu) add radiobutton \
        -label "Normal Merge Mode" \
        -compound left \
        -underline 1 \
        -variable ::Yadt::OPTIONS(merge_mode) \
        -value "normal" \
        -command [ list ::Yadt::Toggle_Merge_Mode ] \
        -accelerator "O"

    $WIDGETS(popup_merge_mode_menu) add radiobutton \
        -label "Expert Merge Mode" \
        -compound left \
        -underline 1 \
        -variable ::Yadt::OPTIONS(merge_mode) \
        -value "expert" \
        -command [ list ::Yadt::Toggle_Merge_Mode ] \
        -accelerator "X"
}

#===============================================================================

proc ::Yadt::Create_Popup_Menu {} {

    variable ::Yadt::WIDGETS
    variable ::Yadt::DIFF_TYPE

    set WIDGETS(popup_menu) .yadt_popupMenu
    if [ winfo exists $WIDGETS(popup_menu) ] {
        destroy $WIDGETS(popup_menu)
    }

    # Setting menu labels
    set WIDGETS(popup_item,normal_merge) "Normal Merge Mode"
    set WIDGETS(popup_item,expert_merge) "Expert Merge Mode"
    set WIDGETS(popup_item,prev_conflict) "Previous Conflict"
    set WIDGETS(popup_item,first_diff) "First Diff"
    set WIDGETS(popup_item,prev_diff) "Previous Diff"
    set WIDGETS(popup_item,center_cur) "Center Current Diff"
    set WIDGETS(popup_item,next_diff) "Next Diff"
    set WIDGETS(popup_item,last_diff) "Last Diff"
    set WIDGETS(popup_item,next_conflict) "Next Conflict"
    set WIDGETS(popup_item,find_nearest) "Find Nearest Diff"

    menu $WIDGETS(popup_menu) \
        -tearoff 0 \
        -relief raised \
        -bd 1 \
        -activeborder 1 \
        -activebackground black \
        -activeforeground yellow

    set m $WIDGETS(popup_menu)

    if { $DIFF_TYPE == 3 } {
        $m add radiobutton \
            -label $WIDGETS(popup_item,normal_merge) \
            -compound left \
            -underline 1 \
            -variable ::Yadt::OPTIONS(merge_mode) \
            -value "normal" \
            -command [ list ::Yadt::Toggle_Merge_Mode ] \
            -accelerator "O"

        $m add radiobutton \
            -label $WIDGETS(popup_item,expert_merge) \
            -compound left \
            -underline 1 \
            -variable ::Yadt::OPTIONS(merge_mode) \
            -value "expert" \
            -command [ list ::Yadt::Toggle_Merge_Mode ] \
            -accelerator "X"

        $m add separator

        $m add command \
            -label $WIDGETS(popup_item,prev_conflict) \
            -image prevConflImage \
            -compound left \
            -accelerator "Control-P" \
            -command [ list ::Yadt::Popup_Menu_Invoke -prev_conflict ]
    }

    $m add command \
        -label $WIDGETS(popup_item,first_diff) \
        -image firstDiffImage \
        -compound left \
        -underline 0 \
        -command [ list ::Yadt::Popup_Menu_Invoke -first ] \
        -accelerator "F"
    $m add command \
        -label $WIDGETS(popup_item,prev_diff) \
        -image prevDiffImage \
        -compound left \
        -underline 0 \
        -command [ list ::Yadt::Popup_Menu_Invoke -prev ] \
        -accelerator "P"
    $m add command \
        -label $WIDGETS(popup_item,center_cur) \
        -image centerDiffImage \
        -compound left \
        -underline 0 \
        -command [ list ::Yadt::Popup_Menu_Invoke -center ] \
        -accelerator "C"
    $m add command \
        -label $WIDGETS(popup_item,next_diff) \
        -image nextDiffImage \
        -compound left \
        -underline 0 \
        -command [ list ::Yadt::Popup_Menu_Invoke -next ] \
        -accelerator "N"
    $m add command \
        -label $WIDGETS(popup_item,last_diff) \
        -image lastDiffImage \
        -compound left \
        -underline 0 \
        -command [ list ::Yadt::Popup_Menu_Invoke -last ] \
        -accelerator "L"

    if { $DIFF_TYPE == 3 } {
        $m add command \
            -label $WIDGETS(popup_item,next_conflict) \
            -image nextConflImage \
            -compound left \
            -accelerator "Control-N" \
            -command [ list ::Yadt::Popup_Menu_Invoke -next_conflict ]
    }

    $m add separator
    $m add command \
        -label $WIDGETS(popup_item,find_nearest) \
        -underline 0 \
        -command [ list ::Yadt::Popup_Menu_Invoke -nearest ] \
        -accelerator "Double-Click"
}

#===============================================================================

proc ::Yadt:::Show_Merge_Mode_Popup_Menu { x y } {

    variable ::Yadt::WIDGETS

    tk_popup $WIDGETS(popup_merge_mode_menu) $x $y
}

#===============================================================================

proc ::Yadt:::Show_Popup_Menu { x y } {

    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::WIDGETS
    variable ::Yadt::WDG_OPTIONS
    variable ::Yadt::TEXT_WDG
    variable ::Yadt::TEXT_NUM_WDG
    variable ::Yadt::TEXT_INFO_WDG

    set window [ winfo containing $x $y ]

    if { [ winfo class $window ] == "Text" } {
        $WIDGETS(popup_menu) entryconfigure $WIDGETS(popup_item,find_nearest) -state normal

        for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
            if { $window == $TEXT_INFO_WDG($i) || \
                $window == $TEXT_NUM_WDG($i)  || \
                $window == $TEXT_WDG($i) } {
                set WDG_OPTIONS(active_window) $TEXT_WDG($i)
                ::Yadt::Set_Find_Element
                break
            }
        }

    } else {
        $WIDGETS(popup_menu) entryconfigure $WIDGETS(popup_item,find_nearest) -state disabled
    }

    set WDG_OPTIONS(popup_x) $x
    set WDG_OPTIONS(popup_y) $y

    tk_popup $WIDGETS(popup_menu) $x $y
}

#===============================================================================

proc ::Yadt::Draw_Toolbar_Elements { } {

    variable ::Yadt::WIDGETS
    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::MERGE_START

    set WIDGETS(tool_bar) [ ::ttk::frame $WIDGETS(window_name).toolbar -relief groove -style Toolbutton ]
    pack $WIDGETS(tool_bar) -side top -fill x -expand 0

    ::Yadt::Draw_Common_Toolbar_Elements

    switch -- $DIFF_TYPE {
        2 {
            ::Yadt::Draw_Combo_Toolbar_Element
            ::Yadt::Draw_Toolbar_Separator $WIDGETS(tool_bar).sep1
            ::Yadt::Draw_Navigation_Toolbar_Elements
            ::Yadt::Draw_Toolbar_Separator $WIDGETS(tool_bar).sep2
            ::Yadt::Draw_Toolbar_Elements2
            ::Yadt::Draw_Toolbar_Separator $WIDGETS(tool_bar).sep3
        }
        3 {
            ::Yadt::Draw_Combo_Toolbar_Element
            ::Yadt::Draw_Toolbar_Separator $WIDGETS(tool_bar).sep1
            if { $MERGE_START == 2 } {
                ::Yadt::Draw_Toolbar_Elements3 2
                ::Yadt::Draw_Toolbar_Separator $WIDGETS(tool_bar).sep2
                ::Yadt::Draw_Resolve_Status_Elements 2
                ::Yadt::Draw_Toolbar_Separator $WIDGETS(tool_bar).sep3
            }

            ::Yadt::Draw_Navigation_Toolbar_Elements
            ::Yadt::Draw_Toolbar_Separator $WIDGETS(tool_bar).sep4
            ::Yadt::Draw_Toolbar_Elements3 3         
            ::Yadt::Draw_Toolbar_Separator $WIDGETS(tool_bar).sep5
            ::Yadt::Draw_Resolve_Status_Elements 3
            ::Yadt::Draw_Toolbar_Separator $WIDGETS(tool_bar).sep6
        }
    }
}

#===============================================================================

proc ::Yadt::Draw_Combo_Toolbar_Element {} {

    variable ::Yadt::WIDGETS
    variable ::Yadt::OPTIONS
    variable ::Yadt::WDG_OPTIONS

    set elements {}

    set WIDGETS(diff_combo) \
        [ ::ttk::combobox $WIDGETS(tool_bar).diff_combo \
              -width 10 \
              -state readonly \
              -takefocus 0 \
              -exportselection 0 \
              -textvariable ::Yadt::WDG_OPTIONS(curr_diff) ]

    bind $WIDGETS(diff_combo) <<ComboboxSelected>> ::Yadt::Move_Indicator_To
    pack $WIDGETS(diff_combo) -side right -padx 5

    set WDG_OPTIONS(tooltip,$WIDGETS(diff_combo)) \
        "List of found differences"
    lappend elements $WIDGETS(diff_combo)

    ::ttk::checkbutton $WIDGETS(tool_bar).ignore_blanks \
        -text "Ignore Blanks" \
        -offvalue 0 \
        -onvalue 1 \
        -variable ::Yadt::OPTIONS(ignore_blanks) \
        -takefocus 0 \
        -state disabled \
        -command ::Yadt::Recompute_Diff_On_Bs_Change
                 
    pack $WIDGETS(tool_bar).ignore_blanks -side right
    set WDG_OPTIONS(tooltip,$WIDGETS(tool_bar).ignore_blanks) \
        "Recompute ignoring blanks"
    lappend elements $WIDGETS(tool_bar).ignore_blanks

    set WIDGETS(b_recompute) \
        [ ::ttk::button $WIDGETS(tool_bar).b_recompute \
              -text R \
              -image refreshImage \
              -takefocus 0 \
              -state normal \
              -style Toolbutton \
              -command "::Yadt::Recompute_Diffs" ]
    set WDG_OPTIONS(tooltip,$WIDGETS(tool_bar).b_recompute) \
        "Recompute differences"
    lappend elements $WIDGETS(tool_bar).b_recompute

    pack $WIDGETS(b_recompute) -side right -padx 5

    ::Yadt::Bind_Toolbar_Events $elements
}

#===============================================================================

proc ::Yadt::Draw_Toolbar_Elements2 {} {

    variable ::Yadt::WIDGETS
    variable ::Yadt::WDG_OPTIONS
    variable ::Yadt::OPTIONS

    set elements {}

    ::ttk::checkbutton $WIDGETS(tool_bar).choice_A \
        -text "A" \
        -image A_Image \
        -takefocus 0 \
        -variable ::Yadt::WDG_OPTIONS(toggleA) \
        -state disabled \
        -style Toolbutton \
        -command [ list ::Yadt::Handle_Choice_Buttons2 1 ]
    set WDG_OPTIONS(tooltip,$WIDGETS(tool_bar).choice_A) \
        "Choose lines from A for merge"
    lappend elements $WIDGETS(tool_bar).choice_A

    ::ttk::checkbutton $WIDGETS(tool_bar).choice_B \
        -text "B" \
        -image B_Image \
        -takefocus 0 \
        -variable ::Yadt::WDG_OPTIONS(toggleB) \
        -state disabled \
        -style Toolbutton \
        -command [ list ::Yadt::Handle_Choice_Buttons2 2 ]
    set WDG_OPTIONS(tooltip,$WIDGETS(tool_bar).choice_B) \
        "Choose lines from B for merge"
    lappend elements $WIDGETS(tool_bar).choice_B

    pack $WIDGETS(tool_bar).choice_A \
         $WIDGETS(tool_bar).choice_B \
         -side left \
         -padx 2

    ::Yadt::Bind_Toolbar_Events $elements
}

#===============================================================================

proc ::Yadt::Draw_Toolbar_Elements3 { type } {

    variable ::Yadt::WIDGETS
    variable ::Yadt::WDG_OPTIONS
    variable ::Yadt::OPTIONS
    variable ::Yadt::MERGE_START

    set elements {}

    if { $type == 2 || $type == 23 } {

        ::ttk::checkbutton $WIDGETS(tool_bar).choice2_A \
            -text "A" \
            -image A_Image \
            -takefocus 0 \
            -variable ::Yadt::WDG_OPTIONS(toggle32A) \
            -state disabled \
            -style Toolbutton \
            -command [ list ::Yadt::Handle_Choice_Buttons3 2 1 ]
        set WDG_OPTIONS(tooltip,$WIDGETS(tool_bar).choice2_A) \
            "Choose lines from A for merging in Merge 1"
        lappend elements $WIDGETS(tool_bar).choice2_A

        ::ttk::checkbutton $WIDGETS(tool_bar).choice2_B \
            -text "B" \
            -image B_Image \
            -takefocus 0 \
            -variable ::Yadt::WDG_OPTIONS(toggle32B) \
            -state disabled \
            -style Toolbutton \
            -command [ list ::Yadt::Handle_Choice_Buttons3 2 2 ]
        set WDG_OPTIONS(tooltip,$WIDGETS(tool_bar).choice2_B) \
            "Choose lines from B for merging in Merge 1"
        lappend elements $WIDGETS(tool_bar).choice2_B

        ::ttk::checkbutton $WIDGETS(tool_bar).choice2_C \
            -text "C" \
            -image C_Image \
            -takefocus 0 \
            -variable ::Yadt::WDG_OPTIONS(toggle32C) \
            -state disabled \
            -style Toolbutton \
            -command [ list ::Yadt::Handle_Choice_Buttons3 2 3 ]
        set WDG_OPTIONS(tooltip,$WIDGETS(tool_bar).choice2_C) \
            "Choose lines from C for merging in Merge 1"
        lappend elements $WIDGETS(tool_bar).choice2_C

        pack $WIDGETS(tool_bar).choice2_A \
             $WIDGETS(tool_bar).choice2_B \
             $WIDGETS(tool_bar).choice2_C \
             -side left \
             -padx 2
    }

    if { $type == 3 || $type == 23 } {
        ::ttk::checkbutton $WIDGETS(tool_bar).choice3_A \
            -text "A" \
            -image A_Image \
            -takefocus 0 \
            -variable ::Yadt::WDG_OPTIONS(toggle33A) \
            -state disabled \
            -style Toolbutton \
            -command [ list ::Yadt::Handle_Choice_Buttons3 3 1 ]
        set WDG_OPTIONS(tooltip,$WIDGETS(tool_bar).choice3_A) \
            "Choose lines from A for merging"
        if { $MERGE_START == 2 } {
            append WDG_OPTIONS(tooltip,$WIDGETS(tool_bar).choice3_A) " in Merge 2"
        }
        lappend elements $WIDGETS(tool_bar).choice3_A

        ::ttk::checkbutton $WIDGETS(tool_bar).choice3_B \
            -text "B" \
            -image B_Image \
            -takefocus 0 \
            -variable ::Yadt::WDG_OPTIONS(toggle33B) \
            -state disabled \
            -style Toolbutton \
            -command [ list ::Yadt::Handle_Choice_Buttons3 3 2 ]
        set WDG_OPTIONS(tooltip,$WIDGETS(tool_bar).choice3_B) \
            "Choose lines from B for merging"
        if { $MERGE_START == 2 } {
            append WDG_OPTIONS(tooltip,$WIDGETS(tool_bar).choice3_B) " in Merge 2"
        }
        lappend elements $WIDGETS(tool_bar).choice3_B

        ::ttk::checkbutton $WIDGETS(tool_bar).choice3_C \
            -text "C" \
            -image C_Image \
            -takefocus 0 \
            -variable ::Yadt::WDG_OPTIONS(toggle33C) \
            -state disabled \
            -style Toolbutton \
            -command [ list ::Yadt::Handle_Choice_Buttons3 3 3 ]
        set WDG_OPTIONS(tooltip,$WIDGETS(tool_bar).choice3_C) \
            "Choose lines from C for merging"
        if { $MERGE_START == 2 } {
            append WDG_OPTIONS(tooltip,$WIDGETS(tool_bar).choice3_C) " in Merge 2"
        }
        lappend elements $WIDGETS(tool_bar).choice3_C

        pack $WIDGETS(tool_bar).choice3_A \
            $WIDGETS(tool_bar).choice3_B \
            $WIDGETS(tool_bar).choice3_C \
            -side left \
            -padx 2
    }

    ::Yadt::Bind_Toolbar_Events $elements
}

#===============================================================================

proc ::Yadt::Draw_Resolve_Status_Elements { target } {

    variable ::Yadt::WIDGETS
    variable ::Yadt::OPTIONS
    variable ::Yadt::WDG_OPTIONS

    set WIDGETS(prev_unresolved_$target) \
        [ ::ttk::button $WIDGETS(tool_bar).prev_unresolved_$target \
              -text "<=" \
              -image prevUnresolvImage \
              -takefocus 0 \
              -state disabled \
              -style Toolbutton \
              -command "::Yadt::Goto_Unresolved -1 $target" ]
    set WDG_OPTIONS(tooltip,$WIDGETS(prev_unresolved_$target)) \
        "Go to the previous unresolved difference"
    lappend elements $WIDGETS(prev_unresolved_$target)

    set WIDGETS(mark$target) $WIDGETS(tool_bar).mark$target
    ::ttk::checkbutton $WIDGETS(mark$target) \
        -onvalue 1 \
        -offvalue 0 \
        -text "mark$target" \
        -image markImage \
        -takefocus 0 \
        -state disabled \
        -style Toolbutton \
        -variable ::Yadt::WDG_OPTIONS(resolve_status_$target) \
        -command [ list ::Yadt::Resolve_Handle $target ]
    set WDG_OPTIONS(tooltip,$WIDGETS(mark$target)) \
        "Mark current difference as resolved"
    lappend elements $WIDGETS(mark$target)

    set WIDGETS(next_unresolved_$target) \
        [ ::ttk::button $WIDGETS(tool_bar).next_unresolved_$target \
              -text "=>" \
              -image nextUnresolvImage \
              -takefocus 0 \
              -state disabled \
              -style Toolbutton \
              -command "::Yadt::Goto_Unresolved 1 $target" ]
    set WDG_OPTIONS(tooltip,$WIDGETS(next_unresolved_$target)) \
        "Go to the next unresolved difference"
    lappend elements $WIDGETS(next_unresolved_$target)

    ::Yadt::Bind_Toolbar_Events $elements

    pack $WIDGETS(tool_bar).prev_unresolved_$target \
        $WIDGETS(mark$target) \
        $WIDGETS(tool_bar).next_unresolved_$target \
        -side left \
        -padx 2
}

#===============================================================================

proc ::Yadt::Draw_Navigation_Toolbar_Elements {} {

    variable ::Yadt::WIDGETS
    variable ::Yadt::OPTIONS
    variable ::Yadt::WDG_OPTIONS
    variable ::Yadt::DIFF_TYPE

    set elements {}

    if { $DIFF_TYPE == 3 } {
        set WIDGETS(move_prev_confl) \
            [ ::ttk::button $WIDGETS(tool_bar).move_prev_confl \
                  -text "<=" \
                  -image prevConflImage \
                  -takefocus 0 \
                  -state disabled \
                  -style Toolbutton \
                  -command [ list ::Yadt::Goto_Conflict -1 ] ]
        pack $WIDGETS(move_prev_confl) -side left
        set WDG_OPTIONS(tooltip,$WIDGETS(move_prev_confl)) \
            "Go to the previous conflict"
        lappend elements $WIDGETS(move_prev_confl)
    }

    set WIDGETS(move_first) \
        [ ::ttk::button $WIDGETS(tool_bar).move_first \
              -text "|<--" \
              -image firstDiffImage \
              -takefocus 0 \
              -state disabled \
              -style Toolbutton \
              -command [ list ::Yadt::Set_Diff_Indicator first ] ]
    pack $WIDGETS(move_first) -side left
    set WDG_OPTIONS(tooltip,$WIDGETS(move_first)) \
        "Go to the first difference"
    lappend elements $WIDGETS(move_first)

    set WIDGETS(move_prev) \
        [ ::ttk::button $WIDGETS(tool_bar).move_prev \
              -text "<--" \
              -image prevDiffImage \
              -takefocus 0 \
              -state disabled \
              -style Toolbutton \
              -command [ list ::Yadt::Set_Diff_Indicator -1 ] ]
    pack $WIDGETS(move_prev) -side left
    set WDG_OPTIONS(tooltip,$WIDGETS(move_prev)) \
        "Go to the previous difference"
    lappend elements $WIDGETS(move_prev)

    set WIDGETS(move_next) \
        [ ::ttk::button $WIDGETS(tool_bar).move_next \
              -text "-->" \
              -image nextDiffImage \
              -takefocus 0 \
              -state disabled \
              -style Toolbutton \
              -command [ list ::Yadt::Set_Diff_Indicator 1 ] ]
    pack $WIDGETS(move_next) -side left
    set WDG_OPTIONS(tooltip,$WIDGETS(move_next)) \
        "Go to the next difference"
    lappend elements $WIDGETS(move_next)

    set WIDGETS(move_last) \
        [ ::ttk::button $WIDGETS(tool_bar).move_last \
              -text "-->|" \
              -image lastDiffImage \
              -takefocus 0 \
              -state disabled \
              -style Toolbutton \
              -command [ list ::Yadt::Set_Diff_Indicator last ] ]
    pack $WIDGETS(move_last) -side left
    set WDG_OPTIONS(tooltip,$WIDGETS(move_last)) \
        "Go to the last difference"
    lappend elements $WIDGETS(move_last)

    if { $DIFF_TYPE == 3 } {
        set WIDGETS(move_next_confl) \
            [ ::ttk::button $WIDGETS(tool_bar).move_next_confl \
                  -text "<=" \
                  -image nextConflImage \
                  -takefocus 0 \
                  -state disabled \
                  -style Toolbutton \
                  -command [ list ::Yadt::Goto_Conflict 1 ] ]
        pack $WIDGETS(move_next_confl) -side left
        set WDG_OPTIONS(tooltip,$WIDGETS(move_next_confl)) \
            "Go to the next conflict"
        lappend elements $WIDGETS(move_next_confl)
    }

    ::Yadt::Bind_Toolbar_Events $elements
}

#===============================================================================

proc ::Yadt::Draw_Common_Toolbar_Elements {} {

    variable ::Yadt::WIDGETS
    variable ::Yadt::WDG_OPTIONS
    variable ::Yadt::OPTIONS
    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::MERGE_START

    set elements {}

    set state [ expr { $OPTIONS(save_always_enabled) ? "normal" : "disabled" } ]
    ::ttk::button $WIDGETS(tool_bar).save \
        -text "Save" \
        -image saveImage \
        -takefocus 0 \
        -state $state \
        -style Toolbutton \
        -command ::Yadt::Save_Merged_Files
    pack $WIDGETS(tool_bar).save -side left
    switch -- $DIFF_TYPE {
        2 {
            set WDG_OPTIONS(tooltip,$WIDGETS(tool_bar).save) \
                "Save merge file"
        }
        3 {
            if { $MERGE_START == $DIFF_TYPE } {
                set WDG_OPTIONS(tooltip,$WIDGETS(tool_bar).save) \
                    "Save merge file"
            } else {
                set WDG_OPTIONS(tooltip,$WIDGETS(tool_bar).save) \
                    "Save merge files"
            }
        }
    }
    lappend elements $WIDGETS(tool_bar).save

    ::ttk::button $WIDGETS(tool_bar).find \
        -text "Find" \
        -image findImage \
        -takefocus 0 \
        -style Toolbutton \
        -command "
               ::Yadt::Pack_Find_Bar
               ::Yadt::Find_In_Text -forward 1
           "
    pack $WIDGETS(tool_bar).find -side left
    set WDG_OPTIONS(tooltip,$WIDGETS(tool_bar).find) \
        "Show find bar to search for a string within either file"
    lappend elements $WIDGETS(tool_bar).find

    set WIDGETS(center_cur) \
        [ ::ttk::button $WIDGETS(tool_bar).center_cur \
              -text ">-<" \
              -image centerDiffImage \
              -takefocus 0 \
              -state disabled \
              -style Toolbutton \
              -command ::Yadt::Diff_Center ]
    pack $WIDGETS(center_cur) -side left
    set WDG_OPTIONS(tooltip,$WIDGETS(center_cur)) \
        "Center the display around the current diff record"
    lappend elements $WIDGETS(center_cur)

    set WIDGETS(preview_button) \
        [ ::ttk::checkbutton $WIDGETS(tool_bar).toggle_preview \
              -text "Preview" \
              -image previewImage \
              -takefocus 0 \
              -onvalue 1 \
              -offvalue 0 \
              -style Toolbutton \
              -variable ::Yadt::OPTIONS(preview_shown) \
              -command ::Yadt::Toggle_Merge_Window ]
    pack $WIDGETS(preview_button) -side left
    set WDG_OPTIONS(tooltip,$WIDGETS(preview_button)) \
        "Toggle merge preview window"
    lappend elements $WIDGETS(preview_button)

    ::Yadt::Bind_Toolbar_Events $elements
}

#===============================================================================

proc ::Yadt::Draw_Toolbar_Separator { wdg } {
    label $wdg \
        -image [ image create photo ] \
        -highlightthickness 0 \
        -bd 1 \
        -width 0 \
        -relief groove
    pack $wdg -side left -fill y -pady 2 -padx 2
    return $wdg
}

#===============================================================================

proc ::Yadt::Draw_Status_Bar {} {

    variable ::Yadt::WIDGETS
    variable ::Yadt::WDG_OPTIONS

    set WIDGETS(status_bar) [ frame $WIDGETS(window_name).statusbar -relief flat -bd 0 ]
    pack $WIDGETS(status_bar) -side bottom -fill x -expand 0 -pady 0 -padx 0

    label $WIDGETS(status_bar).menu_status \
        -textvariable ::Yadt::WDG_OPTIONS(menustatus) \
        -anchor w -relief sunken -bd 1
    pack $WIDGETS(status_bar).menu_status -side left -fill x -expand 1

    label $WIDGETS(status_bar).cursor_position \
        -textvariable ::Yadt::WDG_OPTIONS(cursor_position) \
        -anchor c -relief sunken -bd 1 -width 20
    pack $WIDGETS(status_bar).cursor_position -side left -fill x -expand 0

    label $WIDGETS(status_bar).diff_status \
        -textvariable ::Yadt::WDG_OPTIONS(diffstatus) \
        -anchor e -relief sunken -bd 1 -width 20
    pack $WIDGETS(status_bar).diff_status -side left -fill x -expand 0
}

#===============================================================================

proc ::Yadt::Draw_Find_Bar {} {

    variable ::Yadt::WIDGETS
    variable ::Yadt::OPTIONS
    variable ::Yadt::WDG_OPTIONS

    set elements {}
    set WIDGETS(find_bar) [ frame $WIDGETS(window_name).find_bar -relief sunken -bd 1 ]

    ::ttk::button $WIDGETS(find_bar).close_bar \
        -text Close \
        -image closeImage \
        -takefocus 0 \
        -style Toolbutton \
        -command ::Yadt::Unpack_Find_Bar
    pack $WIDGETS(find_bar).close_bar -side left
    set WDG_OPTIONS(tooltip,$WIDGETS(find_bar).close_bar) "Close find bar"
    lappend elements $WIDGETS(find_bar).close_bar

    label $WIDGETS(find_bar).find_label \
        -anchor w -relief flat -bd 1 -text "Find:" -width 5
    pack $WIDGETS(find_bar).find_label -side left

    set WIDGETS(find_text) \
        [ ::ttk::entry $WIDGETS(find_bar).find_text \
              -width 15 \
              -textvariable ::Yadt::WDG_OPTIONS(find_string) ]
    set WDG_OPTIONS(find_string) ""
    pack $WIDGETS(find_text) -side left -padx 5
    set WDG_OPTIONS(tooltip,$WIDGETS(find_text)) "Search string"
    lappend elements $WIDGETS(find_text)
    bind $WIDGETS(find_text) <KeyRelease> "::Yadt::Handle_Find_Entry %W"
    bind $WIDGETS(find_text) <Return> "::Yadt::Find_In_Text -forward 1 0"
    bind $WIDGETS(find_text) <Escape> ::Yadt::Unpack_Find_Bar
    set WDG_OPTIONS(last_search) ""

    label $WIDGETS(find_bar).in_label \
        -anchor w -relief flat -bd 1 -text "in:"
    pack $WIDGETS(find_bar).in_label -side left

    set WIDGETS(find_window_list) \
        [ ::ttk::combobox $WIDGETS(find_bar).find_wdg \
              -state readonly \
              -takefocus 0 \
              -textvariable ::Yadt::WDG_OPTIONS(find_where) ]

    ::Yadt::Update_Find_Combo_Values

    bind $WIDGETS(find_window_list) <<ComboboxSelected>> ::Yadt::Handle_Combo_Find_Where

    set WDG_OPTIONS(tooltip,$WIDGETS(find_window_list)) "Window where to find"
    lappend elements $WIDGETS(find_window_list)

    pack $WIDGETS(find_window_list) -side left -padx 0

    ::ttk::button $WIDGETS(find_bar).find_prev \
        -text "Find Previous" \
        -takefocus 0 \
        -image findPreviousImage \
        -style Toolbutton \
        -command [ list ::Yadt::Find_In_Text -backward 1 ]
    pack $WIDGETS(find_bar).find_prev -side left -padx 5
    set WDG_OPTIONS(tooltip,$WIDGETS(find_bar).find_prev) "Find previous"
    lappend elements $WIDGETS(find_bar).find_prev

    ::ttk::button $WIDGETS(find_bar).find_next \
        -text "Find Next" \
        -takefocus 0 \
        -image findNextImage \
        -style Toolbutton \
        -command [ list ::Yadt::Find_In_Text -forward 1 ]
    pack $WIDGETS(find_bar).find_next -side left -padx 5
    set WDG_OPTIONS(tooltip,$WIDGETS(find_bar).find_next) "Find next"
    lappend elements $WIDGETS(find_bar).find_next

    ::ttk::checkbutton $WIDGETS(find_bar).ignore_case \
        -text " Ignore Case " \
        -takefocus 0 \
        -onvalue "-nocase" \
        -offvalue "" \
        -variable ::Yadt::WDG_OPTIONS(ignore_case)
    set WDG_OPTIONS(ignore_case) ""
    pack $WIDGETS(find_bar).ignore_case -side left
    set WDG_OPTIONS(tooltip,$WIDGETS(find_bar).ignore_case) \
        "Toggle case ignoring during find"
    lappend elements $WIDGETS(find_bar).ignore_case

    ::ttk::checkbutton $WIDGETS(find_bar).find_type \
        -text " Regexp " \
        -takefocus 0 \
        -onvalue "-regexp" \
        -offvalue "-exact" \
        -variable ::Yadt::WDG_OPTIONS(find_type)
    set WDG_OPTIONS(find_type) "-exact"
    pack $WIDGETS(find_bar).find_type -side left
    set WDG_OPTIONS(tooltip,$WIDGETS(find_bar).find_type) \
        "When on - allows using regular expressions in search string"
    lappend elements $WIDGETS(find_bar).find_type

    ::Yadt::Bind_Toolbar_Events $elements
}

#===============================================================================

proc ::Yadt::Update_Find_Combo_Values {} {

    variable ::Yadt::WIDGETS
    variable ::Yadt::OPTIONS
    variable ::Yadt::WDG_OPTIONS

    if { $OPTIONS(preview_shown) } {
        set wdg_list [ concat [ ::Yadt::Get_Diff_Wdg_List 0 "text" ] \
                           [ ::Yadt::Get_Merge_Wdg_List 0 "text" ] ]
    } else {
        set wdg_list [ ::Yadt::Get_Diff_Wdg_List 0 "text" ]
    }
    set combo_values {}
    foreach wdg $wdg_list {
        lappend combo_values $WDG_OPTIONS($wdg)
    }
    $WIDGETS(find_window_list) configure -values $combo_values
}

#===============================================================================

proc ::Yadt::Watch_Cursor { wdgs } {

    foreach wdg $wdgs {
        $wdg configure -cursor watch
    }

    update
}

#===============================================================================

proc ::Yadt::Restore_Cursor { wdgs } {

    foreach wdg $wdgs {
        $wdg configure -cursor {}
    }

    update
}

#===============================================================================

################################################################################
# Line comparison procs                                                        #
# based on Ratcliff/Obershelp pattern recognition algorithm                    #
################################################################################

#===============================================================================

proc ::Yadt::Reset_Pos_Scrinline { diff_id } {

    variable ::Yadt::DIFF_INT
    variable ::Yadt::DIFF_TYPE

    array unset DIFF_INT scrinline,$diff_id,*
    for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
        set DIFF_INT(scrinline,$diff_id,$i) 0
    }
}

#===============================================================================

proc ::Yadt::Find_Ratcliff_Diff2 { diff_id l1 l2 s1 s2 } {

    if { $diff_id == 0 } {
        ::Yadt::Reset_Pos_Scrinline $diff_id
    }

    set len1 [ string length $s1 ]
    set len2 [ string length $s2 ]

    return [ ::Yadt::Fid_Ratcliff_Aux2 1 2 $diff_id $l1 $l2 $s1 0 $len1 $s2 0 $len2 ]
}

#===============================================================================

proc ::Yadt::Find_Ratcliff_Diff3 { diff_id l1 l2 l3 s1 s2 s3 } {

    if { $diff_id == 0 } {
        ::Yadt::Reset_Pos_Scrinline $diff_id
    }

    set len1 [ string length $s1 ]
    set len2 [ string length $s2 ]
    set len3 [ string length $s3 ]

    return [ ::Yadt::Fid_Ratcliff_Aux3 $diff_id $l1 $l2 $l3 $s1 0 $len1 $s2 0 $len2 $s3 0 $len3 ]
}

#===============================================================================

proc ::Yadt::Fid_Ratcliff_Aux2 { id1 id2 diff_id l1 l2 s1 off1 len1 s2 off2 len2 } {

    variable ::Yadt::WIDGETS
    variable ::Yadt::DIFF_INT

    if { $len1 <= 0 || $len2 <= 0 } {
        if { $len1 == 0 } {
            $WIDGETS(diff_lines_text) tag add instag $id2.$off2 "$id2.$off2+${len2}c"
            set DIFF_INT(scrinline,$diff_id,$id2,$DIFF_INT(scrinline,$diff_id,$id2)) \
                [ list $l2 $off2 [ expr $off2+$len2 ] instag ]
            incr DIFF_INT(scrinline,$diff_id,$id2)
        } elseif { $len2 == 0 } {
            $WIDGETS(diff_lines_text) tag add instag $id1.$off1 "$id1.$off1+${len1}c"
            set DIFF_INT(scrinline,$diff_id,$id1,$DIFF_INT(scrinline,$diff_id,$id1)) \
                [ list $l1 $off1 [ expr $off1+$len1 ] instag ]
            incr DIFF_INT(scrinline,$diff_id,$id1)
        }
        return
    }

    set lcsoff1 -1
    set lcsoff2 -1

    set ret [ ::Yadt::Longest_Common_Substring2 $s1 $off1 $len1 $s2 $off2 $len2 lcsoff1 lcsoff2 ]

    if { $ret > 0 } {
        set rightoff1 [ expr $lcsoff1 + $ret ]
        set rightoff2 [ expr $lcsoff2 + $ret ]

        if { $lcsoff1 > $off1 || $lcsoff2 > $off2 } {
            # left
            ::Yadt::Fid_Ratcliff_Aux2 $id1 $id2 $diff_id $l1 $l2 $s1 $off1 \
                [ expr $lcsoff1-$off1 ] $s2 $off2 [ expr $lcsoff2-$off2 ]

        }
        if { $rightoff1<$off1+$len1 || $rightoff2<$off2+$len2 } {
            # right
            ::Yadt::Fid_Ratcliff_Aux2 $id1 $id2 $diff_id $l1 $l2 $s1 $rightoff1 \
                [ expr $off1+$len1-$rightoff1 ] $s2 $rightoff2 \
                [ expr $off2+$len2-$rightoff2 ]
        }
    } else {
        for { set i 1 } { $i <= 2 } { incr i } {
            $WIDGETS(diff_lines_text) tag add inlinechgtag [ set id$i ].[ set off$i ] "[ set id$i ].[ set off$i ]+[ set len$i ]c"
            set DIFF_INT(scrinline,$diff_id,[ set id$i ],$DIFF_INT(scrinline,$diff_id,[ set id$i ])) \
                [ list [ set l$i ] [ set off$i ] [ expr [ set off$i ] + [ set len$i ] ] inlinechgtag ]
            incr DIFF_INT(scrinline,$diff_id,[ set id$i ])
        }
    }

    return
}

#===============================================================================

proc ::Yadt::Fid_Ratcliff_Aux3 { diff_id l1 l2 l3 s1 off1 len1 s2 off2 len2 s3 off3 len3 } {

    variable ::Yadt::WIDGETS
    variable ::Yadt::DIFF_INT
    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::DIFF3

    if { $len1 <= 0 || $len2 <= 0 || $len3 <= 0 } {
        if { $len1 == 0 && $len2 == 0 } {
            $WIDGETS(diff_lines_text) tag add instag 3.$off3 "3.$off3+${len3}c"
            set DIFF_INT(scrinline,$diff_id,3,$DIFF_INT(scrinline,$diff_id,3)) \
                [ list $l3 $off3 [ expr $off3 + $len3 ] instag ]
            incr DIFF_INT(scrinline,$diff_id,3)
        } elseif { $len1 == 0 && $len3 == 0 } {
            $WIDGETS(diff_lines_text) tag add instag 2.$off2 "2.$off2+${len2}c"
            set DIFF_INT(scrinline,$diff_id,2,$DIFF_INT(scrinline,$diff_id,2)) \
                [ list $l2 $off2 [ expr $off2 + $len2 ] instag ]
            incr DIFF_INT(scrinline,$diff_id,2)
        } elseif { $len2 == 0 && $len3 == 0 } {
            $WIDGETS(diff_lines_text) tag add instag 1.$off1 "1.$off1+${len1}c"
            set DIFF_INT(scrinline,$diff_id,1,$DIFF_INT(scrinline,$diff_id,1)) \
                [ list $l1 $off1 [ expr $off1 + $len1 ] instag ]
            incr DIFF_INT(scrinline,$diff_id,1)
        } elseif { $len1 == 0 } {
            $WIDGETS(diff_lines_text) tag add inlineinstag 2.$off2 "2.$off2+${len2}c"
            $WIDGETS(diff_lines_text) tag add inlineinstag 3.$off3 "3.$off3+${len3}c"

            if { $off1 != 0 || \
                     ( [ info exists DIFF3($diff_id,which_file) ] && \
                           $DIFF3($diff_id,which_file) != 0 ) } {
                set DIFF_INT(scrinline,$diff_id,2,$DIFF_INT(scrinline,$diff_id,2)) \
                [ list $l2 $off2 [ expr $off2 + $len2 ] inlineinstag ]
                incr DIFF_INT(scrinline,$diff_id,2)

                set DIFF_INT(scrinline,$diff_id,3,$DIFF_INT(scrinline,$diff_id,3)) \
                [ list $l3 $off3 [ expr $off3 + $len3 ] inlineinstag ]
                incr DIFF_INT(scrinline,$diff_id,3)
            }
            ::Yadt::Fid_Ratcliff_Aux2 2 3 $diff_id $l2 $l3 $s2 $off2 $len2 $s3 $off3 $len3
        } elseif { $len2 == 0 } {
            $WIDGETS(diff_lines_text) tag add inlineinstag 1.$off1 "1.$off1+${len1}c"
            $WIDGETS(diff_lines_text) tag add inlineinstag 3.$off3 "3.$off3+${len3}c"

            if { $off2 != 0 || \
                     ( [ info exists DIFF3($diff_id,which_file) ] && \
                           $DIFF3($diff_id,which_file) != 0 ) } {
                set DIFF_INT(scrinline,$diff_id,1,$DIFF_INT(scrinline,$diff_id,1)) \
                [ list $l1 $off1 [ expr $off1 + $len1 ] inlineinstag ]
                incr DIFF_INT(scrinline,$diff_id,1)

                set DIFF_INT(scrinline,$diff_id,3,$DIFF_INT(scrinline,$diff_id,3)) \
                [ list $l3 $off3 [ expr $off3 + $len3 ] inlineinstag ]
                incr DIFF_INT(scrinline,$diff_id,3)
            }
            ::Yadt::Fid_Ratcliff_Aux2 1 3 $diff_id $l1 $l3 $s1 $off1 $len1 $s3 $off3 $len3
        } elseif { $len3 == 0 } {
            $WIDGETS(diff_lines_text) tag add inlineinstag 1.$off1 "1.$off1+${len1}c"
            $WIDGETS(diff_lines_text) tag add inlineinstag 2.$off2 "2.$off2+${len2}c"

            if { $off3 != 0 || \
                     ( [ info exists DIFF3($diff_id,which_file) ] && \
                           $DIFF3($diff_id,which_file) != 0 ) } {
                set DIFF_INT(scrinline,$diff_id,1,$DIFF_INT(scrinline,$diff_id,1)) \
                [ list $l1 $off1 [ expr $off1 + $len1 ] inlineinstag ]
                incr DIFF_INT(scrinline,$diff_id,1)

                set DIFF_INT(scrinline,$diff_id,2,$DIFF_INT(scrinline,$diff_id,2)) \
                [ list $l2 $off2 [ expr $off2 + $len2 ] inlineinstag ]
                incr DIFF_INT(scrinline,$diff_id,2)
            }

            ::Yadt::Fid_Ratcliff_Aux2 1 2 $diff_id $l1 $l2 $s1 $off1 $len1 $s2 $off2 $len2
        }
        return
    }

    set lcsoff1 -1
    set lcsoff2 -1
    set lcsoff3 -1

    set ret [ ::Yadt::Longest_Common_Substring3 $s1 $off1 $len1 $s2 $off2 $len2 $s3 $off3 $len3 lcsoff1 lcsoff2 lcsoff3 ]

    if { $ret > 0 } {
        set rightoff1 [ expr $lcsoff1 + $ret ]
        set rightoff2 [ expr $lcsoff2 + $ret ]
        set rightoff3 [ expr $lcsoff3 + $ret ]

        if { $lcsoff1 > $off1 || $lcsoff2 > $off2 || $lcsoff3 > $off3 } {
            ::Yadt::Fid_Ratcliff_Aux3 \
                $diff_id $l1 $l2 $l3 \
                $s1 $off1 [ expr $lcsoff1 - $off1 ] \
                $s2 $off2 [ expr $lcsoff2 - $off2 ] \
                $s3 $off3 [ expr $lcsoff3 - $off3 ]
        }
        if { $rightoff1 < $off1 + $len1 || $rightoff2 < $off2 + $len2 || $rightoff3 < $off3 + $len3 } {
            ::Yadt::Fid_Ratcliff_Aux3 \
                $diff_id $l1 $l2 $l3 \
                $s1 $rightoff1 [ expr $off1 + $len1 - $rightoff1 ] \
                $s2 $rightoff2 [ expr $off2 + $len2 - $rightoff2 ] \
                $s3 $rightoff3 [ expr $off3 + $len3 - $rightoff3 ]
        }
    } else {
        if { $s1 == $s2 } {
            $WIDGETS(diff_lines_text) tag add inlinetag 1.$off1 "1.$off1+${len1}c"
            set DIFF_INT(scrinline,$diff_id,1,$DIFF_INT(scrinline,$diff_id,1)) \
                [ list $l1 $off1 [ expr $off1 + $len1 ] inlinetag ]
            incr DIFF_INT(scrinline,$diff_id,1)
            $WIDGETS(diff_lines_text) tag add inlinetag 2.$off2 "2.$off2+${len2}c"
            set DIFF_INT(scrinline,$diff_id,2,$DIFF_INT(scrinline,$diff_id,2)) \
                [ list $l2 $off2 [ expr $off2 + $len2 ] inlinetag ]
            incr DIFF_INT(scrinline,$diff_id,2)
            $WIDGETS(diff_lines_text) tag add inlinechgtag 3.$off3 "3.$off3+${len3}c"
            set DIFF_INT(scrinline,$diff_id,3,$DIFF_INT(scrinline,$diff_id,3)) \
                [ list $l3 $off3 [ expr $off3 + $len3 ] inlinechgtag ]
            incr DIFF_INT(scrinline,$diff_id,3)
        } elseif { $s1 == $s3 } {
            $WIDGETS(diff_lines_text) tag add inlinetag 1.$off1 "1.$off1+${len1}c"
            set DIFF_INT(scrinline,$diff_id,1,$DIFF_INT(scrinline,$diff_id,1)) \
                [ list $l1 $off1 [ expr $off1 + $len1 ] inlinetag ]
            incr DIFF_INT(scrinline,$diff_id,1)
            $WIDGETS(diff_lines_text) tag add inlinechgtag 2.$off3 "2.$off2+${len2}c"
            set DIFF_INT(scrinline,$diff_id,2,$DIFF_INT(scrinline,$diff_id,2)) \
                [ list $l2 $off2 [ expr $off2 + $len2 ] inlinechgtag ]
            incr DIFF_INT(scrinline,$diff_id,2)
            $WIDGETS(diff_lines_text) tag add inlinetag 3.$off3 "3.$off3+${len3}c"
            set DIFF_INT(scrinline,$diff_id,3,$DIFF_INT(scrinline,$diff_id,3)) \
                [ list $l3 $off3 [ expr $off3 + $len3 ] inlinetag ]
            incr DIFF_INT(scrinline,$diff_id,3)
        } elseif { $s2 == $s3 } {
            $WIDGETS(diff_lines_text) tag add inlinechgtag 1.$off3 "1.$off1+${len1}c"
            set DIFF_INT(scrinline,$diff_id,1,$DIFF_INT(scrinline,$diff_id,1)) \
                [ list $l1 $off1 [ expr $off1 + $len1 ] inlinechgtag ]
            incr DIFF_INT(scrinline,$diff_id,1)
            $WIDGETS(diff_lines_text) tag add inlinetag 2.$off2 "2.$off2+${len2}c"
            set DIFF_INT(scrinline,$diff_id,2,$DIFF_INT(scrinline,$diff_id,2)) \
                [ list $l2 $off2 [ expr $off2 + $len2 ] inlinetag ]
            incr DIFF_INT(scrinline,$diff_id,2)
            $WIDGETS(diff_lines_text) tag add inlinetag 3.$off3 "3.$off3+${len3}c"
            set DIFF_INT(scrinline,$diff_id,3,$DIFF_INT(scrinline,$diff_id,3)) \
                [ list $l3 $off3 [ expr $off3 + $len3 ] inlinetag ]
            incr DIFF_INT(scrinline,$diff_id,3)
        } else {
            for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
                $WIDGETS(diff_lines_text) tag add inlinechgtag $i.[ set off$i ] "$i.[ set off$i ]+[ set len$i ]c"
                set DIFF_INT(scrinline,$diff_id,$i,$DIFF_INT(scrinline,$diff_id,$i)) \
                    [ list [ set l$i ] [ set off$i ] [ expr [ set off$i ] + [ set len$i ] ] inlinechgtag ]
                incr DIFF_INT(scrinline,$diff_id,$i)
            }
        }
    }

    return
}

#===============================================================================

proc ::Yadt::Longest_Common_Substring2 { s1 off1 len1 s2 off2 len2 lcsoff1_ref lcsoff2_ref } {

    upvar $lcsoff1_ref lcsoff1
    upvar $lcsoff2_ref lcsoff2
    set snippet ""

    set snippetlen 0
    set longestlen 0

    # extract just the search regions for efficiency in string searching
    set s1 [ string range $s1 $off1 [ expr $off1 + $len1 - 1 ] ]
    set s2 [ string range $s2 $off2 [ expr $off2 + $len2 - 1 ] ]

    set j 0

    while { 1 } {
        # increase size of matching snippet
        while { $snippetlen < $len2 - $j } {
            set tmp "$snippet[ string index $s2 [ expr $j + $snippetlen ] ]"
            if { [ string first $tmp $s1 ] == -1 } { break }
            set snippet $tmp
            incr snippetlen
        }
        if { $snippetlen == 0 } {
            # nothing starting at this position
            incr j
            if { $snippetlen >= $len2 - $j } { break }
        } else {
            set tmpoff [ string first $snippet $s1 ]
            if { $tmpoff != -1 && $snippetlen > $longestlen } {
                # new longest?
                set longest $snippet
                set longestlen $snippetlen
                set lcsoff1 [ expr $off1 + $tmpoff ]
                set lcsoff2 [ expr $off2 + $j ]
            }
            # drop 1st char of prefix, but keep size the same as longest
            if { $snippetlen >= $len2 - $j } { break }
            set snippet "[ string range $snippet 1 end ][ string index $s2 [ expr $j + $snippetlen ] ]"
            incr j
        }
    }

    return $longestlen
}

#===============================================================================

proc ::Yadt::Longest_Common_Substring3 { s1 off1 len1 s2 off2 len2 s3 off3 len3 lcsoff1_ref lcsoff2_ref lcsoff3_ref } {

    upvar $lcsoff1_ref lcsoff1
    upvar $lcsoff2_ref lcsoff2
    upvar $lcsoff3_ref lcsoff3

    set snippet ""
    set snippetlen 0
    set longestlen 0

    # extract just the search regions for efficiency in string searching
    set s1 [ string range $s1 $off1 [ expr $off1 + $len1 - 1 ] ]
    set s2 [ string range $s2 $off2 [ expr $off2 + $len2 - 1 ] ]
    set s3 [ string range $s3 $off3 [ expr $off3 + $len3 - 1 ] ]

    set i 0
    set j 0
    set k 0

    while { 1 } {

        while { 1 } {
            set tmp "$snippet[ string index $s1 [ expr $i + $snippetlen ] ]"

            if { [ string first $tmp $s2 ] == -1 } { 
                break
            }
            if { [ string first $tmp $s3 ] == -1 } { 
                break
            }

            if { $snippet == $tmp } {
                break
            }
            set snippet $tmp
            incr snippetlen
        }

        if { $snippetlen == 0 } {
            # nothing starting at this position
            incr i
            if { $snippetlen >= $len1 - $i } { 
                break 
            }
        } else {
            if { $snippetlen > $longestlen } {
                # new longest?
                set longest $snippet
                set longestlen $snippetlen

                set i [ string first $snippet $s1 ]
                set j [ string first $snippet $s2 ]
                set k [ string first $snippet $s3 ]

                set lcsoff1 [ expr $off1 + $i ]
                set lcsoff2 [ expr $off2 + $j ]
                set lcsoff3 [ expr $off3 + $k ]
            }
            # drop 1st char of prefix, but keep size the same as longest
            if { $snippetlen >= $len1 - $i } { 
                break 
            }
            if { $snippetlen >= $len2 - $j } { 
                break 
            }
            if { $snippetlen >= $len3 - $k } { 
                break 
            }
            set snippet "[ string range $snippet 1 end ][ string index $s1 [ expr $i + $snippetlen ] ]"

            incr i
            incr j
            incr k
        }
    }

    return $longestlen
}

#===============================================================================

################################################################################
# Map procs                                                                    #
################################################################################

#===============================================================================

proc ::Yadt::Map_Create  { name mapwidth mapheight } {

    variable ::Yadt::DIFF2
    variable ::Yadt::DIFF3
    variable ::Yadt::TEXT_WDG
    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::WIDGETS

    set map $name
    set lines [ expr { double([ $TEXT_WDG(1) index end ]) - 2 } ]
    if { $lines <= 0 } {
        return
    }
    set factor [ expr { $mapheight / $lines } ]

    $map blank
    $map put \#000 \
        -to 0 $mapheight $mapwidth $mapheight

    switch -- $DIFF_TYPE {
        2 {
            set num_diff [ llength $DIFF2(diff) ]
        }
        3 {
            set num_diff [ llength [ array names DIFF3 *,which_file ] ]
        }
    }

    for { set i 1 } { $i <= $num_diff } { incr i } {
        ::Yadt::Map_One_Diff $map $mapwidth $factor $i
    }

    $WIDGETS(mapCanvas) create line 0 0 0 0 \
        -tags thumbUL \
        -fill white
    $WIDGETS(mapCanvas) create line 1 1 1 1 \
        -tags thumbLR \
        -fill black
    $WIDGETS(mapCanvas) raise thumb

    eval ::Yadt::Move_Thumb [ $TEXT_WDG(1) yview ]
}

#===============================================================================

proc ::Yadt::Map_Resize { args } {

    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::DIFF2
    variable ::Yadt::DIFF3
    variable ::Yadt::WIDGETS
    variable ::Yadt::WDG_OPTIONS
    variable ::Yadt::OPTIONS

    set mapwidth [ winfo width $WIDGETS(map) ]
    set WDG_OPTIONS(mapborder) \
        [ expr { [ $WIDGETS(map) cget -borderwidth ] + \
                     [ $WIDGETS(map) cget -highlightthickness ] } ]
    set mapheight [ expr { [ winfo height $WIDGETS(map) ] - \
                               $WDG_OPTIONS(mapborder) * 2 } ]

    switch -- $DIFF_TYPE {
        2 {
            if ![ info exists DIFF2(diff) ] {
                return
            }
            set num_diff [ llength $DIFF2(diff) ]
        }
        3 {
            set num_diff [ llength [ array names DIFF3 *,which_file ] ]
        }
    }

    if { $num_diff == 0 || $mapheight == $WDG_OPTIONS(mapheight) } {
        return
    }

    if { $WDG_OPTIONS(mapheight) == 0 } {
        return
    }

    if { $mapheight < 1 } {
        return
    }

    set WDG_OPTIONS(mapheight) $mapheight
    set WDG_OPTIONS(mapwidth) $mapwidth
    ::Yadt::Map_Create $WDG_OPTIONS(map_image) $mapwidth $mapheight
}

#===============================================================================

proc ::Yadt::Map_Seek { y } {

    variable ::Yadt::WDG_OPTIONS
    variable ::Yadt::TEXT_WDG

    incr y -2

    if { $WDG_OPTIONS(mapheight) < 1 } {
        return
    }

    set yview [ expr { (double($y) / double($WDG_OPTIONS(mapheight))) } ]

    set wdgs [ ::Yadt::Get_Diff_Wdg_List 0 "text" ]
    if { [ lsearch $wdgs $WDG_OPTIONS(active_window) ] != -1 } {
        catch { $WDG_OPTIONS(active_window) yview moveto $yview }
    } else {
        catch { $TEXT_WDG(1) yview moveto $yview }
    }
}

#===============================================================================

proc ::Yadt::Map_One_Diff { map mapwidth ind factor } {

    variable ::Yadt::DIFF_TYPE

    switch -- $DIFF_TYPE {
        2 {
            ::Yadt::Map_One_Diff2 $map $mapwidth $factor $ind
        }
        3 {
            ::Yadt::Map_One_Diff3 $map $mapwidth $factor $ind
        }
    }
}

#===============================================================================

proc ::Yadt::Map_One_Diff2 { map mapwidth ind factor } {

    variable ::Yadt::DIFF_INT
    variable ::Yadt::MAP_COLOR

    foreach { start end type } $DIFF_INT($ind,scrdiff) { }

    set y [ expr { int(($start - 1) * $factor) } ]
    set size [ expr { round(($end - $start + 1) * $factor) } ]

    if { $size < 1 } {
        set size 1
    }

    switch -- $type {
        "d" { set color $MAP_COLOR(bg,deltag) }
        "a" { set color $MAP_COLOR(bg,instag) }
        "c" { set color $MAP_COLOR(bg,chgtag) }
    }

    $map put $color -to 0 $y $mapwidth [ expr { $y + $size } ]
}

#===============================================================================

proc ::Yadt::Map_One_Diff3 { map mapwidth ind factor } {

    variable ::Yadt::DIFF_INT
    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::DIFF3
    variable ::Yadt::MAP_COLOR

    foreach [ list start end type ] $DIFF_INT($ind,scrdiff) { }
    set y [ expr { int(($start - 1) * $factor) } ]
    set size [ expr { round(($end - $start + 1) * $factor) } ]

    if { $size < 1 } {
        set size 1
    }

    set color black
    switch -- $type {
        "ccc" {
            set color $MAP_COLOR(bg,chgtag)
        }
        "cca" {
            set color $MAP_COLOR(bg,deltag)
        }
        "cac" {
            set color $MAP_COLOR(bg,deltag)
        }
        "acc" {
            set color $MAP_COLOR(bg,instag)
        }
        "caa" {
            set color $MAP_COLOR(bg,deltag)
        }
        "aca" {
            set color $MAP_COLOR(bg,instag)
        }
        "aac" {
            set color $MAP_COLOR(bg,instag)
        }
    }

    if { $DIFF3($ind,which_file) == 0 } {
        set color $MAP_COLOR(bg,overlaptag)
    }

    $map put $color -to 0 $y $mapwidth [ expr { $y + $size } ]
}

#===============================================================================


################################################################################
# Events and binds procs                                                       #
################################################################################

#===============================================================================

proc ::Yadt::Get_Merge_Wdg_List { { ind 0 } { type "all" } } {

    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::MERGE_TEXT_WDG
    variable ::Yadt::MERGE_INFO_WDG
    variable ::Yadt::MERGE_START
    variable ::Yadt::OPTIONS

    set wdg_list {}

    if { $ind > 0  &&  $ind >= $MERGE_START  &&  $ind <= $DIFF_TYPE } {
        switch -- $type {
            "info" {
                lappend wdg_list $MERGE_INFO_WDG($ind)
            }
            "text" {
                lappend wdg_list $MERGE_TEXT_WDG($ind)
            }
            "all" {
                lappend wdg_list $MERGE_INFO_WDG($ind)
                lappend wdg_list $MERGE_TEXT_WDG($ind)
            }
            default {
                return -code error "Unsupported type <$type>"
            }
        }
    }

    if { $ind == 0 } {
        for { set i $MERGE_START } { $i <= $DIFF_TYPE } { incr i } {
            switch -- $type {
                "info" {
                    lappend wdg_list $MERGE_INFO_WDG($i)
                }
                "text" {
                    lappend wdg_list $MERGE_TEXT_WDG($i)
                }
                "all" {
                    lappend wdg_list $MERGE_INFO_WDG($i)
                    lappend wdg_list $MERGE_TEXT_WDG($i)
                }
                default {
                    return -code error "Unsupported type <$type>"
                }
            }
        }
    }

    return $wdg_list
}

#===============================================================================

proc ::Yadt::Get_Diff_Wdg_List { { ind 0 } { type "all" } } {

    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::TEXT_WDG
    variable ::Yadt::TEXT_NUM_WDG
    variable ::Yadt::TEXT_INFO_WDG

    set wdg_list {}

    if { $ind > 0 } {
        switch -- $type {
            "num" {
                lappend wdg_list $TEXT_NUM_WDG($ind)
            }
            "info" {
                lappend wdg_list $TEXT_INFO_WDG($ind)
            }
            "text" {
                lappend wdg_list $TEXT_WDG($ind)
            }
            "all" {
                lappend wdg_list $TEXT_WDG($ind)
                lappend wdg_list $TEXT_NUM_WDG($ind)
                lappend wdg_list $TEXT_INFO_WDG($ind)
            }
            default {
                return -code error "Unsupported type <$type>"
            }
        }
    }

    if { $ind == 0 } {
        for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
            switch -- $type {
                "num" {
                    lappend wdg_list $TEXT_NUM_WDG($i)
                }
                "info" {
                    lappend wdg_list $TEXT_INFO_WDG($i)
                }
                "text" {
                    lappend wdg_list $TEXT_WDG($i)
                }
                "all" {
                    lappend wdg_list $TEXT_WDG($i)
                    lappend wdg_list $TEXT_NUM_WDG($i)
                    lappend wdg_list $TEXT_INFO_WDG($i)
                }
                default {
                    return -code error "Unsupported type <$type>"
                }
            }
        }
    }

    return $wdg_list
}

#===============================================================================

proc ::Yadt::Get_File_Title_Wdg_List {} {

    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::WIDGETS

    set wdg_list {}
    for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
        lappend wdg_list $WIDGETS(file_title_$i)
    }

    return $wdg_list
}

#===============================================================================

proc ::Yadt::Enable_Text_Wdg {} {

    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::TEXT_WDG

    for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
        $TEXT_WDG($i) configure -state normal
    }
}

#===============================================================================

proc ::Yadt::Disable_Text_Wdg {} {

    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::TEXT_WDG

    for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
        $TEXT_WDG($i) configure -state disabled
    }
}

#===============================================================================

proc ::Yadt::Enable_Num_Wdg {} {

    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::TEXT_NUM_WDG

    for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
        $TEXT_NUM_WDG($i) configure -state normal
    }
}

#===============================================================================

proc ::Yadt::Disable_Num_Wdg {} {

    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::TEXT_NUM_WDG

    for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
        $TEXT_NUM_WDG($i) configure -state disabled
    }
}

#===============================================================================

proc ::Yadt::Enable_Info_Wdg {} {

    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::TEXT_INFO_WDG

    for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
        $TEXT_INFO_WDG($i) configure -state normal
    }
}

#===============================================================================

proc ::Yadt::Disable_Info_Wdg {} {

    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::TEXT_INFO_WDG

    for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
        $TEXT_INFO_WDG($i) configure -state disabled
    }
}

#===============================================================================

proc ::Yadt::Enable_Merge_Info_Wdg {} {

    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::OPTIONS
    variable ::Yadt::MERGE_START
    variable ::Yadt::MERGE_INFO_WDG

    for { set i $MERGE_START } { $i <= $DIFF_TYPE } { incr i } {
        $MERGE_INFO_WDG($i) configure -state normal
    }
}

#===============================================================================

proc ::Yadt::Disable_Merge_Info_Wdg {} {

    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::OPTIONS
    variable ::Yadt::MERGE_START
    variable ::Yadt::MERGE_INFO_WDG

    for { set i $MERGE_START } { $i <= $DIFF_TYPE } { incr i } {
        $MERGE_INFO_WDG($i) configure -state disabled
    }
}

#===============================================================================

proc ::Yadt::Main_Window_Configure_Event { { wdg "" } } {

    global tcl_platform

    variable ::Yadt::WIDGETS
    variable ::Yadt::OPTIONS
    variable ::Yadt::TMP_OPTIONS
    variable ::Yadt::WDG_OPTIONS

    if { $wdg == "" } {
        set wdg $WIDGETS(window_name)
    }

    set geometry [ wm geometry $wdg ]

    ::CmnTools::Parse_WM_Geometry $geometry -width width -height height -left x -top y

    if { $tcl_platform(platform) == "windows" && \
             [ wm state $WIDGETS(window_name) ] == "zoomed" } {
        set x [ winfo rootx $wdg ]
        set y [ winfo rooty $wdg ]
    }

    regexp {^([+-]*)([0-9]+)$} $x dummy sign value

    set x [ expr int($x) ]
    set y [ expr int($y) ]

    if { ( $x < 0 && $sign == "+-" ) || \
             ( $x > 0 && $sign == "--" ) || \
             ( $x == 0 && $sign == "-" ) } {
        set x [ expr { [ winfo width $wdg ] + 2*[ winfo rootx $wdg ] - $x - [ winfo screenwidth . ] } ]
    }

    if { $x < 0 && $sign == "--" } {
        set x [ expr { [ winfo screenwidth . ] - [ winfo width $wdg ] + $x - 2*[ winfo rootx $wdg ] } ]
    }

    if { $y < 0 } {
        set y 0
    }

    set TMP_OPTIONS(geometry,width) $width
    set TMP_OPTIONS(geometry,height) $height
    set TMP_OPTIONS(geometry,x) $x
    set TMP_OPTIONS(geometry,y) $y

    ::Yadt::Update_Geometry_Label
}

#===============================================================================

proc ::Yadt::Bind_Events {} {

    global tcl_platform
    
    variable ::Yadt::OPTIONS
    variable ::Yadt::WDG_OPTIONS
    variable ::Yadt::WIDGETS
    variable ::Yadt::DIFF_TYPE

    # Popup menu
    set key_event <Button-3>
    if { $tcl_platform(platform) == "unix" &&\
	 $tcl_platform(os) == "Darwin" } {
	set key_event <Control-Button-1>
    }

    foreach wdg [ concat [ ::Yadt::Get_Diff_Wdg_List ] \
                      [ ::Yadt::Get_Merge_Wdg_List ] \
                      $WIDGETS(mapCanvas) ] {
        bind $wdg $key_event { 
            ::Yadt:::Show_Popup_Menu %X %Y 
        }
    }

    foreach wdg [ concat [ ::Yadt::Get_Diff_Wdg_List ] \
                      [ ::Yadt::Get_Merge_Wdg_List ] ] {
        bind $wdg <KeyPress> { break }
        bind $wdg <Alt-Delete> { break }
        bind $wdg <Alt-BackSpace> { break }
        bind $wdg <Alt-KeyPress> { continue }

        bind $wdg <<Paste>> { break }

        foreach event [ list Next Prior Up Down Left Right Home End ] {
            foreach modifier [ list {} Shift- Control- Shift-Control- ] {
                set binding [ bind Text <${modifier}${event}> ]
                if { [ string length $binding ] > 0 } {
                    bind $wdg "<${modifier}${event}>" "
                        ${binding}
                        break
                    "
                }
            }
        }

        bind $wdg <Control-o> continue
        bind $wdg <Control-f> continue
        bind $wdg <Control-c> continue
        bind $wdg <Control-n> continue
        bind $wdg <Control-p> continue
        bind $wdg <Tab> continue
        bind $wdg <Shift-Tab> continue

        bind $wdg <F3> continue
        bind $wdg <Shift-F3> continue

        ::Yadt::Bind_Navigation_Keys $wdg
        ::Yadt::Bind_Choice_Keys $wdg

        bind $wdg <Return> "
            ::Yadt::Move_Nearest $wdg mark insert
            break
        "

        foreach key [ list c n p f l ] {
            bind $wdg <Alt-$key> continue
        }

        bind $wdg <Double-1> "
            ::Yadt::Move_Nearest $wdg xy %x %y
            break
        "

    }

    ::Yadt::Bind_Choice_Keys [ ::Yadt::Get_File_Title_Wdg_List ]

    ::Yadt::Bind_Navigation_Keys [ list $WIDGETS(diff_lines_text) \
                                       $WIDGETS(diff_lines_files) ]

    ::Yadt::Bind_Navigation_Keys [ ::Yadt::Get_Merge_Wdg_List 0 "info" ]

    ::Yadt::Bind_Navigation_Keys [ ::Yadt::Get_File_Title_Wdg_List ]

    ::Yadt::Bind_Navigation_Keys [ list $WIDGETS(diff_combo) \
                                       $WIDGETS(find_window_list) ]

    foreach wdg [ concat [ ::Yadt::Get_Diff_Wdg_List 0 "text" ] \
                      [ ::Yadt::Get_Merge_Wdg_List 0 "text" ] ] {
        foreach event [ list <Button-1> <FocusIn> ] {
            bind $wdg $event "
                set ::Yadt::WDG_OPTIONS(active_window) $wdg
                ::Yadt::Set_Find_Element
                ::Yadt::Update_Scrollbar_And_Thumb
            "
        }
    }

    if { $DIFF_TYPE == 3 } {
        foreach wdg [ concat $WIDGETS(diff_combo) $WIDGETS(tool_bar) [ winfo children $WIDGETS(tool_bar) ] ] {
            bind $wdg $key_event { 
                ::Yadt:::Show_Merge_Mode_Popup_Menu %X %Y 
            }
        }
    }
}

#===============================================================================

proc ::Yadt::Bind_Choice_Keys { widgets } {

    variable ::Yadt::WIDGETS
    variable ::Yadt::DIFF_TYPE

    foreach wdg $widgets {
        bind $wdg "1" "
            ::Yadt::Handle_Choice_Shortcuts 1
            break
        "
        bind $wdg "2" "
            ::Yadt::Handle_Choice_Shortcuts 2
            break
        "
        if { $DIFF_TYPE == 3 } {
            bind $wdg "3" "
                ::Yadt::Handle_Choice_Shortcuts 3
                break
            "
        }
    }
}

#===============================================================================

proc ::Yadt::Bind_Navigation_Keys { widgets } {

    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::WIDGETS

    foreach wdg $widgets {
        bind $wdg <c> "
            $WIDGETS(center_cur) invoke
            break
        "
        bind $wdg <n> "
            $WIDGETS(move_next) invoke
            break
        "
        bind $wdg <p> "
            $WIDGETS(move_prev) invoke
            break
        "
        bind $wdg <f> "
            $WIDGETS(move_first) invoke
            break
        "
        bind $wdg <l> "
            $WIDGETS(move_last) invoke
            break
        "
        bind $wdg <q> "
            ::Yadt::Exit
            break
        "
        if { $DIFF_TYPE == 3 } {
            bind $wdg <Control-n> "
                $WIDGETS(move_next_confl) invoke
                break
            "
            bind $wdg <Control-p> "
                $WIDGETS(move_prev_confl) invoke
                break
            "
        }
    }
}

#===============================================================================

proc ::Yadt::Bind_Toolbar_Events { elements } {
    foreach element $elements {
        bind $element <Enter> [ list ::Yadt::Handle_Toolbutton_Events <Enter> %W ]
        bind $element <Leave> [ list ::Yadt::Handle_Toolbutton_Events <Leave> %W ]
        bind $element <FocusIn> [ list ::Yadt::Handle_Toolbutton_Events <FocusIn> %W ]
        bind $element <FocusOut> [ list ::Yadt::Handle_Toolbutton_Events <FocusOut> %W ]

        DynamicHelp::add $element -type balloon -variable ::Yadt::WDG_OPTIONS(tooltip,$element)
    }
}

#===============================================================================

proc ::Yadt::Move_Thumb { y1 y2 } {

    variable ::Yadt::WIDGETS
    variable ::Yadt::WDG_OPTIONS

    set thumbheight [ expr { ($y2 - $y1) * $WDG_OPTIONS(mapheight) } ]
    if { $thumbheight < $WDG_OPTIONS(thumb_min_height) } {
        set thumbheight $WDG_OPTIONS(thumb_min_height)
    }

    if ![ info exists WDG_OPTIONS(mapwidth) ] {
        set WDG_OPTIONS(mapwidth) 0
    }

    set x1 1
    set x2 [ expr { $WDG_OPTIONS(mapwidth) - 3 } ]

    set y1 [ expr { int(($y1 * $WDG_OPTIONS(mapheight)) - 2) } ]
    if { $y1 < 0 } {
        set y1 0
    }

    set y2 [ expr { $y1 + $thumbheight } ]
    if { $y2 > $WDG_OPTIONS(mapheight) } {
        set y2 $WDG_OPTIONS(mapheight)
        set y1 [ expr { $y2 - $thumbheight } ]
    }

    set dx1 $x1
    set dx2 $x2
    set dy1 $y1
    set dy2 $y2

    $WIDGETS(mapCanvas) coords thumbUL $x1 $y2 \
        $x1 $y1 \
        $x2 $y1 \
        $dx2 $dy1 \
        $dx1 $dy1 \
        $dx1 $dy2
    $WIDGETS(mapCanvas) coords thumbLR $dx1 $y2 \
        $x2 $y2 \
        $x2 $dy1 \
        $dx2 $dy1 \
        $dx2 $dy2 \
        $dx1 $dy2

    set WDG_OPTIONS(thumbBbox) [ list $x1 $y1 $x2 $y2 ]
    set WDG_OPTIONS(thumb_height) $thumbheight
}

#===============================================================================

proc ::Yadt::Popup_Menu_Invoke { action args } {

    variable ::Yadt::WIDGETS
    variable ::Yadt::WDG_OPTIONS

    switch -- $action {
        -center {
            $WIDGETS(center_cur) invoke
        }
        -first {
            $WIDGETS(move_first) invoke
        }
        -prev {
            $WIDGETS(move_prev) invoke
        }
        -next {
            $WIDGETS(move_next) invoke
        }
        -last {
            $WIDGETS(move_last) invoke
        }
        -nearest {
            ::Yadt::Move_Nearest \
                $WDG_OPTIONS(active_window) xy \
                [ expr $WDG_OPTIONS(popup_x) - [ winfo rootx $WDG_OPTIONS(active_window) ] ] \
                [ expr $WDG_OPTIONS(popup_y) - [ winfo rooty $WDG_OPTIONS(active_window) ] ]
        }
        -prev_conflict {
            $WIDGETS(move_prev_confl) invoke
        }
        -next_conflict {
            $WIDGETS(move_next_confl) invoke
        }
        default {
            return -code error "Internal error: incorrect action <$action>\
                in [ lindex [ info level 0 ] 0 ]"
        }
    }
}

#===============================================================================

proc ::Yadt::Handle_Map_Event { event y } {

    variable ::Yadt::WDG_OPTIONS
    variable ::Yadt::TEXT_WDG
    variable ::Yadt::DIFF_TYPE

    switch -- $event {
        B1-Press {
            set ty1 [ lindex $WDG_OPTIONS(thumbBbox) 1 ]
            set ty2 [ lindex $WDG_OPTIONS(thumbBbox) 3 ]
            if { $y >= $ty1 && $y <= $ty2 } {
                set WDG_OPTIONS(mapScrolling) 1
            }
        }
        B1-Motion {
            if [ info exists WDG_OPTIONS(mapScrolling) ] {
                ::Yadt::Map_Seek $y
            }
        }
        B1-Release {
            ::Yadt::Status_Msg menustatus ""
            set ty1 [ lindex $WDG_OPTIONS(thumbBbox) 1 ]
            set ty2 [ lindex $WDG_OPTIONS(thumbBbox) 3 ]
            if { $y < $ty1 || $y > $ty2 } {
                if { $y < $ty1 } {
                    $TEXT_WDG($DIFF_TYPE) yview scroll -1 pages
                } else {
                    $TEXT_WDG($DIFF_TYPE) yview scroll 1 pages
                }
            } else {

            }
            unset -nocomplain WDG_OPTIONS(mapScrolling)
        }
    }
}

#===============================================================================

proc ::Yadt::Handle_Toolbutton_Events { event wdg } {

    variable ::Yadt::OPTIONS
    variable ::Yadt::WDG_OPTIONS

    switch -- $event {
        "<Enter>" -
        "<FocusIn>" {
            ::Yadt::Show_Tooltip button $wdg
        }
        "<Leave>" -
        "<FocusOut>" {
            ::Yadt::Show_Tooltip button ""
        }
    }
}

#===============================================================================

proc ::Yadt::Pack_Find_Bar {} {

    variable ::Yadt::WIDGETS

    ::Yadt::Set_Find_Element
    pack $WIDGETS(find_bar) \
        -side bottom \
        -fill x \
        -expand 0 \
        -pady 0 \
        -padx 0 \
        -after $WIDGETS(status_bar)

    focus $WIDGETS(find_text)
}

#===============================================================================

proc ::Yadt::Unpack_Find_Bar {} {

    variable ::Yadt::WIDGETS

    pack forget $WIDGETS(find_bar)
    ::Yadt::Focus_Active_Window
}

#===============================================================================

proc ::Yadt::Toggle_Diff_Lines {} {

    variable ::Yadt::WIDGETS
    variable ::Yadt::OPTIONS
    variable ::Yadt::TMP_OPTIONS

    if { $OPTIONS(show_diff_lines) } {
        pack $WIDGETS(diff_lines_frame) \
            -fill x \
            -expand 0 \
            -side bottom \
            -before $WIDGETS(main_part)
    } else {
        pack forget $WIDGETS(diff_lines_frame)
    }

    set TMP_OPTIONS(show_diff_lines) $OPTIONS(show_diff_lines)
}

#===============================================================================

proc ::Yadt::Handle_Find_Entry { wdg } {

    variable ::Yadt::WDG_OPTIONS

    if { [ $wdg get ] == $WDG_OPTIONS(last_search) } return

    ::Yadt::Find_In_Text -forward 0 0
}

#===============================================================================

proc ::Yadt::Handle_Combo_Find_Where {} {

    variable ::Yadt::WIDGETS
    variable ::Yadt::WDG_OPTIONS

    foreach wdg [ concat [ ::Yadt::Get_Diff_Wdg_List 0 "text" ] \
                      [ ::Yadt::Get_Merge_Wdg_List 0 "text" ] ] {
        if { $WDG_OPTIONS($wdg) == $WDG_OPTIONS(find_where) } {
            set WDG_OPTIONS(active_window) $wdg
            break
        }
    }

    ::Yadt::Find_In_Text -forward 1 0
}

#===============================================================================

proc ::Yadt::Handle_Choice_Shortcuts { ind } {

    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::DIFF_INT

    if { $DIFF_INT(count) == 0 } return

    switch -- $DIFF_TYPE {
        2 {
            ::Yadt::Merge2 $ind
        }
        3 {
            ::Yadt::Merge3 $DIFF_TYPE $ind
        }
    }

    ::Yadt::Update_Widgets
}

#===============================================================================

proc ::Yadt::Handle_Choice_Buttons2 { ind } {

    variable ::Yadt::WDG_OPTIONS
    variable ::Yadt::DIFF_INT

    set current_method $DIFF_INT(normal_merge$DIFF_INT(pos))
    if { $current_method == -1 } {
        set current_method ""
    }

    switch -- $ind {
        1 {
            set new_state $WDG_OPTIONS(toggleA)
        }
        2 {
            set new_state $WDG_OPTIONS(toggleB)
        }
    }
    
    switch -- $new_state {
        0 {
            regsub $ind $current_method "" new_method
        }
        1 {
            set new_method "${current_method}$ind"
        }
    }

    if { $new_method == "" } {
        set new_method -1
    }

    ::Yadt::Merge2 $new_method
}

#===============================================================================

proc ::Yadt::Handle_Choice_Buttons3 { target ind } {

    variable ::Yadt::WDG_OPTIONS
    variable ::Yadt::DIFF_INT
    variable ::Yadt::OPTIONS

    set current_method $DIFF_INT($OPTIONS(merge_mode)_merge$DIFF_INT(pos),$target)
    if { $current_method == -1 } {
        set current_method ""
    }

    switch -- $ind {
        1 {
            set new_state $WDG_OPTIONS(toggle3${target}A)
        }
        2 {
            set new_state $WDG_OPTIONS(toggle3${target}B)
        }
        3 {
            set new_state $WDG_OPTIONS(toggle3${target}C)
        }
    }

    switch -- $new_state {
        0 {
            regsub $ind $current_method "" new_method
        }
        1 {
            set new_method "${current_method}$ind"
        }
    }

    if { $new_method == "" } {
        set new_method -1
    }

    ::Yadt::Merge3 $target $new_method
}

#===============================================================================

proc ::Yadt::Resolve_Handle { target } {

    variable ::Yadt::WIDGETS
    variable ::Yadt::WDG_OPTIONS
    variable ::Yadt::DIFF_INT
    variable ::Yadt::OPTIONS

    set DIFF_INT($DIFF_INT(pos),$target,$OPTIONS(merge_mode)_resolved) $WDG_OPTIONS(resolve_status_$target)

    if { $DIFF_INT($DIFF_INT(pos),$target,$OPTIONS(merge_mode)_resolved) == 1 } {
        set WDG_OPTIONS(tooltip,$WIDGETS(mark$target)) \
            "Unmark current difference as resolved"
    } else {
        set WDG_OPTIONS(tooltip,$WIDGETS(mark$target)) \
            "Mark current difference as resolved"
    }
    ::Yadt::Status_Msg menustatus $WDG_OPTIONS(tooltip,$WIDGETS(mark$target))

    ::Yadt::Update_Widgets
}

#===============================================================================

proc ::Yadt::Find_In_Text { direction { set_focus 0 } { shift_chars 1 } } {

    variable ::Yadt::WIDGETS
    variable ::Yadt::TEXT_WDG
    variable ::Yadt::WDG_OPTIONS

    if { [ info exists WDG_OPTIONS(active_window) ] && \
             $WDG_OPTIONS(active_window) != "" } {
        set find_where $WDG_OPTIONS(active_window)
    } else {
        set find_where $TEXT_WDG(1)
    }

    set WDG_OPTIONS(last_search) $WDG_OPTIONS(find_string)

    if { $WDG_OPTIONS(find_string) != "" } {

        if { [ $WIDGETS(find_text) get ] != "" } {
            if { $direction == "-forward" } {
                set find_from [ $find_where index "insert +${shift_chars}c" ]
            } else {
                set find_from insert
            }
        } else {
            set find_from 1.0
        }

        if [ catch {
            # to avoid possible errors in regexp entered by user
            if { $WDG_OPTIONS(ignore_case) == "-nocase" } {
                set result [ $find_where search $direction $WDG_OPTIONS(find_type) \
                                 -nocase -- $WDG_OPTIONS(find_string) $find_from ]
            } else {
                set result [ $find_where search $direction $WDG_OPTIONS(find_type) \
                                 -- $WDG_OPTIONS(find_string) $find_from ]
            }
        } errmsg ] {
            bell
        } else {
            if { $result > 0 } {
                if { $WDG_OPTIONS(find_type) == "-regexp" } {
                    set line [ $find_where get $result "$result lineend" ]

                    if { $WDG_OPTIONS(ignore_case) == "-nocase" } {
                        regexp -nocase -- $WDG_OPTIONS(find_string) $line match_var
                    } else {
                        regexp -- $WDG_OPTIONS(find_string) $line match_var
                    }
                    set length [ string length $match_var ]
                } else {
                    set length [ string length $WDG_OPTIONS(find_string) ]
                }

                set WDG_OPTIONS(last_search) $WDG_OPTIONS(find_string)
                $find_where mark set insert $result
                $find_where tag remove sel 1.0 end
                $find_where tag add sel $result "$result + ${length}c"
                $find_where see $result
                ::Yadt::Status_Msg menustatus ""
            } else {
                ::Yadt::Status_Msg menustatus "Phrase Not Found!"
                bell
            }
        }
    }

    update
    update idletasks
    if { $set_focus } {
        ::Yadt::Focus_Active_Window
    }
}

#===============================================================================

proc ::Yadt::Edit_Copy {} {
    clipboard clear -displayof .
    catch {
        clipboard append [ selection get -displayof . ]
    }
}

#===============================================================================

proc ::Yadt::Show_Tooltip { type wdg } {

    variable ::Yadt::WDG_OPTIONS

    switch -- $type {
        menu {
            if [ catch { $wdg entrycget active -label } label ] {
                set label ""
            }
            if [ info exists WDG_OPTIONS(tooltip,$label) ] {
                ::Yadt::Status_Msg menustatus \
                    $WDG_OPTIONS(tooltip,$label)
            } else {
                ::Yadt::Status_Msg menustatus \
                    $label
            }
        }
        button {
            if [ info exists WDG_OPTIONS(tooltip,$wdg) ] {
                ::Yadt::Status_Msg menustatus $WDG_OPTIONS(tooltip,$wdg)
            } else {
                ::Yadt::Status_Msg menustatus ""
            }
        }
    }
}

#===============================================================================

proc ::Yadt::Configure_Tooltips {} {

    variable ::Yadt::OPTIONS

    if { $OPTIONS(show_tooltips) } {
        DynamicHelp::configure -state normal
    } else {
        DynamicHelp::configure -state disabled
    }
}

#===============================================================================

proc ::Yadt::Status_Msg { type msg } {

    variable ::Yadt::WDG_OPTIONS

    set ::Yadt::WDG_OPTIONS($type) $msg
    update idletasks
}

#===============================================================================

proc ::Yadt::Update_Scrollbar_And_Thumb {} {

    variable ::Yadt::OPTIONS
    variable ::Yadt::WDG_OPTIONS
    variable ::Yadt::WIDGETS

    if { $OPTIONS(syncscroll) } return

    set wdgs [ ::Yadt::Get_Diff_Wdg_List 0 "text" ]
    if { [ lsearch $wdgs $WDG_OPTIONS(active_window) ] != -1 } {
        set y1y2 [ $WDG_OPTIONS(active_window) yview ]
        lassign $y1y2 y1 y2
        $WIDGETS(v_scroll) set $y1 $y2
        ::Yadt::Move_Thumb $y1 $y2
    }

    set merge_wdgs [ ::Yadt::Get_Merge_Wdg_List ]
    if { [ lsearch $merge_wdgs $WDG_OPTIONS(active_window) ] != -1 } {
        set y1y2 [ $WDG_OPTIONS(active_window) yview ]
        lassign $y1y2 y1 y2
        $WIDGETS(v_scroll_merge) set $y1 $y2
    }
}

#===============================================================================

proc ::Yadt::Triple_V_Scroll_Units { new_value current_value } {

    upvar $new_value triple_value

    set triple_value $current_value
    if [ regexp "^yview scroll (.*) units$" $current_value dummy units_num ] {
        set triple_value "yview scroll [ expr 3*$units_num ] units"
    }
}

#===============================================================================

proc ::Yadt::V_Scrollbar_Event { args } {

    variable ::Yadt::TEXT_WDG
    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::WDG_OPTIONS

    ::Yadt::Triple_V_Scroll_Units cmd_args $args

    set wdgs [ ::Yadt::Get_Diff_Wdg_List ]
    if { [ lsearch $wdgs $WDG_OPTIONS(active_window) ] < 0 } {
        set WDG_OPTIONS(active_window) $TEXT_WDG($DIFF_TYPE)
        focus $WDG_OPTIONS(active_window)
    }

    eval $WDG_OPTIONS(active_window) $cmd_args
}

#===============================================================================

proc ::Yadt::V_Merge_Scrollbar_Event { args } {

    variable ::Yadt::MERGE_TEXT_WDG
    variable ::Yadt::MERGE_START
    variable ::Yadt::WDG_OPTIONS

    ::Yadt::Triple_V_Scroll_Units cmd_args $args

    set wdgs [ ::Yadt::Get_Merge_Wdg_List ]
    if { [ lsearch $wdgs $WDG_OPTIONS(active_window) ] < 0 } {
        set WDG_OPTIONS(active_window) $MERGE_TEXT_WDG($MERGE_START)
        focus $WDG_OPTIONS(active_window)
    }

    eval $WDG_OPTIONS(active_window) $cmd_args
}

#===============================================================================

proc ::Yadt::Toggle_Sync_Scroll { args } {

    variable ::Yadt::OPTIONS
    variable ::Yadt::TMP_OPTIONS

    set TMP_OPTIONS(syncscroll) $OPTIONS(syncscroll)
}

#===============================================================================

proc ::Yadt::Vertical_Scroll_Sync { caller_type id act_wdg v_scroll thumb y0 y1 } {

    global ::Yadt::V_SYNC
    variable ::Yadt::WDG_OPTIONS
    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::MERGE_START
    variable ::Yadt::TEXT_WDG
    variable ::Yadt::MERGE_TEXT_WDG
    variable ::Yadt::OPTIONS

    if [ info exists ::Yadt::V_SYNC($caller_type) ] return
    set ::Yadt::V_SYNC($caller_type) 1

    if { $thumb } {
        ::Yadt::Move_Thumb $y0 $y1
    }

    if { $v_scroll != "" } {
        $v_scroll set $y0 $y1
    }

    switch -- $caller_type {
        "text" {
            if { $OPTIONS(syncscroll) } {
                set wdg_list [ ::Yadt::Get_Diff_Wdg_List ]
            } else {
                set wdg_list [ ::Yadt::Get_Diff_Wdg_List $id ]
            }
        }
        "merge" {
            if { $OPTIONS(syncscroll) } {
                set wdg_list [ ::Yadt::Get_Merge_Wdg_List ]
            } else {
                set wdg_list [ ::Yadt::Get_Merge_Wdg_List $id ]
            }
        }
        default {
            return -code error "Unsupported caller type <$caller_type>"
        }
    }

    set line [ ::Yadt::Get_Top_Line_Num_From_Text_Widget $act_wdg ]

    foreach wdg $wdg_list {
        $wdg yview $line
    }

    update idletasks
    after idle { catch { array unset ::Yadt::V_SYNC } }
}

#===============================================================================

proc ::Yadt::Horizontal_Scroll_Sync { caller_type id args } {

    global ::Yadt::H_SYNC
    variable ::Yadt::WIDGETS
    variable ::Yadt::TEXT_WDG
    variable ::Yadt::MERGE_TEXT_WDG
    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::OPTIONS
    variable ::Yadt::MERGE_START

    if [ info exists H_SYNC($caller_type,$id) ] {
        return
    }

    for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
        set size_text$i [ expr [ lindex [ $TEXT_WDG($i) xview ] 1 ] - [ lindex [ $TEXT_WDG($i) xview ] 0 ] ]
    }

    for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
        set start [ lindex $args 0 ]
        if { ($id != $i) || $caller_type != "text" } {
            if !$OPTIONS(syncscroll) {
                continue
            }
            if { [ set size_text$id ] == 0 } {
                continue
            }
            set start [ expr { $start * [ set size_text$i ] / [ set size_text$id ] } ]
        }

        $WIDGETS(h_scroll_$i) set $start [ expr { $start + [ set size_text$i ] } ]
        $TEXT_WDG($i) xview moveto $start
        set H_SYNC($caller_type,$i) 1
    }

    for { set i $MERGE_START } { $i <= $DIFF_TYPE } { incr i } {
        set size_merge$i [ expr [ lindex [ $MERGE_TEXT_WDG($i) xview ] 1 ] - \
                               [ lindex [ $MERGE_TEXT_WDG($i) xview ] 0 ] ]
    }
    for { set i $MERGE_START } { $i <= $DIFF_TYPE } { incr i } {
        set start [ lindex $args 0 ]
        if { ($id != $i) || $caller_type != "merge" } {
            if !$OPTIONS(syncscroll) {
                continue
            }
            if { [ set size_merge$i ] == 0 } {
                continue
            }
            set start [ expr { $start * [ set size_merge$i ] / [ set size_merge$i ] } ]
        }

        $WIDGETS(h_scroll_merge_$i) set $start [ expr { $start + [ set size_merge$i ] } ]
        $MERGE_TEXT_WDG($i) xview moveto $start

        set H_SYNC($caller_type,$i) 1
    }

    update idletasks
    after idle { catch { array unset ::Yadt::H_SYNC } }
}

#===============================================================================

proc ::Yadt::Toggle_Merge_Window {} {

    variable ::Yadt::WIDGETS
    variable ::Yadt::OPTIONS
    variable ::Yadt::TMP_OPTIONS
    variable ::Yadt::WDG_OPTIONS
    variable ::Yadt::TEXT_WDG

    switch -- $OPTIONS(preview_shown) {
        1 {
            # Show Merge Window
            ::Yadt::Yadt_Paned -show $WIDGETS(main_paned) $WIDGETS(bottom_wnd)
        }
        0 {
            # Hide merge window
            ::Yadt::Yadt_Paned -hide $WIDGETS(main_paned) $WIDGETS(bottom_wnd)
            set WDG_OPTIONS(active_window) $TEXT_WDG(1)
        }
    }

    ::Yadt::Update_Find_Combo_Values
    ::Yadt::Set_Find_Element
    ::Yadt::Update_Widgets

    set TMP_OPTIONS(preview_shown) $OPTIONS(preview_shown)
}

#===============================================================================

proc ::Yadt::Toggle_Merge_Mode {} {

    variable ::Yadt::OPTIONS
    variable ::Yadt::TMP_OPTIONS
    variable ::Yadt::DIFF_INT
    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::RANGES2DIFF
    variable ::Yadt::RANGES2DIFF
    variable ::Yadt::DIFF2RANGES

    if { $DIFF_TYPE == 2 } {
        return
    }

    switch -- $OPTIONS(merge_mode) {
        normal {
            set DIFF_INT(pos) $RANGES2DIFF($DIFF_INT(pos))
        }
        expert {
            foreach range $DIFF2RANGES($DIFF_INT(pos)) {
                ::Yadt::Current_Tag remove $range
            }
            set DIFF_INT(pos) [ lindex $DIFF2RANGES($DIFF_INT(pos)) 0 ]
        }
    }

    ::Yadt::Set_Diff_Indicator $DIFF_INT(pos) 0 1

    set TMP_OPTIONS(merge_mode) $OPTIONS(merge_mode)
}

#===============================================================================


################################################################################
# Navigation and update procs                                                  #
################################################################################

#===============================================================================

proc ::Yadt::Get_Top_Line_Num_From_Text_Widget { wdg } {

    set line [ lindex [ $wdg dump -all @0,0 ] end ]
    set line [ lindex [ split $line . ] 0 ]
    set line [ expr $line - 1 ]

    return $line
}

#===============================================================================

proc ::Yadt::Set_Find_Element {} {

    variable ::Yadt::WDG_OPTIONS

    set WDG_OPTIONS(find_where) $WDG_OPTIONS($WDG_OPTIONS(active_window))
}

#===============================================================================

proc ::Yadt::Diff_Center {} {

    global ::Yadt::V_SYNC
    variable ::Yadt::DIFF_TYPE

    set ::Yadt::V_SYNC(text) 1    

    switch -- $DIFF_TYPE {
        2 {
            ::Yadt::Diff2_Center
        }
        3 {
            ::Yadt::Diff3_Center
        }
    }

    after idle { unset -nocomplain ::Yadt::V_SYNC(text) }
}

#===============================================================================

proc ::Yadt::Diff2_Center {} {

    variable ::Yadt::WIDGETS
    variable ::Yadt::DIFF_INT
    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::WDG_OPTIONS
    variable ::Yadt::OPTIONS
    variable ::Yadt::TEXT_WDG
    variable ::Yadt::TEXT_NUM_WDG
    variable ::Yadt::TEXT_INFO_WDG

    if { !$DIFF_INT(count) } return

    if ![ info exists DIFF_INT($DIFF_INT(pos),scrdiff) ] return

    foreach { start end type } $DIFF_INT($DIFF_INT(pos),scrdiff) { }

    set opix [ winfo reqheight $TEXT_WDG(1) ]
    if { $opix == 0 } return

    set olin [ $TEXT_WDG(1) cget -height ]
    set npix [ winfo height $TEXT_WDG(1) ]
    set winlines [ expr { $npix * $olin / $opix } ]
    set diffsize [ expr { $end - $start + 1 } ]

    if { $diffsize < $winlines } {
        set h [ expr { ($winlines - $diffsize) / 2 } ]
    } else {
        set h 2
    }

    for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
        set y($i) [ expr { $start - $h } ]
        if { $y($i) < 0 } {
            set y($i) 0
        }
    }

    for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
        $TEXT_WDG($i) mark set insert $start.0
    }

    for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
        if { !$OPTIONS(syncscroll) && \
                 $WDG_OPTIONS(active_window) != $TEXT_WDG($i) } continue
        $TEXT_WDG($i) yview $y($i)
        $TEXT_NUM_WDG($i) yview $y($i)
        $TEXT_INFO_WDG($i) yview $y($i)
    }
    eval ::Yadt::Move_Thumb [ $TEXT_WDG(1) yview ]
    eval $WIDGETS(v_scroll) set [ $TEXT_WDG(1) yview ]

    ::Yadt::Merge_Center
}

#===============================================================================

proc ::Yadt::Diff3_Center {} {

    variable ::Yadt::WIDGETS
    variable ::Yadt::DIFF3
    variable ::Yadt::DIFF_INT
    variable ::Yadt::WDG_OPTIONS
    variable ::Yadt::OPTIONS
    variable ::Yadt::TEXT_WDG
    variable ::Yadt::TEXT_NUM_WDG
    variable ::Yadt::TEXT_INFO_WDG
    variable ::Yadt::DIFF_TYPE

    if ![ llength [ array names DIFF3 *,which_file ] ] return

    foreach { start end type } [ ::Yadt::Get_Diff_Scr_Params $DIFF_INT(pos) ] { }
    if { $start == -1 && $end == -1 && $type == -1 } return

    set opix [ winfo reqheight $TEXT_WDG(1) ]
    if { $opix == 0 } return

    set olin [ $TEXT_WDG(1) cget -height ]
    set npix [ winfo height $TEXT_WDG(1) ]
    set winlines [ expr { $npix * $olin / $opix } ]

    set diffsize [ expr { $end - $start + 1 } ]

    if { $diffsize < $winlines } {
        set h [ expr { ($winlines - $diffsize) / 2 } ]
    } else {
        set h 2
    }

    for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
        set y($i) [ expr { $start - $h } ]
        if { $y($i) < 0 } {
            set y($i) 0
        }
    }

    for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
        $TEXT_WDG($i) mark set insert $start.0
    }

    for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
        if { !$OPTIONS(syncscroll) && \
                 $WDG_OPTIONS(active_window) != $TEXT_WDG($i) } continue
        $TEXT_WDG($i) yview $y($i)
        $TEXT_NUM_WDG($i) yview $y($i)
        $TEXT_INFO_WDG($i) yview $y($i)
    }
    eval ::Yadt::Move_Thumb [ $TEXT_WDG(1) yview ]
    eval $WIDGETS(v_scroll) set [ $TEXT_WDG(1) yview ]

    ::Yadt::Merge_Center
}

#===============================================================================

proc ::Yadt::Merge_Center {} {

    global ::Yadt::V_SYNC
    variable ::Yadt::DIFF_TYPE

    set ::Yadt::V_SYNC(merge) 1

    switch -- $DIFF_TYPE {
        2 {
            ::Yadt::Merge2_Center
        }
        3 {
            ::Yadt::Merge3_Center
        }
    }

    after idle { unset -nocomplain ::Yadt::V_SYNC(merge) }
}

#===============================================================================

proc ::Yadt::Merge2_Center {} {

    variable ::Yadt::WIDGETS
    variable ::Yadt::MERGE_START
    variable ::Yadt::DIFF_INT
    variable ::Yadt::MERGE_TEXT_WDG
    variable ::Yadt::MERGE_INFO_WDG
    variable ::Yadt::OPTIONS
    variable ::Yadt::WDG_OPTIONS

    if { $DIFF_INT(count) == 0 } return

    set difflines [ ::Yadt::Diff_Size $DIFF_INT(pos) $DIFF_INT(normal_merge$DIFF_INT(pos)) ]
    set yview [ $MERGE_TEXT_WDG(2) yview ]

    set ywindow [ expr { [ lindex $yview 1 ] - [ lindex $yview 0 ] } ]
    set firstline [ $MERGE_TEXT_WDG(2) index mark$DIFF_INT(pos) ]
    set totallines [ $MERGE_TEXT_WDG(2) index end ]

    if { $totallines == 0 } return

    if { !$OPTIONS(syncscroll) && \
             $WDG_OPTIONS(active_window) != $MERGE_TEXT_WDG(2) } return

    if { $difflines / $totallines < $ywindow } {
        $MERGE_TEXT_WDG(2) yview moveto [ expr { ($firstline + $difflines / 2) / $totallines - $ywindow / 2 } ]
    } else {
        $MERGE_TEXT_WDG(2) yview moveto [ expr { ($firstline - 1) / $totallines } ] 
    }

    set line [ ::Yadt::Get_Top_Line_Num_From_Text_Widget $MERGE_TEXT_WDG(2) ]
    foreach wdg [ ::Yadt::Get_Merge_Wdg_List ] {
        $wdg yview $line
    }
    eval $WIDGETS(v_scroll_merge) set [ $MERGE_TEXT_WDG($MERGE_START) yview ]
}

#===============================================================================

proc ::Yadt::Merge3_Center {} {

    variable ::Yadt::WIDGETS
    variable ::Yadt::DIFF_INT
    variable ::Yadt::MERGE_TEXT_WDG
    variable ::Yadt::MERGE_INFO_WDG
    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::MERGE_START
    variable ::Yadt::OPTIONS
    variable ::Yadt::WDG_OPTIONS
    variable ::Yadt::RANGES2DIFF

    if { $DIFF_INT(count) == 0 } return

    set difflines {}
    for { set j $MERGE_START } { $j <= $DIFF_TYPE } { incr j } {
        set num [ ::Yadt::Diff_Size $DIFF_INT(pos) $DIFF_INT($OPTIONS(merge_mode)_merge$DIFF_INT(pos),$j) ]
        lappend difflines $num
    }

    set difflines [ eval ::CmnTools::MaxN $difflines ]

    for { set i $MERGE_START } { $i <= $DIFF_TYPE } { incr i } {

        if { !$OPTIONS(syncscroll) && \
                 $WDG_OPTIONS(active_window) != $MERGE_TEXT_WDG($i) } continue

        set yview [ $MERGE_TEXT_WDG($i) yview ]
        set ywindow [ expr { [ lindex $yview 1 ] - [ lindex $yview 0 ] } ]

        set pos $DIFF_INT(pos)
        set offset 0
        if { $OPTIONS(merge_mode) == "expert" } {
            set offset [ ::Yadt::Get_Range_Offset_Inside_Diff $DIFF_INT(pos) $i ]
            set pos $RANGES2DIFF($DIFF_INT(pos))
        }

        set firstline [ expr { [ $MERGE_TEXT_WDG($i) index mark${i}_$pos ] + $offset } ]
        set totallines [ $MERGE_TEXT_WDG($i) index end ]

        if { $totallines == 0 } continue

        if { $difflines / $totallines < $ywindow } {
            $MERGE_TEXT_WDG($i) yview moveto \
                [ expr { ($firstline + $difflines / 2) / $totallines - $ywindow / 2 } ]
        } else {
            $MERGE_TEXT_WDG($i) yview moveto \
                [ expr { ($firstline - 1) / $totallines } ]
        }
        
        set line [ ::Yadt::Get_Top_Line_Num_From_Text_Widget $MERGE_TEXT_WDG($i) ]
        foreach wdg [ ::Yadt::Get_Merge_Wdg_List $i ] {
            $wdg yview $line
        }
    }
    eval $WIDGETS(v_scroll_merge) set [ $MERGE_TEXT_WDG($MERGE_START) yview ]
}

#===============================================================================

proc ::Yadt::Move_Indicator_To {} {

    variable ::Yadt::WDG_OPTIONS

    set value $WDG_OPTIONS(curr_diff)

    if { $value == "" } return

    regexp {([0-9]+) *:} $value matchVar ind
    ::Yadt::Set_Diff_Indicator $ind 0 1
}

#===============================================================================

proc ::Yadt::Focus_Active_Window {} {

     variable ::Yadt::WDG_OPTIONS
     variable ::Yadt::TEXT_WDG

     set wdg $TEXT_WDG(1)
     if { [ info exists WDG_OPTIONS(active_window) ] && \
              $WDG_OPTIONS(active_window) != "" } {
         set wdg $WDG_OPTIONS(active_window)
     }

     focus -force $wdg
}

#===============================================================================

proc ::Yadt::Move_Nearest { wdg mode args } {

    switch -- $mode {
        "xy" {
            lassign $args x y
            set index [ $wdg index @$x,$y ]
            set line_num [ expr { int($index) } ]
        }
        "mark" {
            set index [ $wdg index [ lindex $args 0 ] ]
            set line_num [ expr { int($index) } ]
        }
    }

    set diff [ ::Yadt::Find_Diff $line_num -screen ]

    ::Yadt::Set_Diff_Indicator $diff 0 1 "normal"
}

#===============================================================================

proc ::Yadt::Find_Diff { line_num find_where } {

    variable ::Yadt::DIFF_TYPE

    switch -- $find_where {
        -screen {
            set search_type scrdiff
        }
        -original {
            set search_type pdiff
        }
        default {
            return -code error "Unsupported value for find_where <$find_where>"
        }
    }

    switch -- $DIFF_TYPE {
        2 {
            return [ ::Yadt::Find2_Diff $line_num $search_type ]
        }
        3 {
            return [ ::Yadt::Find3_Diff $line_num $search_type ]
        }
    }
}

#===============================================================================

proc ::Yadt::Find2_Diff { line_num search_type } {

    variable ::Yadt::DIFF_INT

    set top $line_num

    for { set low 1; set high $DIFF_INT(count); set i [ expr { ($low + $high) / 2 } ] } \
        { $i >= $low } \
        { set i [ expr { ($low + $high) / 2 } ] } {

            foreach { line s(1) e(1) s(2) e(2) type } $DIFF_INT($i,$search_type) { }

            if { $s(1) > $top } {
                set high [ expr { $i - 1 } ]
            } else {
                set low [ expr { $i + 1 } ]
            }
        }

    set i [ ::CmnTools::MaxN 1 [ ::CmnTools::MinN $i $DIFF_INT(count) ] ]

    if { $i > 0 && $i < $DIFF_INT(count) } {
        set nexts1 [ lindex $DIFF_INT([ expr { $i + 1 } ],scrdiff) 0 ]
        set e(1) [ lindex $DIFF_INT($i,scrdiff) 1 ]
        if { $nexts1 - $top < $top - $e(1) } {
            incr i
        }
    }

    return $i
}

#===============================================================================

proc ::Yadt::Find3_Diff { line_num search_type } {

    variable ::Yadt::DIFF_INT
    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::OPTIONS
    variable ::Yadt::DIFF2RANGES

    set top $line_num

    for { set low 1; set high $DIFF_INT(count); set diff_id [ expr { ($low + $high) / 2 } ] } \
        { $diff_id >= $low } \
        { set diff_id [ expr { ($low + $high) / 2 } ] } {

            for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
                switch -- $search_type {
                    pdiff {
                foreach [ list thisdiff($i) s($i) e($i) type($i) ] \
                    $DIFF_INT($diff_id,$i,$search_type) { }
            }
                    scrdiff {
                        foreach [ list thisdiff($i) s($i) e($i) type($i) ] \
                            $DIFF_INT($diff_id,$search_type) { }
                    }
                }
            }

            if { $s(1) > $top } {
                set high [ expr { $diff_id - 1 } ]
            } else {
                set low [ expr { $diff_id + 1 } ]
            }
        }

    set diff_id [ ::CmnTools::MaxN 1 [ ::CmnTools::MinN $diff_id $DIFF_INT(count) ] ]

    if { $diff_id > 0 && $diff_id < $DIFF_INT(count) } {
        set nexts1 [ lindex $DIFF_INT([ expr { $diff_id + 1 } ],scrdiff) 0 ]
        set e(1) [ lindex $DIFF_INT($diff_id,scrdiff) 1 ]
        if { $nexts1 - $top < $top - $e(1) } {
            incr diff_id
        }
    }

    return $diff_id
}

#===============================================================================

proc ::Yadt::Set_Diff_Indicator { value { relative 1 } { setpos 1 } { value_type "" } } {

    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::DIFF2
    variable ::Yadt::DIFF3
    variable ::Yadt::DIFF_INT
    variable ::Yadt::OPTIONS
    variable ::Yadt::RANGES
    variable ::Yadt::DIFF2RANGES
    variable ::Yadt::RANGES2DIFF

    if { $value == "first" } {
        set value 1
        set relative 0
    }

    switch -- $DIFF_TYPE {
        2 {
            set num_diff [ llength $DIFF2(diff) ]
        }
        3 {
            switch -- $OPTIONS(merge_mode) {
                normal {
                    set num_diff [ llength [ array names DIFF3 *,which_file ] ]
                }
                expert {
                    set num_diff [ llength [ array names RANGES ] ]
                }
        }
    }
}

    if { $num_diff == 0 } return

    if { $value == "last" } {
        set value $num_diff
        set relative 0
    }

    ::Yadt::Current_Tag remove $DIFF_INT(pos)

    if { $value_type == "normal" && \
             $OPTIONS(merge_mode) == "expert" && \
             $DIFF_TYPE == 3 } {
        set value [ lindex $DIFF2RANGES($value) 0 ]
    }

    if { $relative } {
        set DIFF_INT(pos) [ expr $DIFF_INT(pos) + $value ]
    } else {
        set DIFF_INT(pos) $value
    }
    set DIFF_INT(pos) [ ::CmnTools::MaxN $DIFF_INT(pos) 1 ]
    set DIFF_INT(pos) [ ::CmnTools::MinN $DIFF_INT(pos) $num_diff ]

    ::Yadt::Current_Tag add $DIFF_INT(pos)

    ::Yadt::Update_Widgets
}

#===============================================================================

proc ::Yadt::Goto_Conflict { value { setpos 1 } } {

    variable ::Yadt::DIFF3
    variable ::Yadt::DIFF_INT

    #Find next conflict
    set found [ ::Yadt::Find_Conflict $value ]

    if { $found } {
        ::Yadt::Set_Diff_Indicator $found 0 1 "normal"
        ::Yadt::Update_Widgets
    }
}

#===============================================================================

proc ::Yadt::Find_Conflict { direction } {

    variable ::Yadt::DIFF3
    variable ::Yadt::DIFF_INT
    variable ::Yadt::OPTIONS
    variable ::Yadt::RANGES
    variable ::Yadt::RANGES2DIFF

    set num_diff [ llength [ array names DIFF3 *,which_file ] ]


    switch -- $OPTIONS(merge_mode) {
        normal {
            set diff_id $DIFF_INT(pos)
        }
        expert {
            set diff_id $RANGES2DIFF($DIFF_INT(pos))
        }
    }

    if { $num_diff == 0 } {
        return 0
    }

    set found 0

    switch -- $direction {
        1 {
            for { set i [ expr $diff_id + 1 ] } { $i <= $num_diff } { incr i } {
                if { $DIFF3($i,which_file) == 0 } {
                    set found $i
                    break
                }
            }
        }
        -1 {
            for { set i [ expr $diff_id - 1 ] } { $i > 0 } { incr i -1 } {
                if { $DIFF3($i,which_file) == 0 } {
                    set found $i
                    break
                }
            }
        }
        default {
            return -code error "Wrong value for <$direction> in [ lindex [ info level 0 ] 0 ]"
        }
    }

    return $found
}

#===============================================================================

proc ::Yadt::Goto_Unresolved { value target { setpos 1 } } {

    variable ::Yadt::DIFF3
    variable ::Yadt::DIFF_INT
    variable ::Yadt::OPTIONS
    variable ::Yadt::RANGES

    switch -- $OPTIONS(merge_mode) {
        normal {
    set num_diff [ llength [ array names DIFF3 *,which_file ] ]
    }
        expert {
            set num_diff [ llength [ array names RANGES ] ]
        }
    }

    if { $num_diff == 0 } return

    #Find next conflict
    set found [ ::Yadt::Find_Unresolved $value $target $num_diff ]

    if { $found } {
        ::Yadt::Set_Diff_Indicator $found 0 1
        ::Yadt::Update_Widgets
    }
}

#===============================================================================

proc ::Yadt::Find_Unresolved { direction target num_diff } {

    variable ::Yadt::DIFF3
    variable ::Yadt::DIFF_INT
    variable ::Yadt::OPTIONS

    set found 0

    switch -- $direction {
        1 {
            for { set i [ expr $DIFF_INT(pos) + 1 ] } { $i <= $num_diff } { incr i } {
                if { $DIFF_INT($i,$target,$OPTIONS(merge_mode)_resolved) == 0 } {
                    set found $i
                    break
                }
            }
        }
        -1 {
            for { set i [ expr $DIFF_INT(pos) - 1 ] } { $i > 0 } { incr i -1 } {
                if { $DIFF_INT($i,$target,$OPTIONS(merge_mode)_resolved) == 0 } {
                    set found $i
                    break
                }
            }
        }
        default {
            return -code error "Wrong value for <$direction> in [ lindex [ info level 0 ] 0 ]"
        }
    }

    return $found
}

#===============================================================================

proc ::Yadt::Update_Widgets {} {

    variable ::Yadt::DIFF_INT
    variable ::Yadt::DIFF3
    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::OPTIONS
    variable ::Yadt::RANGES

    set diff_id $DIFF_INT(pos)

    switch -- $DIFF_TYPE {
        2 {
            set num_diff $DIFF_INT(count)
            ::Yadt::Update_Widgets2 $num_diff
        }
        3 {
            switch -- $OPTIONS(merge_mode) {
                normal {
            set num_diff [ llength [ array names DIFF3 *,which_file ] ]
                }
                expert {
                    set num_diff [ llength [ array names RANGES ] ]
                }
            }
            ::Yadt::Update_Widgets3 $num_diff
        }
    }

    ::Yadt::Update_Common_Widgets $diff_id $num_diff
}

#===============================================================================

proc ::Yadt::Update_Widgets2 { num_diff } {

    variable ::Yadt::WDG_OPTIONS
    variable ::Yadt::WIDGETS
    variable ::Yadt::DIFF_INT
    variable ::Yadt::DIFF_TYPE

    $WIDGETS(tool_bar).ignore_blanks configure -state normal

    set state disabled
    if  { $num_diff > 0 } {

        if { $DIFF_INT(pos) == 0 } {
            set DIFF_INT(pos) 1
        }

        if { [ regexp -- 1 $DIFF_INT(normal_merge$DIFF_INT(pos)) ] && \
                 $DIFF_INT(normal_merge$DIFF_INT(pos)) != -1 } {
            set WDG_OPTIONS(toggleA) 1
        } else { 
            set WDG_OPTIONS(toggleA) 0
        }

        if { [ regexp -- 2 $DIFF_INT(normal_merge$DIFF_INT(pos)) ] && \
                 $DIFF_INT(normal_merge$DIFF_INT(pos)) != -1 } {
            set WDG_OPTIONS(toggleB) 1
        } else { 
            set WDG_OPTIONS(toggleB) 0
        }
        set state normal
    }

    $WIDGETS(tool_bar).choice_A configure -state $state
    $WIDGETS(tool_bar).choice_B configure -state $state
}

#===============================================================================

proc ::Yadt::Update_Widgets3 { num_diff } {

    variable ::Yadt::OPTIONS
    variable ::Yadt::WDG_OPTIONS
    variable ::Yadt::WIDGETS
    variable ::Yadt::DIFF_INT
    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::MERGE_START

    $WIDGETS(tool_bar).ignore_blanks configure -state normal
    $WIDGETS(menu_file) entryconfigure $WIDGETS(menu_item,file,write_cvs) -state normal

    set choice_buttons [ list \
                             $WIDGETS(tool_bar).choice2_A \
                             $WIDGETS(tool_bar).choice2_B \
                             $WIDGETS(tool_bar).choice2_C \
                             $WIDGETS(tool_bar).choice3_A \
                             $WIDGETS(tool_bar).choice3_B \
                             $WIDGETS(tool_bar).choice3_C ]

    set choice_state disabled
    set prev_unresolved_state disabled
    set next_unresolved_state disabled
    set mark_state disabled

    if  { $num_diff > 0 } {
        set choice_state normal

        if { $DIFF_INT(pos) == 0 } {
            set DIFF_INT(pos) 1
        }

        # Setting merge chosen values
        for { set i $MERGE_START } { $i <= $DIFF_TYPE } { incr i } {

            if { [ regexp -- 1 $DIFF_INT($OPTIONS(merge_mode)_merge$DIFF_INT(pos),$i) ] && \
                     $DIFF_INT($OPTIONS(merge_mode)_merge$DIFF_INT(pos),$i) != -1 } {
                set WDG_OPTIONS(toggle3${i}A) 1
            } else { 
                set WDG_OPTIONS(toggle3${i}A) 0
            }
            if [ regexp -- 2 $DIFF_INT($OPTIONS(merge_mode)_merge$DIFF_INT(pos),$i) ] {
                set WDG_OPTIONS(toggle3${i}B) 1
            } else { 
                set WDG_OPTIONS(toggle3${i}B) 0
            }
            if [ regexp -- 3 $DIFF_INT($OPTIONS(merge_mode)_merge$DIFF_INT(pos),$i) ] {
                set WDG_OPTIONS(toggle3${i}C) 1
            } else { 
                set WDG_OPTIONS(toggle3${i}C) 0
            }
            set WDG_OPTIONS(resolve_status_$i) $DIFF_INT($DIFF_INT(pos),$i,$OPTIONS(merge_mode)_resolved)

            if { $WDG_OPTIONS(resolve_status_$i) } {
                set action -mark
            } else {
                set action -unmark
            }
            ::Yadt::Mark_Resolve_Handle $i mark_resolved $action -current 0

            if [ ::Yadt::Find_Unresolved -1 $i $num_diff ] {
                set prev_unresolved_state normal
            }
            if [ ::Yadt::Find_Unresolved 1 $i $num_diff ] {
                set next_unresolved_state normal
            }
            set mark_state normal
        }
    }

    # Choice buttons
        foreach choice_button $choice_buttons {
            if { [ winfo exists $choice_button ] } {
            $choice_button configure -state $choice_state
            }
        }
        
    # Resolve/Mark buttons
        for { set i $MERGE_START } { $i <= $DIFF_TYPE } { incr i } {
        $WIDGETS(prev_unresolved_$i) configure -state $prev_unresolved_state
        $WIDGETS(next_unresolved_$i) configure -state $next_unresolved_state
        $WIDGETS(mark$i) configure -state $mark_state
    }
}

#===============================================================================

proc ::Yadt::Update_Common_Widgets { diff_id num_diff } {

    variable ::Yadt::WIDGETS
    variable ::Yadt::OPTIONS
    variable ::Yadt::WDG_OPTIONS
    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::MERGE_START
    variable ::Yadt::DIFF_INT
    variable ::Yadt::DIFF3

    # Status bar
    switch -- $OPTIONS(merge_mode) {
        normal {
            set units "diffs"
        }
        expert {
            set units "ranges"
        }
    }
    ::Yadt::Status_Msg diffstatus "$units: $diff_id of $num_diff "

    # Center button, combo box and Map
    ::Yadt::Update_Center_Map_Diff_Combo_State $diff_id $num_diff

    if { $num_diff > 0 } {
        if { $DIFF_TYPE == 3 } {
            for { set j $MERGE_START } { $j <= $DIFF_TYPE } { incr j } {
                if [ ::Yadt::Check_Resolved -all $j "" $num_diff ] {
                    ::Yadt::Mark_Resolve_Handle $j mark_all_diff_resolved -mark -all 0
                    ::Yadt::Mark_Resolve_Handle $j mark_all_confl_resolved -mark -conflict 0
                } else {
                    ::Yadt::Mark_Resolve_Handle $j mark_all_diff_resolved -unmark -all 0

                    if [ ::Yadt::Check_Resolved -confl $j confl_exist $num_diff ] {
                        set action -mark
                    } else {
                        set action -unmark
                    }

                    if { !$confl_exist } {
                        $WIDGETS(menu_merge$j) entryconfigure $WIDGETS(menu_item,merge$j,mark_all_confl_resolved) -state disabled
                    } else {
                        ::Yadt::Mark_Resolve_Handle $j mark_all_confl_resolved $action -conflict 0
                    }
                }
            }
        }
    }

    ::Yadt::Update_Save_Buttons_State
    ::Yadt::Update_Merge_Menu_State $num_diff
    ::Yadt::Update_Navigation_Buttons_And_Menu $diff_id $num_diff

    # Conflict navigation buttons and menus
    if { $DIFF_TYPE == 3 } {
        ::Yadt::Update_Conflict_Navigation_Buttons_And_Menu
    }
}

#===============================================================================

proc ::Yadt::Update_Center_Map_Diff_Combo_State { diff_id num_diff } {

    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::WIDGETS
    variable ::Yadt::WDG_OPTIONS
    variable ::Yadt::OPTIONS
    variable ::Yadt::RANGES2DIFF

    set state disabled
    if { $num_diff > 0 } {
        set state normal
    }

    $WIDGETS(tool_bar).center_cur configure -state $state

    switch -- $state {
        "disabled" {
        $WDG_OPTIONS(map_image) blank
        $WIDGETS(diff_combo) configure -values {}
            $WIDGETS(diff_combo).e delete 0 end
        }
        "normal" {
            if { $DIFF_TYPE == 3 && $OPTIONS(merge_mode) == "expert" } {
                set diff_id $RANGES2DIFF($diff_id)
    }
            set i [ expr $diff_id - 1 ]
            $WIDGETS(diff_combo) current $i
            $WIDGETS(diff_combo) selection clear
        }
    }
}

#===============================================================================

proc ::Yadt::Update_Save_Buttons_State {} {

    variable ::Yadt::OPTIONS
    variable ::Yadt::WIDGETS

    if { $OPTIONS(save_always_enabled) } return

    if { $OPTIONS(preview_shown) } {
        $WIDGETS(tool_bar).save configure -state normal
        $WIDGETS(menu_file) entryconfigure $WIDGETS(menu_item,file,save) -state normal
        $WIDGETS(menu_file) entryconfigure $WIDGETS(menu_item,file,save_exit) -state normal
    } else {
        $WIDGETS(tool_bar).save configure -state disabled
        $WIDGETS(menu_file) entryconfigure $WIDGETS(menu_item,file,save) -state disabled
        $WIDGETS(menu_file) entryconfigure $WIDGETS(menu_item,file,save_exit) -state disabled
    }
}

#===============================================================================

proc ::Yadt::Update_Merge_Menu_State { num_diff } {

    variable ::Yadt::OPTIONS
    variable ::Yadt::WIDGETS
    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::MERGE_START

    set merge_item_state disabled
    if { $num_diff > 0 } {
        set merge_item_state "normal"
    }

    for { set i $MERGE_START } { $i <= $DIFF_TYPE } { incr i } {
        set num_elem [ $WIDGETS(menu_merge$i) index end ]
        for { set j 1 } { $j <= $num_elem } { incr j } {
            if { [ $WIDGETS(menu_merge$i) type $j ] == "separator" } continue
                $WIDGETS(menu_merge$i) entryconfigure $j -state $merge_item_state
            }

        if { $OPTIONS(preview_shown) } {
            $WIDGETS(menu_merge$i) entryconfigure $WIDGETS(menu_item,merge$i,show_merge) -label "Hide Merge Window"
            set WIDGETS(menu_item,merge$i,show_merge) "Hide Merge Window"
        } else {
            $WIDGETS(menu_merge$i) entryconfigure $WIDGETS(menu_item,merge$i,show_merge) -label "Show Merge Window"
            set WIDGETS(menu_item,merge$i,show_merge) "Show Merge Window"
        }
    }
}

#===============================================================================

proc ::Yadt::Update_Navigation_Buttons_And_Menu { diff_id num_diff } {

    variable ::Yadt::WIDGETS

    if { $diff_id <= 1 } {
        $WIDGETS(move_first) configure -state disabled
        $WIDGETS(move_prev)  configure -state disabled
        $WIDGETS(menu_view)  entryconfigure $WIDGETS(menu_item,view,first_diff) -state disabled
        $WIDGETS(menu_view)  entryconfigure $WIDGETS(menu_item,view,prev_diff)  -state disabled
        $WIDGETS(popup_menu) entryconfigure $WIDGETS(popup_item,first_diff) -state disabled
        $WIDGETS(popup_menu) entryconfigure $WIDGETS(popup_item,prev_diff)  -state disabled
    } else {
        $WIDGETS(move_first) configure -state normal
        $WIDGETS(move_prev)  configure -state normal
        $WIDGETS(menu_view)  entryconfigure $WIDGETS(menu_item,view,first_diff) -state normal
        $WIDGETS(menu_view)  entryconfigure $WIDGETS(menu_item,view,prev_diff)  -state normal
        $WIDGETS(popup_menu) entryconfigure $WIDGETS(popup_item,first_diff) -state normal
        $WIDGETS(popup_menu) entryconfigure $WIDGETS(popup_item,prev_diff)  -state normal
    }

    if { $diff_id >= $num_diff } {
        $WIDGETS(move_next)  configure -state disabled
        $WIDGETS(move_last)  configure -state disabled
        $WIDGETS(menu_view)  entryconfigure $WIDGETS(menu_item,view,last_diff) -state disabled
        $WIDGETS(menu_view)  entryconfigure $WIDGETS(menu_item,view,next_diff) -state disabled
        $WIDGETS(popup_menu) entryconfigure $WIDGETS(popup_item,last_diff) -state disabled
        $WIDGETS(popup_menu) entryconfigure $WIDGETS(popup_item,next_diff) -state disabled
    } else {
        $WIDGETS(move_next)  configure -state normal
        $WIDGETS(move_last)  configure -state normal
        $WIDGETS(menu_view)  entryconfigure $WIDGETS(menu_item,view,last_diff) -state normal
        $WIDGETS(menu_view)  entryconfigure $WIDGETS(menu_item,view,next_diff) -state normal
        $WIDGETS(popup_menu) entryconfigure $WIDGETS(popup_item,last_diff) -state normal
        $WIDGETS(popup_menu) entryconfigure $WIDGETS(popup_item,next_diff) -state normal
    }
}

#===============================================================================

proc ::Yadt::Update_Conflict_Navigation_Buttons_And_Menu {} {

    variable ::Yadt::WIDGETS

    set next_conflict_state disabled
    set prev_conflict_state disabled

    if [ ::Yadt::Find_Conflict 1 ] {
        set next_conflict_state normal
        }
    if [ ::Yadt::Find_Conflict -1 ] {
        set prev_conflict_state normal
    }

    $WIDGETS(tool_bar).move_next_confl configure -state $next_conflict_state
    $WIDGETS(menu_view)  entryconfigure $WIDGETS(menu_item,view,next_conflict) -state $next_conflict_state
    $WIDGETS(popup_menu) entryconfigure $WIDGETS(popup_item,next_conflict) -state $next_conflict_state

    $WIDGETS(tool_bar).move_prev_confl configure -state $prev_conflict_state
    $WIDGETS(menu_view) entryconfigure $WIDGETS(menu_item,view,prev_conflict) -state $prev_conflict_state
    $WIDGETS(popup_menu) entryconfigure $WIDGETS(popup_item,prev_conflict) -state $prev_conflict_state
}

#===============================================================================

################################################################################
# PREFERENCES                                                                  #
################################################################################

#===============================================================================

proc ::Yadt::Show_Preferences {} {

    global CVS_REVISION
    variable ::Yadt::WIDGETS
    variable ::Yadt::OPTIONS
    variable ::Yadt::WDG_OPTIONS
    variable ::Yadt::PREF
    variable ::Yadt::TMP_OPTIONS

    set wdg $WIDGETS(pref)

    if [ winfo exists $wdg ] {
        destroy $wdg
    }

    toplevel $wdg
    wm withdraw $wdg
    wm title $wdg "$WDG_OPTIONS(yadt_title) $CVS_REVISION Preferences"
    if { [ info exists WIDGETS(window_name) ] &&\
             [ winfo exists $WIDGETS(window_name) ] } {
        wm transient $wdg $WIDGETS(window_name)
    }
    wm resizable $wdg 0 0
    wm minsize $wdg 100 100

    ::Yadt::Init_Pref_Labels

    # Controls frame
    frame $wdg.controls -relief groove -bd 2
    pack $wdg.controls -side bottom -fill x -expand 0 -padx 2 -pady 2

    ::ttk::button $wdg.controls.close -text Close -command [ list destroy $wdg ] -image closeImage -compound left
    pack $wdg.controls.close -side right -padx 5 -pady 5

    ::ttk::button $wdg.controls.help -text Help -command ::Yadt::Show_Preferences_Help -image helpImage -compound left
    pack $wdg.controls.help -side right -padx 5 -pady 5

    ::ttk::button $wdg.controls.save -text Save -command ::Yadt::Save_Preferences -image saveImage -compound left
    pack $wdg.controls.save -side right -padx 5 -pady 5

    ::ttk::button $wdg.controls.apply -text Apply -command ::Yadt::Apply_Preferences -image markImage -compound left
    pack $wdg.controls.apply -side right -padx 5 -pady 5

    ::ttk::button $wdg.controls.defaults -text "Restore Defaults" -command ::Yadt::Restore_Default_Preferences -image preferencesImage -compound left
    pack $wdg.controls.defaults -side left -padx 5 -pady 5

    # Parameters frames
    frame $wdg.layout -relief flat -bd 0
    pack $wdg.layout -side top -fill both -expand 1

    # Geometry
    TitleFrame $wdg.layout.geometry \
        -text "Geometry (Default: $WDG_OPTIONS(yadt_width_default)x$WDG_OPTIONS(yadt_height_default))" \
        -relief groove -bd 2 -side left
    pack $wdg.layout.geometry -side left -fill both -expand 1 -padx 2 -pady 2

    set t_frame [ $wdg.layout.geometry getframe ]

    set wdg_frame [ frame $t_frame.wdg_frame ]
    pack $wdg_frame -side left -fill both -expand 1

    frame $wdg_frame.f_geometry 
    pack $wdg_frame.f_geometry -fill both -expand 1 -side left

    ::Yadt::Pref_Spin_Create $wdg_frame.f_geometry width
    ::Yadt::Pref_Spin_Create $wdg_frame.f_geometry height

    # Position
    TitleFrame $wdg.layout.position \
        -text "Position (Default: +$WDG_OPTIONS(yadt_x_default)+$WDG_OPTIONS(yadt_y_default))" \
        -relief groove -bd 2 -side left
    pack $wdg.layout.position -side left -fill both -expand 1 -padx 2 -pady 2

    set t_frame [ $wdg.layout.position getframe ]

    set wdg_frame [ frame $t_frame.wdg_frame ]
    pack $wdg_frame -side left -fill both -expand 0

    frame $wdg_frame.f_position 
    pack $wdg_frame.f_position -fill both -expand 1 -side top

    ::Yadt::Pref_Spin_Create $wdg_frame.f_position x
    ::Yadt::Pref_Spin_Create $wdg_frame.f_position y

    # Geometry label
    label $wdg.g_preview -textvariable ::Yadt::TMP_OPTIONS(geometry_label) -bd 2 -relief groove -height 2
    pack $wdg.g_preview -fill x -expand 0 -side top -pady 2 -padx 2

    frame $wdg.layout_mode -relief flat -bd 0
    pack $wdg.layout_mode -side top -fill both -expand 1 -padx 0 -pady 0

    # Vertical/Horizontal Layout
    TitleFrame $wdg.layout_mode.diff -text $PREF(diff_layout) -relief groove -bd 2 -side center
    pack $wdg.layout_mode.diff -side left -fill both -expand 1 -padx 2 -pady 2

    foreach param_value [ list vertical horizontal ] {
        ::Yadt::Pref_Radio_Button [ $wdg.layout_mode.diff getframe ] diff_layout $param_value
    }

    # Merge mode: normal or expert
    TitleFrame $wdg.layout_mode.mmode -text $PREF(merge_mode) -relief groove -bd 2 -side center
    pack $wdg.layout_mode.mmode -side left -fill both -expand 1 -padx 2 -pady 2

    foreach param_value [ list normal expert ] {
        ::Yadt::Pref_Radio_Button [ $wdg.layout_mode.mmode getframe ] merge_mode $param_value
    }

    # Display Parameters
    TitleFrame $wdg.display -text "Display Options" -relief groove -bd 2 -side left
    pack $wdg.display -side top -fill both -expand 1 -padx 2 -pady 2

    set frame1 [ frame [ $wdg.display getframe ].frame1 ]
    pack $frame1 -side left -expand 1 -fill both

    foreach param [ list ignore_blanks preview_shown ] {
        ::Yadt::Pref_Check_Button $frame1 $param
    }

    set frame2 [ frame [ $wdg.display getframe ].frame2 ]
    pack $frame2 -side left -expand 1 -fill both

    foreach param [ list show_diff_lines show_inline ] {
        ::Yadt::Pref_Check_Button $frame2 $param
    }

    set frame3 [ frame [ $wdg.display getframe ].frame3 ]
    pack $frame3 -side left -expand 1 -fill both

    foreach param [ list show_tooltips ] {
        ::Yadt::Pref_Check_Button $frame3 $param
    }

    # Navigation Parameters
    TitleFrame $wdg.nav -text "Navigation Options" -relief groove -bd 2 -side left
    pack $wdg.nav -side top -fill both -expand 1 -padx 2 -pady 2

    foreach param [ list syncscroll autocenter automerge ] {
        ::Yadt::Pref_Check_Button [ $wdg.nav getframe ] $param left
    }

    # Text markup Parameters
    TitleFrame $wdg.text -text "Text Markup Options" -relief groove -bd 2 -side left
    pack $wdg.text -side top -fill both -expand 1 -padx 2 -pady 2

    foreach param [ list taginfo tagln tagtext ] {
         ::Yadt::Pref_Check_Button [ $wdg.text getframe ] $param left
    }

    # File translation Parameters
    TitleFrame $wdg.translation -text "File end of line (EOL) translation (diffs recalculation required)" -relief groove -bd 2 -side left
    pack $wdg.translation -side top -fill both -expand 1 -padx 2 -pady 2

    foreach param_value [ list windows unix auto ] {
        ::Yadt::Pref_Radio_Button [ $wdg.translation getframe ] translation $param_value -state normal
    }

    update
    set w [ winfo reqwidth $wdg ]
    set h [ winfo reqheight $wdg ]

    BWidget::place $wdg $w $h center $WIDGETS(window_name) 
    wm deiconify $wdg

    ::Yadt::Main_Window_Configure_Event
}

#===============================================================================

proc ::Yadt::Update_Apply_Pref_Button {} {

    variable ::Yadt::TMP_OPTIONS
    variable ::Yadt::OPTIONS
    variable ::Yadt::WIDGETS
    variable ::Yadt::DIFF_TYPE

    if { ![ info exists WIDGETS(pref) ] || \
             ![ winfo exists $WIDGETS(pref).controls.apply ] } {
        return
    }

    set state disabled

    foreach key [ array names TMP_OPTIONS ] {

        if ![ info exists OPTIONS($key) ] continue

        if { $key == "geometry" } {

            set tmp_geometry $TMP_OPTIONS(geometry,width)x$TMP_OPTIONS(geometry,height)
            if { $TMP_OPTIONS(geometry,x) >= 0 } {
                append tmp_geometry "+"
            }
            append tmp_geometry "$TMP_OPTIONS(geometry,x)"
            if { $TMP_OPTIONS(geometry,y) >= 0 } {
                append tmp_geometry "+"
            }
            append tmp_geometry "$TMP_OPTIONS(geometry,y)"

            if { $tmp_geometry != $OPTIONS(geometry) } {
                set state normal
                continue
            }
        }

        if { $TMP_OPTIONS($key) != $OPTIONS($key) } {
            if { $DIFF_TYPE == 2 } {
                if { $key == "merge_mode" || $key == "automerge" } {
                    continue
                }
            }
            set state normal
            break
        }
    }

    $WIDGETS(pref).controls.apply configure -state $state
}

#===============================================================================

proc ::Yadt::Pref_Spin_Create { s_frame param } {

    global ERROR_CODES
    variable ::Yadt::TMP_OPTIONS
    variable ::Yadt::WIDGETS

    switch -- $param {
        width {
            set from [ lindex [ wm minsize $WIDGETS(window_name) ] 0 ]
            set to [ lindex [ wm maxsize . ] 0 ]
            set l_text "Width:"
        }
        height {
            set from [ lindex [ wm minsize $WIDGETS(window_name) ] 1 ]
            set to [ lindex [ wm maxsize . ] 1 ]
            set l_text "Height:"
        }
        x {
            set to [ expr { [ lindex [ wm maxsize . ] 0 ] - \
                                [ lindex [ wm minsize $WIDGETS(window_name) ] 0 ] } ]
            set from -$to
            set l_text "Left:"
        }
        y {
            set to [ expr { [ lindex [ wm maxsize . ] 1 ] - \
                                [ lindex [ wm minsize $WIDGETS(window_name) ] 1 ] } ]
            set from 0
            set l_text "Top:"
        }
        default {
            return -code ERROR_CODES(error) "Internal error: unsupported spin <$param>"
        }
    }

    label $s_frame.l_$param -text "$l_text\n$from...$to" -anchor e -height 2
    pack $s_frame.l_$param -side left -pady 2 -padx 5

    ::ttk::spinbox $s_frame.${param}_spin \
        -width 5 \
        -from $from \
        -to $to \
        -increment 1 \
        -validate all \
        -validatecommand "::Yadt::Spin_Validate %W %V %P" \
        -textvariable ::Yadt::TMP_OPTIONS(geometry,$param) \
        -command ::Yadt::Update_Apply_Pref_Button
    pack $s_frame.${param}_spin -side left -pady 2 -padx 2

    bind $s_frame.${param}_spin <Return> "
        ::Yadt::Spin_On_Return $s_frame.${param}_spin forced 
    "
}

#===============================================================================

proc ::Yadt::Update_Geometry_Label {} {

    variable ::Yadt::TMP_OPTIONS
    variable ::Yadt::WIDGETS

    set TMP_OPTIONS(geometry) $TMP_OPTIONS(geometry,width)x$TMP_OPTIONS(geometry,height)

    if { $TMP_OPTIONS(geometry,x) >= 0 } {
        append TMP_OPTIONS(geometry) "+"
    }
    append TMP_OPTIONS(geometry) "$TMP_OPTIONS(geometry,x)"
    if { $TMP_OPTIONS(geometry,y) >= 0 } {
        append TMP_OPTIONS(geometry) "+"
    }
    append TMP_OPTIONS(geometry) "$TMP_OPTIONS(geometry,y)"

    set TMP_OPTIONS(geometry_label) "Current Geometry: $TMP_OPTIONS(geometry)"

    ::Yadt::Update_Apply_Pref_Button
}

#===============================================================================

proc ::Yadt::Spin_On_Return { spin_wdg v_event } {

    set value [ $spin_wdg get ]
    ::Yadt::Spin_Validate $spin_wdg $v_event $value
}

#===============================================================================

proc ::Yadt::Spin_Validate { spin_wdg v_event value } {

    variable ::Yadt::TMP_OPTIONS

    set res 1

    switch -- $v_event {
        focusin -
        focusout -
        forced {
            set to_value [ expr int([ $spin_wdg cget -to ]) ]
            if { $value > $to_value } {
                bell
                $spin_wdg set $to_value
                $spin_wdg configure -validate all
            }

            set from_value [ expr int([ $spin_wdg cget -from ]) ]
            if { $value < $from_value } {
                bell
                $spin_wdg set $from_value
                $spin_wdg configure -validate all
            }
        }
        key {
            if { ![ string is integer $value ] && $value != "-" } {
                bell
                set res 0
            }
        }
    }

    return $res
}

#===============================================================================

proc ::Yadt::Pref_Radio_Button { t_frame param value args } {

    variable ::Yadt::OPTIONS
    variable ::Yadt::TMP_OPTIONS

    set state [ ::CmnTools::Get_Arg -state args -default "" ]

    set p_frame [ frame $t_frame.f_${param}_$value ]
    pack $p_frame -side left -fill both -expand 1

    set TMP_OPTIONS($param) $OPTIONS($param)

    if { $state == "" } {
        set state normal
        if { $OPTIONS(external_call) } {
            set state disabled
        }
    }
    ::ttk::radiobutton $p_frame.${param}_$value \
        -text [ string toupper $value 0 0 ] \
        -value $value \
        -state $state \
        -variable ::Yadt::TMP_OPTIONS($param) \
        -command ::Yadt::Update_Apply_Pref_Button

    pack $p_frame.${param}_$value -side left -fill x -expand 1
}

#===============================================================================

proc ::Yadt::Pref_Check_Button { t_frame param { side top } } {

    variable ::Yadt::OPTIONS
    variable ::Yadt::PREF
    variable ::Yadt::TMP_OPTIONS

    frame $t_frame.f_$param
    pack $t_frame.f_$param -side $side -fill both -expand 1

    set TMP_OPTIONS($param) $OPTIONS($param)

    set state normal
    if { $OPTIONS(external_call) } {
        set state disabled
    }
    ::ttk::checkbutton $t_frame.f_$param.ch_$param \
        -text $PREF($param) \
        -onvalue 1 \
        -offvalue 0 \
        -state $state \
        -variable ::Yadt::TMP_OPTIONS($param) \
        -command ::Yadt::Update_Apply_Pref_Button
    pack $t_frame.f_$param.ch_$param -side left -fill x -expand 0
}

#===============================================================================

proc ::Yadt::Restore_Default_Preferences {} {

    variable ::Yadt::DEF_OPTIONS
    variable ::Yadt::WDG_OPTIONS
    variable ::Yadt::TMP_OPTIONS
    variable ::Yadt::OPTIONS

    foreach key [ array names TMP_OPTIONS ] {
        if ![ regexp {^geometry} $key ] {
            set TMP_OPTIONS($key) $DEF_OPTIONS($key)
        } else {
            foreach element [ list width height x y ] {
                set TMP_OPTIONS(geometry,$element)  $WDG_OPTIONS(yadt_${element}_default)
            }
        }
    }

    ::Yadt::Update_Apply_Pref_Button
}

#===============================================================================

proc ::Yadt::Init_Pref_Labels {} {

    variable ::Yadt::PREF
    variable ::Yadt::WDG_OPTIONS

    array unset PREF

    set PREF(ignore_blanks) "Ignore blanks by default"
    set PREF(geometry) "Geometry and position of the $WDG_OPTIONS(yadt_title) window"
    set PREF(diff_layout) {Layout of diff text widgets}
    set PREF(merge_mode) {3-way Merge Mode}
    set PREF(preview_shown) {Show merge preview window}
    set PREF(syncscroll) {Synchronize scrollbars}
    set PREF(show_diff_lines) {Show line by line comparison window}
    set PREF(show_inline) {Show differences inline}
    set PREF(autocenter) {Automatically center current diff region}
    set PREF(automerge) {Perform auto-merge after start}
    set PREF(show_tooltips) {Show balloon tooltips}
    set PREF(taginfo) {Highlight change bars}
    set PREF(tagln) {Highlight line numbers}
    set PREF(tagtext) {Highlight file contents}
    set PREF(translation) {File end of line translation}
}

#===============================================================================

proc ::Yadt::Save_Preferences {} {

    global tcl_platform CVS_REVISION
    variable ::Yadt::DEF_OPTIONS
    variable ::Yadt::PREF
    variable ::Yadt::TMP_OPTIONS
    variable ::Yadt::WDG_OPTIONS
    variable ::Yadt::OPTIONS

    if [ file exists $WDG_OPTIONS(rcfile) ] {
        file rename -force $WDG_OPTIONS(rcfile) "$WDG_OPTIONS(rcfile)~"
    }

    # Here 'modified' variable means differrence not from rc file,
    # but from default YaDT settings
    # Therefore, rc file will be deleted only in case 
    # when all current parameters are equal to YaDT internal defaults
    set modified 0

    set fd [ open $WDG_OPTIONS(rcfile) w ]

    puts $fd "# This file was generated by $WDG_OPTIONS(yadt_title) $CVS_REVISION"
    puts $fd "# [ clock format [ clock seconds ] ]\n"

    foreach key [ array names TMP_OPTIONS ] {
        # TMP_OPTIONS contain several additional options like (geometry,width)
        # so we have to skip them
        if ![ info exists PREF($key) ] continue
        if ![ info exists DEF_OPTIONS($key) ] continue

        # There is no need to save option if it equals to the default value
        if { $key != "geometry" && $TMP_OPTIONS($key) == $DEF_OPTIONS($key) } continue

        # In any other case - option is to be saved

        # Only parameter geometry needs special treatment
        if { $key == "geometry" } {

            set save_geometry 0

            if [ ::CmnTools::Parse_WM_Geometry $TMP_OPTIONS(geometry) -width width -height height -left x -top y ] {
                if { [ info exists width ] && [ info exists height ] } {
                    if { $width != $WDG_OPTIONS(yadt_width_default) } {
                        set save_geometry 1
                    }
                    if { $height != $WDG_OPTIONS(yadt_height_default) } {
                        set save_geometry 1
                    }
                }

                if { [ info exists x ] && [ info exists y ] } {
                    if { $x != $WDG_OPTIONS(yadt_x_default) } {
                        set save_geometry 1
                    }
                    if { $y != $WDG_OPTIONS(yadt_y_default) } {
                        set save_geometry 1
                    }
                }
            }

            if { !$save_geometry } {
                continue
            }
        }

        set modified 1

        regsub "\n" $PREF($key) "\n# " comment
        puts $fd "# $comment"
        # Don't modify format of the following output! 
        # The format is used in proc.::CmnTools::Parse_Yadt_Customization_Data:
        puts $fd "define $key <$TMP_OPTIONS($key)>\n"
    }

    close $fd

    if { !$modified } {
        file delete $WDG_OPTIONS(rcfile)
    } else {
        if { $tcl_platform(platform) == "windows" } {
            file attribute $WDG_OPTIONS(rcfile) -hidden 1
        }
    }

    if { $OPTIONS(external_call) } {
        puts stdout "SavePref"
    }
}

#===============================================================================

proc ::Yadt::Apply_Preferences {} {

    global ERROR_CODES tcl_platform
    variable ::Yadt::OPTIONS
    variable ::Yadt::TMP_OPTIONS
    variable ::Yadt::WIDGETS
    variable ::Yadt::DIFF_INT
    variable ::Yadt::DIFF_TYPE

    set delayed_cmds {}

    set keys [ array names TMP_OPTIONS ]

    array set special_keys {
        ignore_blanks ::Yadt::Recompute_Diff_On_Bs_Change
        merge_mode    ::Yadt::Toggle_Merge_Mode
        automerge     ::Yadt::Auto_Merge3
    }

    set rediff 0
    set idx [ lsearch $keys ignore_blanks ]
    if { $idx != -1 } {
        if { $OPTIONS(ignore_blanks) != $TMP_OPTIONS(ignore_blanks) } {
            set rediff 1
            set OPTIONS(ignore_blanks) $TMP_OPTIONS(ignore_blanks)
            set keys [ lreplace $keys $idx $idx ]
            lappend delayed_cmds $special_keys(ignore_blanks)
        }
    }

    if { $DIFF_TYPE == 3 } {
        set idx [ lsearch $keys merge_mode ]
        if { $idx != -1 } {
            if { $OPTIONS(merge_mode) != $TMP_OPTIONS(merge_mode) } {
                set OPTIONS(merge_mode) $TMP_OPTIONS(merge_mode)
                set keys [ lreplace $keys $idx $idx ]
                lappend delayed_cmds $special_keys(merge_mode)
            }
        }
    }

    set idx [ lsearch $keys automerge ]
    if { $idx != -1 } {
        if { $OPTIONS(automerge) != $TMP_OPTIONS(automerge) } {
            set OPTIONS(automerge) $TMP_OPTIONS(automerge)
            if { $rediff == 0 && $OPTIONS(automerge) } {
                lappend delayed_cmds $special_keys(automerge)
            }
        }
    }

    foreach key $keys {

        # TMP_OPTIONS contain several additional options like (geometry,width)
        # so we have to skip them
        if ![ info exists OPTIONS($key) ] continue

        if { $TMP_OPTIONS($key) == $OPTIONS($key) } {
            if { $key != "geometry" } continue
        }

        # In any other case - option is to be applied
        set OPTIONS($key) $TMP_OPTIONS($key)

        switch -- $key {
            geometry {
                # AVS: wm geometry fails if window is maximized.
                # Under windows it is solved by checking if wm state is zoomed;
                # under Linux there is no such state "zoomed"
                # (and no other way to check if window is maximized) -
                # only withdraw and deiconify can solve this :(

                set geometry [ wm geometry $WIDGETS(window_name) ]

                ::CmnTools::Parse_WM_Geometry $geometry -width width -height height -left x -top y

                if { $tcl_platform(platform) == "windows" } {
                    set is_zoomed [ expr { [ wm state $WIDGETS(window_name) ] == "zoomed" ? 1 : 0 } ]
                    if { $is_zoomed } {
                        set x [ winfo rootx $WIDGETS(window_name) ]
                        set y [ winfo rooty $WIDGETS(window_name) ]
                    }
                }

                if { $width == $TMP_OPTIONS($key,width) && \
                         $height == $TMP_OPTIONS($key,height) && \
                         $x == $TMP_OPTIONS($key,x) && \
                         $y == $TMP_OPTIONS($key,y) } continue

                if { $tcl_platform(platform) == "windows" && $is_zoomed } {
                    wm state $WIDGETS(window_name) "normal"
                }

                set tmp_width $TMP_OPTIONS($key,width)
                set tmp_height $TMP_OPTIONS($key,height)
                set tmp_x $TMP_OPTIONS($key,x)
                set tmp_y $TMP_OPTIONS($key,y)

                BWidget::place $WIDGETS(window_name) \
                    $TMP_OPTIONS($key,width) \
                    $TMP_OPTIONS($key,height) \
                    at \
                    $TMP_OPTIONS($key,x) \
                    $TMP_OPTIONS($key,y)

                if { $tcl_platform(os) == "Linux" } {
                    # AVS: we don't want window to be withdrawn and deiconified
                    # every time, but only in case the first geometry failed.

                    set geometry [ wm geometry $WIDGETS(window_name) ]
                    ::CmnTools::Parse_WM_Geometry $geometry -width width -height height -left x -top y

                    if { $width != $tmp_width || \
                             $height != $tmp_height } {
                        wm withdraw $WIDGETS(window_name)
                        BWidget::place $WIDGETS(window_name) \
                            $tmp_width \
                            $tmp_height \
                            at \
                            $tmp_x \
                            $tmp_y
                        wm deiconify $WIDGETS(window_name)
                    }
                }

                ::Yadt::Update_Geometry_Label
                set OPTIONS($key) $TMP_OPTIONS($key)
            }
            diff_layout {
                ::Yadt::Change_Layout
            }
            preview_shown {
                ::Yadt::Toggle_Merge_Window
            }
            syncscroll {
                # Nothing to do. This event is handled by vertical scrolling proc
            }
            show_diff_lines {
                ::Yadt::Toggle_Diff_Lines
            }
            show_inline {
                ::Yadt::Toggle_Inline_Tags
            }
            autocenter {
                if $OPTIONS($key) ::Yadt::Diff_Center
            }
            show_tooltips {
                ::Yadt::Configure_Tooltips
            }
            taginfo -
            tagln -
            tagtext {
                ::Yadt::Clear_Mark_Diffs
                ::Yadt::Set_All_Tags
                ::Yadt::Set_Diff_Indicator $DIFF_INT(pos) 0 1
            }
            ignore_blanks {
            }
            merge_mode {
            }
            automerge {
            }
            translation {
                ::Yadt::Start_New_Diff_Wrapper
                set TMP_OPTIONS(translation) $OPTIONS(translation)
            }
        }
    }

    foreach delayed_cmd $delayed_cmds {
        eval $delayed_cmd
    }

    after idle ::Yadt::Update_Apply_Pref_Button
}

#===============================================================================

proc ::Yadt::Show_Preferences_Help {} {

    variable ::Yadt::WIDGETS
    variable ::Yadt::PREF

    ::Yadt::Init_Pref_Labels

    if [ winfo exists $WIDGETS(pref_help) ] {
        ::Yadt::Draw_Help_Wdg pref_help -show
        return
    }

    set text "
<ttl>Yadt Preferences</ttl>

<hdr>Overview</hdr>

Preferences are stored in a file in your home directory identified by the environment variable <cmp>HOME</cmp>.
If the environment variable <cmp>HOME</cmp> is not set the platform-specific variant of <cmp>'/'</cmp> will be used.
If you are on a Windows platform the file will be named <cmp>_yadt.rc</cmp> and will have the attribute 'hidden'. For all other platforms the file will be named '.yadtrc'. You may override the name and location of this file by specifying <cmp>--config</cmp> options in command line. Also, if it is needed to avoid using this configuration file, specify <cmp>--norc</cmp> option in command line.

Preferences are organized in several groups: <cmp>Geometry</cmp>, <cmp>Position</cmp>, <cmp>Layout</cmp>, <cmp>Display</cmp>, <cmp>Navigation</cmp> and <cmp>Text Markup</cmp> options.

<hdr>Geometry and Position</hdr>

This set of widgets define the size and YaDT window position on the screen. It can be very precisely customized or set to the default value.

<hdr>Layout</hdr>

This defines the layout of the text widgets. Can be vertical or horizontal. The default value is vertical.

<hdr>3-way Merge Mode</hdr>

This defines the 3-way merge mode. In Normal mode, it is possible to merge differences one by one. In Expert mode, YaDT tries to split each difference in a set of smaller ranges to merge which.

<hdr>Display</hdr>

<bld>$PREF(ignore_blanks)</bld>
If set, YaDT by default will ignore blanks while finding files differences.

<bld>$PREF(preview_shown)</bld>
If set, the merge preview window will be shown even if it was not requested in the command line.

<bld>$PREF(syncscroll)</bld>
If set, scrolling either text window will result in all diff windows scrolling.
If not set, the windows will scroll independent of each other.

<bld>$PREF(show_diff_lines)</bld>
If set, show a window at the bottom of the display that shows the current line from each file, one on top of the other. This window is most useful to do a byte-by-byte comparison of a line that has changed.
If not set, the window will not be shown.

<bld>$PREF(show_inline)</bld>
If set, differences in each line are shown right inside of main window.

<bld>$PREF(show_tooltips)</bld>
If set, balloon tooltips will be shown for elements like toolbar buttons.

<hdr>Navigation</hdr>

<bld>$PREF(autocenter)</bld>
If set, whenever a new diff record becomes the current diff record (for example, when pressing the next or previous buttons), the diff record will be automatically centered on the screen.
If unset, no automatic scrolling will occur.

<bld>$PREF(automerge)</bld>
This option will take effect only while comparing three files with merge. If set, YaDT will try to automatically resolve any conflicts if any and put them in merge file. It is actually not recommended to save this option in the file as it might be not you want YaDT to do every next start.

<hdr>Text Markup</hdr>

<bld>$PREF(taginfo)</bld>
If set, change indicators will be highlighted.
If not set, change indicators won't be highlighted.

<bld>$PREF(tagln)</bld>
If set, line numbers for the current diff region are highlighted.
If not set, line numbers won't be highlighted.

<bld>$PREF(tagtext)</bld>
If set, the file contents will be highlighted.
If not set, the file contents won't be highlighted.

<hdr>File end of line translation</hdr>

This option defines how to treat line ending, or end of line (EOL) in files being compared.
By default, this option is set to platform specific value, but sometimes, it is needed to change it, f.i. cwhile omparing windows-styled files from unix-like systems. Differences will be recalculated for changes to take effect.
"



    set text [ subst \
        -nobackslashes -nocommands $text ]

    ::Yadt::Draw_Help_Wdg pref_help -create $text
}

#===============================================================================

################################################################################
# HELP                                                                         #
################################################################################

#===============================================================================

proc ::Yadt::Msg_Box { title text type icon } {

    variable ::Yadt::WIDGETS

    package require BWidget 1.8

    set wdg .yadt_msgbox

    if [ winfo exists $wdg ] {
        destroy $wdg
    }

    toplevel $wdg
    wm withdraw $wdg
    wm title $wdg $title
    if { [ info exists WIDGETS(window_name) ] &&\
             [ winfo exists $WIDGETS(window_name) ] } {
        wm transient $wdg $WIDGETS(window_name)
    }
    wm resizable $wdg 1 1
    wm minsize $wdg 100 100

    ::Yadt::Load_Images

    frame $wdg.controls -relief raised -bd 1
    pack $wdg.controls -side bottom -fill x -expand 0

    frame $wdg.main -relief raised -bd 1
    pack $wdg.main -side top -fill both -expand 1

    ::ttk::button $wdg.controls.close -text OK -command "destroy $wdg" -width 10
    pack $wdg.controls.close -padx 5 -pady 5 -side bottom

    frame $wdg.main.icon -relief flat -bd 0 -width 200
    pack $wdg.main.icon -side left -fill y -expand 0

    label $wdg.main.icon.img -image ${icon}Image
    pack $wdg.main.icon.img -side left -anchor c

    frame $wdg.main.msg -relief raised -bd 0
    pack $wdg.main.msg -fill both -expand 1

    set scrolled_win [ ScrolledWindow $wdg.main.msg.sw ]
    pack $scrolled_win -fill both -expand 1

    text $scrolled_win.txt \
        -wrap word \
        -height 30 \
        -relief flat \
        -bd 5 \
        -exportselection 1 \
        -highlightthickness 0 \
        -background [ $wdg.controls cget -background ] \
        -state normal
    $scrolled_win setwidget $scrolled_win.txt

    $scrolled_win.txt insert end $text
    $scrolled_win.txt configure -state disabled

    update
    set w [ winfo reqwidth $wdg ]
    set h [ winfo reqheight $wdg ]

    BWidget::place $wdg $w $h center
    wm deiconify $wdg
    if { ![ info exists WIDGETS(window_name) ] ||\
             ![ winfo exists $WIDGETS(window_name) ] } {
        catch { grab set $wdg }    
        tkwait window $wdg
    }
}

#===============================================================================

proc ::Yadt::Show_Help {} {

    variable ::Yadt::WIDGETS
    variable ::Yadt::MAP_COLOR

    if ![ array size MAP_COLOR ] {
        ::Yadt::Init_Graphic
    }

    if [ winfo exists $WIDGETS(help_name) ] {
        ::Yadt::Draw_Help_Wdg help_name -show
        return
    }

    set text {
<ttl>What is Yadt?</ttl>

Yadt stands for yet another diff tool.
Yadt can be used for comparing and merging two or three files.
Actually, it is a front-end for diff and diff3 for Unix and Windows.


<ttl>Yadt command line usage</ttl>

There are a number of ways you can call yadt:

<hdr>Briefly</hdr>

<bld>2-Way diffs:</bld>
<cmd>
        yadt [OPTIONS] OLDFILE MYFILE
        yadt [OPTIONS] -r REV FILE
        yadt [OPTIONS] -r REV -r FILE
        yadt [OPTIONS] -r REV1 -r REV2 FILE
        yadt [OPTIONS] FILE -r REV -r
        yadt [OPTIONS] FILE -r -r REV
</cmd>
<bld>3-Way diffs:</bld>
<cmd>
        yadt [OPTIONS] [--diff3] OLDFILE YOURFILE MYFILE
        yadt [OPTIONS] --diff3 FILE
        yadt [OPTIONS] --diff3 -r REV1 -r REV2 -r REV3 FILE
        yadt [OPTIONS] --diff3 -r REV1 FILE -r REV2
        yadt [OPTIONS] --diff3 FILE -r REV1 -r REV2
        yadt [OPTIONS] --diff3 FILE -r REV1 -r REV2 -r
</cmd>
<bld>CVS-conflicts for a file:</bld>
<cmd>
        yadt [OPTIONS] --conflict FILE
</cmd>
<bld>Where OPTIONS can be:</bld>
<cmd>
        --merge MERGE_FILE
        --initline LINE
        --chdir DIR
        --diff-cmd "diff PATH"
        --cvs-cmd "cvs PATH"
        --git-cmd "git PATH"
        --d CVSROOT
        --module CVSMODULE
        --ge[ometry] WIDTHxHEIGHT
        --ho[rizontal] | --ve[rtical]
        --config CONFIG_FILE
        --norc
        --auto-merge
        --translation TRANSLATION
        --merge_mode MERGE_MODE
</cmd>

<hdr>Description</hdr>

<bld>Plain files:</bld>

Compare 2 files:
        <cmd>
        yadt OLDFILE MYFILE
        </cmd>
Compare 3 files:
        <cmd>
        yadt OLDFILE YOURFILE MYFILE
        </cmd>

<bld>Plain file with conflict markers:</bld>
        <cmd>
        yadt --conflict FILE
        </cmd>

<bld>Yadt supports CVS, therefore for source control:</bld>
        <cmd>
        yadt FILE</cmd> - (same as -r)

        Note: in this case, by default YaDT will compare FILE with the "Working revision", not with HEAD.
        To compare with HEAD, use
        <cmd>
        yadt -rHEAD FILE</cmd>
        <cmd>
        yadt -r FILE
        yadt -rREV FILE
        yadt -rREV -r FILE
        yadt -rREV1 -rREV2 FILE
        </cmd>
<bld>It is also possible to compare 3 files with source control:</bld>
        <cmd>
        yadt --diff3 FILE</cmd>        - will compare HEAD revision with "Working revision" with FILE
        <cmd>
        yadt --diff3 -rREV FILE</cmd> - will compare REV revision with "Working revision" with FILE.

        And so on:
        <cmd>
        yadt --diff3 -rREV1 -rREV2 FILE
        yadt --diff3 -rREV1 -rREV2 -rREV3 FILE
        </cmd>
<bld>Also, it is possible to change the sequence for diff3 comparing like:</bld>
        <cmd>
        yadt --diff3 -rREV1 FILE -rREV2</cmd> - will compare REV1 revision with FILE with REV2 revision.

<bld>Other options:</bld>
        <cmd>
        --merge MERGE_FILE</cmd> - will add merge preview window in YaDT layout. Note, if this option is omitted, it is possible to show merge preview window from YaDT menu.

        <itl>Examples:</itl>
        <cmd>
        yadt OLDFILE MYFILE --merge MYFILE_MERGE
        yadt OLDFILE YOURFILE MYFILE --merge MYFILE_MERGE
        yadt --diff3 FILE --merge FILE_MERGE
        </cmd>
        <cmd>--initline LINE</cmd> - specifies the line number where to go when YaDT is started
        <cmd>--chdir DIR</cmd> - specifies the directory where files you want to compare are located. If files are located in current directory, there is no need in this option.
        <cmd>--diff-cmd "diff PATH"</cmd> - specifies other diff utility path to use instead of default.
        <cmd>--cvs-cmd "cvs PATH"</cmd> - specifies other cvs utility path to use instead of default.
        <cmd>--git-cmd "git PATH"</cmd> - specifies other git utility path to use instead of default.
        <cmd>--d CVSROOT</cmd> - specifies cvsroot if needed.

        <itl>Example:</itl>
        
        Comparing files in CVS without having a local copy of CVS repository:
        <cmd>
        yadt --d CVSROOT --module CVSMODULE -r 1.1 -r 1.2 FILE
        </cmd>
        Here CVSROOT and CVSMODULE have the same values as during command:
        <cmd>
        cvs -d CVSROOT co CVSMODULE
        </cmd>

        <cmd>--ge[ometry] WIDTHxHEIGHT</cmd> - specify own YaDT window geometry.

        <itl>Example:</itl>
        <cmd>
        yadt FILE --geometry 800x600
        </cmd>
        <cmd>--ho[rizontal] | --ve[rtical]</cmd> - by default YaDT has vertical layout. However, it is possible to place comparing files one under another by specifying --ho[rizontal] in command line. Also, it is possible to change the layout from menu.
        <cmd>--config</cmd> - specify alternative path to the YaDT config file.
        <cmd>--norc</cmd> - forcely do not use YaDT config file.
        <cmd>--auto-merge</cmd> - for 3-way merge, try to resolve conflicts automatically, if any.
        <cmd>--translation TRANSLATION</cmd> - defines the way of handling line endig (EOL) of files being compared. Acceptable values are "windows", "unix" and "auto". By default, platform specific value is used, that is when run under Windows - "windows", under Unix-like systems - "unix".
        <cmd>--merge_mode MERGE_MODE</cmd> - for 3-way merge, could be either "normal", which is default or "expert". In "normal" mode, merge is performed as usual, diff by diff. In "expert" mode, YaDT tries to split each diff in a set of smaller ranges to merge which.

        <itl>Example:</itl>
        <cmd>
        yadt OLDFILE YOURFILE MYFILE --merge MYFILE_MERGE --auto-merge
        </cmd>

<ttl>Yadt GUI usage</ttl>

<hdr>Layout</hdr>

        The top row contains YaDT menu. Below that is a toolbar which contains navigation and merge selection tools. The most part of YaDT is occupied with text widget elements. Depending on how many files are being compared, there are two or three text widgets. By default these widgets are splitted vertically. However, it is possible to change vertical layout to horizontal and back by executing menu item "View - Layout".
        If YaDT was called with --merge option or menu item "Merge - Show Merge Window" was called, a merge preview window is shown below text widgets.

        If menu item "View - Show Line Comparison" is set, at the bottom there is two or three lines window, which shows the "current line" from text widgets, one on top of the other. The "current line" is defined by the line that has the blinking insertion cursor, which can be set by merely clicking on any line in the display. This window may be hidden if the menu item "View - Show Line Comparison" is deselected.

<hdr>Diff Map</hdr>

        The diff map is a map of all the diff regions. It is shown on the left of the main window. The map is a miniature of the file's diff regions from top to bottom. Each diff region is rendered as a patch of color, Delete as red, Insert as green and Change as blue. In the case of a 3-way merge, overlap regions are marked in yellow. The height of each patch corresponds to the relative size of the diff region. A thumb lets you interact with the map as if it were a scrollbar.
All diff regions are drawn on the map even if too small to be visible. For large files with small diff regions, this may result in patches overwriting each other.

<hdr>Navigation and merge</hdr>

<bld>Keyboard Navigation</bld>

When a text widget has the focus, you may use the following shortcut keys:
<cmp>
        f        First diff
        c        Center current diff
        l        Last diff
        n        Next diff
        p        Previous diff
        q        Quit yadt
</cmp>
The cursor, Home, End, PageUp and PageDown keys work as expected, adjusting the view in whichever text window has the focus. 

There is a possibility to search for text in any text widget. Button <img>findImage</img> will open an additional search panel at the bottom of the yadt.

<bld>Navigating by differences</bld>

        To navigate between found differences, appropriate buttons are used:

        <img>firstDiffImage</img> - Move to the first difference
        <img>prevDiffImage</img> - Move to the previous difference
        <img>nextDiffImage</img> - Move to the next difference
        <img>lastDiffImage</img> - Move to the last difference

        Also, the same operations are provided in the menu View and popup menu.

        If it is needed to go to the specific difference, it is possible to choose it in the dropdown combo box.

        At anytime it is possible to center the current diff by pressing:

        <img>centerDiffImage</img> - Center current diff

<bld>Navigating by conflicts</bld>

        This operation is available only for comparing three files as we suppose that comparing of two files has no conflicts.

        <img>prevConflImage</img> - Move to the previous conflict
        <img>nextConflImage</img> - Move to the next conflict

<bld>Navigating by unresolved conflicts</bld>

        This operation is available only for comparing three files when merge previrew window exists.
        By default, any conflicts are considered (marked) as unresolved. Before saving file, it is better to mark all conflicts as resolved, however it is possible to save merge file despite of conflicts marked as unresolved.

        To move between unresolved conflicts the following buttons are used:

        <img>prevUnresolvImage</img> - Move to the previous unresolved conflict
        <img>nextUnresolvImage</img> - Move to the next unresolved conflict

        After the decision which parts of compared files should be merged, the conflict should be marked as resolved.
        It is not possible to save merge file until all conflicts are resolved.

        <img>markImage</img> - Mark conflict as resolved

        Any marked as resolved conflict can be unmarked back:

        <img>unmarkImage</img> - Unmark conflict as resolved

        If YaDT was called without --merge option, it is possible to display merge preview by executing menu item "Merge - <img>previewImage</img> Show Merge Window".

<bld>Choosing merge way</bld>

        For defining which parts of compared files will appear in the merge file, the following buttons are used:

        <img>A_Image</img> - Take lines from file A for merging
        <img>B_Image</img> - Take lines from file B for merging

        and for comparing three files one more button:

        <img>C_Image</img> - Take lines from file C for merging

After all conflicts (if any) are resolved and merge file is ready, button <img>saveImage</img> will save the merge file.

}

    set text [ subst \
        -nobackslashes -nocommands $text ]

    ::Yadt::Draw_Help_Wdg help_name -create $text
}

#===============================================================================

proc ::Yadt::Draw_Help_Wdg { help_name action { text "" } } {

    global CVS_REVISION
    variable ::Yadt::WIDGETS
    variable ::Yadt::WDG_OPTIONS

    switch -- $action {
        -show {
            if { [ info exists WIDGETS(window_name) ] && [ winfo exists $WIDGETS(window_name) ]  } {
                set x [ expr { [ winfo rootx $WIDGETS(window_name) ] + 25 } ]
                set y [ expr { [ winfo rooty $WIDGETS(window_name) ] + 25 } ]
                set w [ expr { [ winfo width $WIDGETS(window_name) ] * 3 / 4 } ]
                set h [ expr { [ winfo height $WIDGETS(window_name) ] * 3 / 4 } ]
            } else {
                set x 25 
                set y 25
                set w 500
                set h 500
            }

            wm geometry $WIDGETS($help_name) "=${w}x${h}+${x}+${y}"
            wm resizable $WIDGETS($help_name) 1 1
            wm minsize $WIDGETS($help_name) 100 100
            wm deiconify $WIDGETS($help_name)
        }
        -create {
            toplevel $WIDGETS($help_name)
            wm withdraw $WIDGETS($help_name)
            wm title $WIDGETS($help_name) "$WDG_OPTIONS(yadt_title) $CVS_REVISION Help"
            if { [ info exists WIDGETS(window_name) ] && [ winfo exists $WIDGETS(window_name) ]  } {
                wm transient $WIDGETS($help_name) $WIDGETS(window_name)
            }

            frame $WIDGETS($help_name).controls -bd 1 -relief groove
            pack $WIDGETS($help_name).controls -side bottom -fill x -expand 0

            ::ttk::button $WIDGETS($help_name).controls.close -text Close -width 10 -command "destroy $WIDGETS($help_name)"
            pack $WIDGETS($help_name).controls.close -side bottom -padx 5 -pady 5

            frame $WIDGETS($help_name).main -bd 1 -relief sunken
            pack $WIDGETS($help_name).main \
                -side top \
                -fill both \
                -expand y

            text $WIDGETS($help_name).main.text \
                -wrap word \
                -setgrid 0 \
                -padx 20 \
                -highlightthickness 0 \
                -exportselection 1 \
                -bd 0 \
                -width 50 \
                -height 20 \
                -yscroll [ list $WIDGETS($help_name).main.scroll set ] \
                -background white \
                -foreground black
            scrollbar $WIDGETS($help_name).main.scroll \
                -command [ list $WIDGETS($help_name).main.text yview ] \
                -orient vertical

            pack $WIDGETS($help_name).main.scroll \
                -side right \
                -fill y \
                -expand n

            pack $WIDGETS($help_name).main.text \
                -side left \
                -fill both \
                -expand y

            ::Yadt::Insert_Text $WIDGETS($help_name).main.text $text
            $WIDGETS($help_name).main.text configure -state disabled

            ::Yadt::Draw_Help_Wdg $help_name -show
        }
    }
}

#===============================================================================

proc ::Yadt::Prepare_Help_Tags { widget } {

    global tk_version

    if { $tk_version >= 8.0 } {
        $widget configure -font { Helvetica 10 }

        $widget tag configure bld \
            -font { Helvetica 10 bold }

        $widget tag configure cmp \
            -font { Courier 10 bold }

        $widget tag configure hdr \
            -font { Helvetica 12 bold } \
            -underline 1

        $widget tag configure itl \
            -font { Times 10 italic }

        $widget tag configure btn \
            -font { Courier 9 } \
            -foreground black \
            -background white \
            -relief groove \
            -borderwidth 2

        $widget tag configure cmd \
            -font { Courier 9 } \
            -foreground black \
            -background white

        $widget tag configure ttl \
            -font { Helvetica 12 bold } \
            -foreground blue \
            -justify center

    } else {
        $widget configure \
            -font -*-Helvetica-Medium-R-Normal-*-14-*

        $widget tag configure bld \
            -font -*-Helvetica-Bold-R-Normal-*-14-*

        $widget tag configure cmp \
            -font -*-Courier-Medium-R-Normal-*-14-*

        $widget tag configure hdr \
            -font -*-Helvetica-Bold-R-Normal-*-18-* \
            -underline 1

        $widget tag configure itl \
            -font -*-Times-Medium-I-Normal-*-14-*

        $widget tag configure btn \
            -font -*-Courier-Medium-R-Normal-*-12-* \
            -foreground black \
            -background white \
            -relief groove \
            -borderwidth 2

        $widget tag configure cmd \
            -font -*-Courier-Medium-R-Normal-*-12-* \
            -foreground black \
            -background white

        $widget tag configure ttl \
            -font -*-Helvetica-Bold-R-Normal-*-18-* \
            -foreground blue\
            -justify center
    }
}

#===============================================================================

proc ::Yadt::Insert_Text { widget txt } {

    ::Yadt::Prepare_Help_Tags $widget

    $widget tag configure rev \
        -foreground white \
        -background black

    $widget mark set insert 0.0

    set t $txt

    while { [ regexp -indices {<([^@>]*)>} $t match inds ] == 1 } {
        lassign $inds start end
        set keyword [ string range $t $start $end ]
        set oldend [ $widget index end ]

        if { $keyword != "/img" } {
            $widget insert end [ string range $t 0 [ expr { $start - 2 } ] ]
        }

        ::Yadt::Purge_All_Tags $widget $oldend insert

        if { [ string range $keyword 0 0 ] == "/" } {
            set keyword [ string trimleft $keyword "/" ]
            if { [ info exists tags($keyword) ] == 0 } {
                return -code error "Parse error: end tag <$keyword> without beginning"
            }
            if { $keyword != "img" } {
                $widget tag add $keyword $tags($keyword) insert
            } else {
                $widget image create $tags($keyword) -image [ string range $t 0 [ expr { $start - 2 } ] ]
            }
            unset tags($keyword)
        } else {
            if [ info exists tags($keyword) ] {
                return -code error "Parse error: nesting of begin tag <$keyword>"
            }
            set tags($keyword) [ $widget index insert ]
        }

        set t [ string range $t [ expr { $end + 2 } ] end ]
    }

    set oldend [ $widget index end ]
    $widget insert end $t
    ::Yadt::Purge_All_Tags $widget $oldend insert
}

#===============================================================================

proc ::Yadt::Purge_All_Tags { widget start end } {
    foreach tag [ $widget tag names $start ] {
        $widget tag remove $tag $start $end
    }
}

#===============================================================================


################################################################################
# IMAGES                                                                       #
################################################################################

#===============================================================================

proc ::Yadt::Load_Images {} {

    image create photo firstDiffImage\
        -format gif\
        -data {
R0lGODlhFAAUAOf8AAABAAACAAAUAAIsAAItAQAvAAQ1AAA3AAA6AQI8AAA/AABBAABDAgBKAQNO
AABRAABUAQBeAABlAABmAABnAABoAABpAQBqAgBvAABxAABzAAB0AQN1AgB4AAB6AAB7AAB8AAB9
AAJ+AAeAAgCCAwCEAACFAACHAAKIAAaJAACMAQCNAwCOAACQAACRAAOSAACVAAmUAACXAQCaAAGc
AC2TESiaGjijGj+hJEOjG0WlHT6oIEinIECqIkOsJUeuHEWuJ06tJ0qwH0ewKUmxK1GvKkyyIkS1
I1OxLEa3JT26J0+1JE21LlyxLUe4JlC2Jki5KFuyNmKwNk+3MF6zL1yzN1+0MF20OGG1MVO6NE29
LGC2OkjAJGS4NWK4PF27Nle+OF+8N2a6N1HBMEzEKGe7OFPCMVnAOWi8OWa8QFXENFvCO1DHLGe+
Qmq+Om+8Qmi/Q1fGNlLJLmzAPGrARFDJOHG/RGvBRVTKMGLGN2nEN3PARVXLMWrFOFvRN3DLPl3T
OWvPQHXLTl/UO2jTO23RQ2nUPG3VNHfRRHXRTGrWPWzXPnPVPnHVRm3YP3fUTnDZN27ZQXrVR3TX
SXHaOW/aQnzWSXDbQ3bZS3PcO3jaQ3LcRHvYUnXdPHPdRXjbTH/ZTHbePXTfRnndToHbTnfgP3Xg
R4DcVnjhQHbhSIXbXnniQXfiSoTeUHvjQnnjS3zkQ3rkTHvlTX7mRXzmTorgYo/faY3hXH/oR33o
T4DpSH7pUI/jXoLqSYDqUY7kZoPrSoHrUpPjbYTsS5jidILsU4XtTIPtVZHnaYbuTYTuVofvT5zl
d6DkfoXwV6Hlf5TrbIfxWIryUYjyWaPngInzWpftbqjmiKTogYz0U4r0W4/yYov1XJ3td6bqhIz2
XaTripT1XajshY34XqbsjKDweanthqHxeqjvjq/tjqPzfJj5YZH7Yp/1dpL8Y63xipP9ZLHwkbDx
mKv1hrPykrD0jbTzk7nymrb1lbL3j7D3lbv0nP///////////////yH+EUNyZWF0ZWQgd2l0aCBH
SU1QACH5BAEKAP8ALAAAAAAUABQAQAjvAP/9+0CwoMGDBAUKxMOtWjVlx4LRovXKVRkfBRRq/PfE
W6dNmwwZwpIjwMaT/wZ9y0YnSwCUG+O8myXr1StPW4oEOLmvp8+fQHuiHPSt2jRlwYChYZLgpAoT
UPHY6+WLVqxXW4iEIBgCpRlzoTx5AomFRwCYAm0cgfLEiBAhO2qg3Beqrt27eEN9QDvmDRgHaDcO
4lZN2TI6TBYEHvSNWzVlx4LRQoQGSICTXLhVm7dvWTBftGKJDRVmRwCUdeL1oiXLZpciAQKrMefK
pqdNWHgECAzFW6dNwA1hyREg8JNnzGphOkQIS44AgaNrDAgAOw==
}

#===============================================================================

    image create photo prevDiffImage\
        -format gif\
        -data {
R0lGODlhFAAUAOf8AAABAAACAAAUAAIsAAItAQAvAAQ1AAA3AAA6AQI8AAA/AABBAABDAgBKAQNO
AABRAABUAQBeAABlAABmAABnAABoAABpAQBqAgBvAABxAABzAAB0AQN1AgB4AAB6AAB7AAB8AAB9
AAJ+AAeAAgCCAwCEAACFAACHAAKIAAaJAACMAQCNAwCOAACQAACRAAOSAACVAAmUAACXAQCaAAGc
AC2TESiaGjijGj+hJEOjG0WlHT6oIEinIECqIkOsJUeuHEWuJ06tJ0qwH0ewKUmxK1GvKkyyIkS1
I1OxLEa3JT26J0+1JE21LlyxLUe4JlC2Jki5KFuyNmKwNk+3MF6zL1yzN1+0MF20OGG1MVO6NE29
LGC2OkjAJGS4NWK4PF27Nle+OF+8N2a6N1HBMEzEKGe7OFPCMVnAOWi8OWa8QFXENFvCO1DHLGe+
Qmq+Om+8Qmi/Q1fGNlLJLmzAPGrARFDJOHG/RGvBRVTKMGLGN2nEN3PARVXLMWrFOFvRN3DLPl3T
OWvPQHXLTl/UO2jTO23RQ2nUPG3VNHfRRHXRTGrWPWzXPnPVPnHVRm3YP3fUTnDZN27ZQXrVR3TX
SXHaOW/aQnzWSXDbQ3bZS3PcO3jaQ3LcRHvYUnXdPHPdRXjbTH/ZTHbePXTfRnndToHbTnfgP3Xg
R4DcVnjhQHbhSIXbXnniQXfiSoTeUHvjQnnjS3zkQ3rkTHvlTX7mRXzmTorgYo/faY3hXH/oR33o
T4DpSH7pUI/jXoLqSYDqUY7kZoPrSoHrUpPjbYTsS5jidILsU4XtTIPtVZHnaYbuTYTuVofvT5zl
d6DkfoXwV6Hlf5TrbIfxWIryUYjyWaPngInzWpftbqjmiKTogYz0U4r0W4/yYov1XJ3td6bqhIz2
XaTripT1XajshY34XqbsjKDweanthqHxeqjvjq/tjqPzfJj5YZH7Yp/1dpL8Y63xipP9ZLHwkbDx
mKv1hrPykrD0jbTzk7nymrb1lbL3j7D3lbv0nP///////////////yH5BAEKAP8ALAAAAAAUABQA
QAjdAP8JHEiwoEGBeLhVq6bsWDBatF65KuOjwMF/T7x12rTJkCEsOQJcJDjoWzY6WQKMHBjn3SxZ
r1552lIkwEqCNALcHDjoW7VpyoIBQ8MkgUEVJpLisdfLF61Yr7YQCfHhQ4iDZsyF8uSJIxYeAVba
OALliREhQnbU2Ml25Jg3YBy0HcStmrJldJgsWDnoG7dqyo4Fo4UIDZAABrlwqzZv37JgvmjF4hoq
zI4AB+vE60VLVswuRQKsVGPOVUxPm7DwCLASirdOHDcZwpIjwMonz5jVwnSIEJYcAdreDAgAOw==
}

#===============================================================================

    image create photo nextDiffImage\
        -format gif\
        -data {
R0lGODlhFAAUAOf8AAABAAACAAAUAAIsAAItAQAvAAQ1AAA3AAA6AQI8AAA/AABBAABDAgBKAQNO
AABRAABUAQBeAABlAABmAABnAABoAABpAQBqAgBvAABxAABzAAB0AQN1AgB4AAB6AAB7AAB8AAB9
AAJ+AAeAAgCCAwCEAACFAACHAAKIAAaJAACMAQCNAwCOAACQAACRAAOSAACVAAmUAACXAQCaAAGc
AC2TESiaGjijGj+hJEOjG0WlHT6oIEinIECqIkOsJUeuHEWuJ06tJ0qwH0ewKUmxK1GvKkyyIkS1
I1OxLEa3JT26J0+1JE21LlyxLUe4JlC2Jki5KFuyNmKwNk+3MF6zL1yzN1+0MF20OGG1MVO6NE29
LGC2OkjAJGS4NWK4PF27Nle+OF+8N2a6N1HBMEzEKGe7OFPCMVnAOWi8OWa8QFXENFvCO1DHLGe+
Qmq+Om+8Qmi/Q1fGNlLJLmzAPGrARFDJOHG/RGvBRVTKMGLGN2nEN3PARVXLMWrFOFvRN3DLPl3T
OWvPQHXLTl/UO2jTO23RQ2nUPG3VNHfRRHXRTGrWPWzXPnPVPnHVRm3YP3fUTnDZN27ZQXrVR3TX
SXHaOW/aQnzWSXDbQ3bZS3PcO3jaQ3LcRHvYUnXdPHPdRXjbTH/ZTHbePXTfRnndToHbTnfgP3Xg
R4DcVnjhQHbhSIXbXnniQXfiSoTeUHvjQnnjS3zkQ3rkTHvlTX7mRXzmTorgYo/faY3hXH/oR33o
T4DpSH7pUI/jXoLqSYDqUY7kZoPrSoHrUpPjbYTsS5jidILsU4XtTIPtVZHnaYbuTYTuVofvT5zl
d6DkfoXwV6Hlf5TrbIfxWIryUYjyWaPngInzWpftbqjmiKTogYz0U4r0W4/yYov1XJ3td6bqhIz2
XaTripT1XajshY34XqbsjKDweanthqHxeqjvjq/tjqPzfJj5YZH7Yp/1dpL8Y63xipP9ZLHwkbDx
mKv1hrPykrD0jbTzk7nymrb1lbL3j7D3lbv0nP///////////////yH+EUNyZWF0ZWQgd2l0aCBH
SU1QACH5BAEKAP8ALAAAAAAUABQAQAjcAP8JHEiwoEGCdeL1oiXr1asuRQIcNDjmDRgHEwtC8dZp
k0dDWHIEyDjoG7dqyo4Fo4UIDZAAGZ88Y1YL0yFCWHIEyPhPjTlXDj1twsIjwEEu3KrN27csmC9a
sTx5ChVmR4CJg7hVU7aMDpMFPMPytHEEyhMjQoTsqBH2ibdOHg0ZwpIjAE8z5kJJ9YiFRwCecd7N
kuXQ05YiAQyqMMEYj71evmjFerWFSIgPH0IUxMOtWjVlx4LRovXKVRkfBSYO+lZtmrJgwNAwSSB2
0LdsdLIEEEuQRgDewAUGBAA7
}

#===============================================================================

    image create photo lastDiffImage\
        -format gif\
        -data {
R0lGODlhFAAUAOf8AAABAAACAAAUAAIsAAItAQAvAAQ1AAA3AAA6AQI8AAA/AABBAABDAgBKAQNO
AABRAABUAQBeAABlAABmAABnAABoAABpAQBqAgBvAABxAABzAAB0AQN1AgB4AAB6AAB7AAB8AAB9
AAJ+AAeAAgCCAwCEAACFAACHAAKIAAaJAACMAQCNAwCOAACQAACRAAOSAACVAAmUAACXAQCaAAGc
AC2TESiaGjijGj+hJEOjG0WlHT6oIEinIECqIkOsJUeuHEWuJ06tJ0qwH0ewKUmxK1GvKkyyIkS1
I1OxLEa3JT26J0+1JE21LlyxLUe4JlC2Jki5KFuyNmKwNk+3MF6zL1yzN1+0MF20OGG1MVO6NE29
LGC2OkjAJGS4NWK4PF27Nle+OF+8N2a6N1HBMEzEKGe7OFPCMVnAOWi8OWa8QFXENFvCO1DHLGe+
Qmq+Om+8Qmi/Q1fGNlLJLmzAPGrARFDJOHG/RGvBRVTKMGLGN2nEN3PARVXLMWrFOFvRN3DLPl3T
OWvPQHXLTl/UO2jTO23RQ2nUPG3VNHfRRHXRTGrWPWzXPnPVPnHVRm3YP3fUTnDZN27ZQXrVR3TX
SXHaOW/aQnzWSXDbQ3bZS3PcO3jaQ3LcRHvYUnXdPHPdRXjbTH/ZTHbePXTfRnndToHbTnfgP3Xg
R4DcVnjhQHbhSIXbXnniQXfiSoTeUHvjQnnjS3zkQ3rkTHvlTX7mRXzmTorgYo/faY3hXH/oR33o
T4DpSH7pUI/jXoLqSYDqUY7kZoPrSoHrUpPjbYTsS5jidILsU4XtTIPtVZHnaYbuTYTuVofvT5zl
d6DkfoXwV6Hlf5TrbIfxWIryUYjyWaPngInzWpftbqjmiKTogYz0U4r0W4/yYov1XJ3td6bqhIz2
XaTripT1XajshY34XqbsjKDweanthqHxeqjvjq/tjqPzfJj5YZH7Yp/1dpL8Y63xipP9ZLHwkbDx
mKv1hrPykrD0jbTzk7nymrb1lbL3j7D3lbv0nP///////////////yH+EUNyZWF0ZWQgd2l0aCBH
SU1QACH5BAEKAP8ALAAAAAAUABQAQAjuAP8JHEiwoEGCdeL1oiXr1asuRQIcNDjmDRgHEwtC8dZp
k0dDWHIEyDjoG7dqyo4Fo4UIDZAAGZ88Y1YL0yFCWHIEyPhPjTlXDj1twsIjwEEu3KrN27csmC9a
sTx5ChVmR4CJg7hVU7aMDpMFB/eFGku2rNlQHwzaOALliREhQnbU4PnvibdOHg0ZwpIjAE8z5kJJ
9YiFRwCecd7NkuXQ05YiAQyqMEEZj71evmjFerWFSIgPH0IUxMOtWjVlx4LRovXKVRkfBSYO+lZt
mrJgwNAwSUD336Bv2ehkCTBxn/HjyJMbJwi6ufPnzf8FBAA7
}

#===============================================================================

    image create photo centerDiffImage\
        -format gif\
        -data {
R0lGODlhFAAUAKEDAAAAABQUdv8AAP///yH5BAEKAAMALAAAAAAUABQAQAJgnI+poH1ggHPAgBGy
3nsAAwzcqA2AAUwNYACqAhjAINT2fQ+AAUwNYAAIh8Ti0GBMFg0AnwJgADgTAANgkMlqtwOAATDA
iW0DgAEwRQAMgPQBYAAMtvTsAGAAuA2AvaIAADs=
}

#===============================================================================

    image create photo previewImage\
        -format gif\
        -data {
R0lGODlhFAAUAMIBAAAAABQUdv/2AP///xQUdhQUdhQUdhQUdiH+EUNyZWF0ZWQgd2l0aCBHSU1Q
ACH5BAEKAAQALAAAAAAUABQAQAOMSLrcHiuIMYQVgQUVCPhgqARKoAROugRKwASXFTSBEqhqoAQE
oAQxQUDxIQQUgUUgaAkwAooAThEgBBQBRWDL7Xq5iq/YqwgQQmg0IaAINLyOgCKwCFgolwAjoAgQ
AAQBAgNBAQQfBAEKAQsBTAIBDAEKAQQfCl4EWwsBCgFTCgEEAQQBCgGgDQGpOAkAOw==
}

#===============================================================================

    image create photo findImage\
        -format gif\
        -data {
R0lGODlhFAAUAOeLAAAAAAECBBEREBkZGSgmJSkpKS4pJSwsLC4uLjQwLDQ0NDY0MTU1NTk5Nzs6
Nzw8PEE/PEBAQEJCQkZFQkVFRUdGREhISEpKSktLS1BNSU9PT1BQUFJQTVFRUVNTUlNTVFhWVFdX
V1tbW1xcXF1dXWBgYGFhYWJiYmRkZGZmZmhnaGxoY2ppZmdteG5ubnNzc251f3Z2dnZ2eHl5eW58
kXuAhneClYKCgoeHh4SKqYuLi4+MiHaRupCQkIOSpICTppOTk5STlJWVlZaWlo+XopiYmJSYrJCZ
sZmZmZubm5ubnIGf0X2i156enp+fn6CgoKKiooOo3KWlpZOtzaqqqqqqrYWw4Iaw5aysrK2sq62t
ra+vr5G02bGxsbu7u6W+5L+/v8DAwJfI98HBwcLCwpbK/qXH8cPDw8TExLvF35nM/sXFxZvN/sbG
xsnIxp/P/snJycrKyp7U/6jU/8jO4K3Z/7Xa/7fa/8Ta+NnZ2b3f/8ve98Xh/97e3cfi/8nj/8rj
/uDg4M/m/urq5+nz/Ov1/+z1/vj49/j4+Pn5+fv7+4O/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/
CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/
CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/
CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/
CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/
CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/
CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CSH+EUNyZWF0ZWQgd2l0aCBH
SU1QACH5BAEKAP8ALAAAAAAUABQAAAjXAP8JHEiwoMGDCBMqXMhQYQcNFBae2PACh5AnTpo4EfIA
oQgSccJ0oSIFipMmSJKgGFBQAgUdZ+CM0XLjRIcHF4rkIUOioAJFM9a40ILGAoYYHcAEQnQoiIqB
BUZ4KQEmUKJBMlh86NGmjxE6eGAMRLDBxJY1bnKk+VJBCZYqewwJqmNg4IEQQLIcIVTIz48IQ4jo
4XNHToKCKXaYAfTHDhcCDGqweSNmigCDK8rMmaPGh0AOPJgsAXGwAY0rVqJAGOjAwwIACCe0sJEB
QEOCAW7r3s0bYUAAOw==
}

#===============================================================================

    image create photo findNextImage\
        -format gif\
        -data {
R0lGODlhFAAUAOe2AAAAAA0NDBUVFR0bGgAxAiYmJignJTArJzIuKi4vLzMzMjMzMzo3NDo6OkA/
PUJAPEFBQUNDQ0ZGRkdHR0lIRkpIRkpKSk1MSU5MSQBuAE9PT1BQUFBQUVFRUQByAABzAFNTUwV0
A1VVVQZ1Aw50CFdXVwB6AFlZWQp5BlpaWgl7BV9fX2NjY2djXmFkagCNAGdlYmlmaWdnZyiGIBWO
D3FpcGxscBeSDnR0dGt2hjKVGHZ3fHl5eXV7hx2hE3t7exyiEnx8fHl9gnR+iyajGSWlF0OgLkKi
LYOGg3OIqm6UckanLo2Kh4CNnYyOjJSMlJCQkJKSkpKSl3mefHmefYyTs4yVoJOVk5WVloOZrpKY
r2SwZI+btnyf05ycnIWgy56enp+fn6Ojo6SkpIao2aekp4Ks3ZOqx6enq2rFOIOt5KqqqKqqqq2t
rXHLPpG02HTMQnbNRHrNSbKysnnORW3UOX7PTnPXQbe3t3bcQ3feRJTE9ZPG+r+/v3rgRsHBwXvj
SMPCwJfK/MPDw37kS8TExJnM/sXFxX7nS5zN/YHnTqfL9YDoTbDM88nJyZzR/4XsUqXT/4buUonv
Vs/Pz8bR563a/7TY/5XxZrTZ/9bW1qnthLnc/9Xa6Nvb2cHf/tzb2MXg/5r9YrDzicfh/t3e3d7e
3sbi/57+Zsvi/aD/Z87j+7b3j87l/rn5lfHw7vTv9Ofz/+jz/vn5+f77/v7+/oO/CYO/CYO/CYO/
CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/
CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/
CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/
CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CSH+EUNyZWF0ZWQgd2l0aCBH
SU1QACH5BAEKAP8ALAAAAAAUABQAAAj+AP8JHEiwoMGDBl8gXCiQSBGGBD1k+GCChiofEAUu2TSK
lStMqIBkPHJHDyBGkCaJugHRSJ08fggpkmQHBUIJIGroSOMGThxEckIQZLHhRxQvYsKUmUJFCQEV
dEYQPCGDUp85bMaIAXPFCZIYM0gQhCAhyB9Hh8TgSNGhgQU2sLY8EUBwQa0fhVj00VRiAg8ReErR
eiXFxsACG+acKGRqFqgdMDhEKeRJS6dUQwhqYNFmUKAqlRpRwMIGzSpZrSwdIAgCyhousmKFyhIB
ihVOny49QlBwBZNFpE5lejMggRBDifacCWCwBZ9IkQQ1EXghSZcvGBDmUGOGDIOBCioOGACA0IGL
Hg8AZFw/MCAAOw==
}

#===============================================================================

    image create photo findPreviousImage\
        -format gif\
        -data {
R0lGODlhFAAUAOe4AAAAAA0NDB0bGoEAACAgICYmJq0CALQAACgnJcEDADArJzIuKi4vL74MADMz
MjMzMzo3NDo6Os8XAOQRAEA/PdcZAEJAPEFBQfAWAENDQ0REREZGRkdHR8knCElIRkpIRkpKSpc3
Nk1MSU5MSfkkAE9PT1BQUFBQUdsvCVFRUdwxAVNTU1VVVVdXV1lZWVpaWl9fX2NjY2djXmFkamVl
ZWdlYuZIEOFMCWZoaGlpabJXUmxscGNxdGxwcOVXEv9VDP5WCv1WEWt2hv9WEHV1dehdFf9XEXZ2
dnZ3fOdgFnl5eehiF/9cGv5dFPhfF3V7h8pmXnt7e/5gEXx8fHl9gnR+i/5iF/9iFv5nGf9nGf9p
G/5rGv9rG3OIqv9uHP9wHI2Kh/90HoCNnY2Njf94I5CQkMyDepKSkpKSl8aFgceFf4yTs4yVoJWV
loOZrv+CN5iYmJKYr52YmI+btsePjHyf052dnYWgy6GdnaSgn4ao2YKs3f+UX5Oqx6enq4Ot5Kqq
qKqqqq2trauwsZG02P+gaqe0tbKysrC4uLe3t/+qZ/+ra/+scv+veZTE9ZPG+sHBwcPCwJfK/MPD
w8TEw8TExJnM/sTFxZzN/afL9bDM85zR/6XT/8nOzsrR0cbR563a/7TY/7TZ/9bW1rnc/9jY2NXa
6Nvb2cHf/tzb2MXg/8fh/t7e3sbi/8vi/c7j+87l/uzs7PDw7ufz/+jz/vf39/n5+f7+/oO/CYO/
CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/
CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/
CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/
CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CSH+EUNyZWF0ZWQgd2l0aCBH
SU1QACH5BAEKAP8ALAAAAAAUABQAAAj+AP8JHEiwoEGCFQ4qHCjBxkKFCRqpaDABA4mHAg8UkvKG
0SJFZDAa4APECpYtX8JowTiASZAmV7Jw8eIEo8AhRnwUSbLkBg+MPUL86EAnjRozg+xoUOgihycd
KBDlwSMHTpkxNAgUvLBhCqROUAwReZEiAohAsUodKfjgVpRLOCiNasFBCYtErGrJQrNjYAETh1xU
YmUrFZIaJ85UOhXHlKsqBEvEEDQp0ppPmjy0CeTnFS1YoBQQXFEG0Bxas1S5yVCGDSlUoTYtKAgD
TKZVrUQREsCAiiVMjvoEMCjjESdOksQIFNGlzp0RCoX82aMHwkAHHxAAUEhhxhMLAGwEih8YEAA7
}

#===============================================================================

    image create photo saveImage\
        -format gif\
        -data {
R0lGODlhFAAUAOe3AAdIAAtLAx9TFA5nDBplChBoDRJpDhNqEBhrBRVrERpsBiBsGxZ0EEliRCNz
EFthWCyJE2lvZQmeAA2fAHF3bnJ4bxOhABaiAhmjBBukBnl/dR+mCyGnDTahFyOoEBGtFH2DeUub
KSWqEVOYPjqkHE2dKyerEyyoKIGHfSmsFVObRyqtF1ScSDqnKCyuGDuoKTSrIjGvCFaeSjypKzas
IzOwCjqtGTetJDSxDVigTDiuJTayDzqvJ1SmOzezET6wHTuwKD+xHjm0Ez2xKXmYcF+kSUmvHjq1
FUGyID6yKnebbD+zK1+mUjy3Fz24GGemU2OoTT65GmKpVUu0LWeoW0C6HE21LkG7HV2vQ0i5KFuw
S16wREO8H1yxTES9IGiuUoOiekW+IZKdjEe/I2ayTlC9In6ocUjAJFG+I0nBJlK/JVTAJlXCJ4es
fFbDKVfEKoSxf1rGLGrARI+vhmXJO5G2hWbLPGjMPZG5jmnNPpe4jmrOP66wra60qqS8obK4rqe+
o7e+s7nAtb2/vLvCt77EucLEwcDGvL3ItsHHvcTGw8TLwL/NwcDOwsPOvMjPxM3Py8vRxsXTxs7Q
zMzSx8bUx8/Rzs3TydDSz9HT0NLU0dPV0tXX1NbY1dja1tnb19vd2tze293f3N7g3d/h3uDi3+Hk
4OTm4+Xn5Obo5efp5ujq5+nr6Ors6evu6u3v6+/x7vHz8PL08fP18vf59vj69/n7+P//////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////yH+EUNyZWF0ZWQgd2l0aCBH
SU1QACH5BAEKAP8ALAAAAAAUABQAQAj+AP/9KyPHEaWDjxYVIhToTx8yRgQK9OBhBiJJkSpJetSo
UaJCgrZw4VJAIJIjR4gUGVnHFS1Wk0qsWUMnToJ/ZS5MaGGKlqpJQIFuIuVJyxEuA/6t2VGjRg8p
UpjkkMGCxQgSP36USWNA4IQJJ1TZWhV0EqRNpj51gdCBwT81Hi7MCPXKVNlJmj5t0jJygEAbFFfY
aLpjhxCUR0aOGVPg35ojhed8QWnGECdVrkKMSUNnzQGJ/xQ0oKABBQoQFSI8EECAwAIAEldMOJGK
Vq1ZsmCxSmWKlKcuSH44+Ffm6wlVtmzJigWLVSpTpDxpQXIEgcALE2aYigVLlapUpkaLiRrFScvI
Af/UUJzhSZWpUaNEffrkyVMmLCML/FtD0QON/zzwAMQQSSxhhRVZcDFGAQLVYIMNTdVQmBCIjcTF
GGcY8M8ahe2gByB4tCEGH4p4YkoIi9GxhgH/lIEYGFCgBIcnrdBiSglprEFHHAdI9AMXRCjxBBV+
2LIKJ4OEsEYce5QRAGhQRhllQAA7
}

#===============================================================================

    image create photo saveExitImage\
        -format gif\
        -data {
R0lGODlhFAAUAOf/AAA3fAA4fQA5fgA3nwI4oBY3fgA7oQA9owBAphI/hRQ9nx5ERgNDox9FRgtF
pQxUIABKqQBKsRhLbRRHqABNrBVJnAROrQxPsEJJWxVSrANZshpUrhNlGwdcoQBtEhxVsAtbtAJu
EwByACJYsxZqJxJdtgBhyBVdtwBjuwBiyUpZUxZfshheuARjylVWXwRlvgBlyhpfuQBmyxxguglk
yxthtFhZYgd5FB9itg55CA1nwAB8FzVepw5ouhF0QTZfqC1iqiNkuFtcZQB/GhFrsC5jqyVluRVq
vC9krCZmuhdrvV5fZxpqxChnuwVxyipovDRnrxxtwGJiax9uwSFvwiNvwyVwxACPBxZ1zidxxWdn
cClyxhh3ySpzxxt4ywCVAB15zCp3vSx4vi93xSN7zgWdADZ8ywmeACmAzU55sTh9zCuBzkx7qw2f
AFN6pi2CzxCgADt/zkh+tFV8qEl/tU9+r0qAtlh/qxmjBEOI0F6FshitADGhQkiM1DySzHyIlWaM
uW+LrUOge4CMmSi0EDSxDWqQvTayD06flEOsRjK0K1WhkHyUsUWvSDy3F4uTmkG5BoaVqIqVoka0
PUyyRHGbwYaZsVqsfHSexUq4QVS1VlG+I0nBJoyft2O3UlXCJ5ahr1q/UJykrGi9V4yovp2lrZqm
s2LAWVvHLqKrs2nNPnDHZ6iwuG7QObKwtKy0vHnTRrK3urC4wJDIhn/VWLa7vrC8yoXRf7S9xbjA
yJDTgrvAwrnByZHUg7rCyr7DxafQpMHGycPIy8TJzMfJxsXKzcbMzsrMycbO1tDN0c/RztDSz9HT
0LHioNLU0bLjodPV0tXX1NbY1d3Y1t7Z2L3oruDa2drc2eHb2tvd2tne4dze293f3ODe4tvg497g
3d/h3ubh3+Hk4Ojj4uHm6eTm4+Xn5OPo6+zm5efp5tvu2eXq7enr6Obs7vDr6eXv6ufw6/Dt8u3v
6/Xv7u/x7vDy7/Hz8PL08fjz8fz29fb49Pj69/n7+P78//7//P///yH+EUNyZWF0ZWQgd2l0aCBH
SU1QACH5BAEKAP8ALAAAAAAUABQAQAj+AP8J/GfLl69cuGS9YpWqlKiBAmlksACF17BhxooJC/Zr
V61YdrysCSDwiBUnf9xkcUIq3iw8odQ1a/NlyIN/NBggAHJOHztix4Ieg/ZtGp0tZEjSmIEjRhpD
gPTMYbOIVitUmw6tOkUC5wECPNrxq8cMGjRmy6SBw1anA5EEOCFMKOJNnrhlzpgxUwYtWzQ6XuIo
HQECxIkTLFAESaJEDCJNmRIJ8qM0yRMdoPRMmRIp2aRRwA716veszQ6IBTC4sCFEipYlKjiIuOHh
QYOBEcCu28cP37157tCFC7dNjpIecGkoOBCWHz969eSlEyduLZ0pY5Q6cACEnL166dKXmRP3jVtR
Ol3iAPgHwwKFItrYpTPPbdu0a9aihURDEsaGDRqsUAMOQfRwRBRVWBFHH3mQMRJOhyHGwgwv6PBE
GJfQAssmjuzBhwTsGWHEDKaAwkggj7jiiSqQcELILfnokgNOUUzBhCR3VFFFJ91Qkok48PRTTRtX
hCBQBUlgMYgllWCCjD/wJFKGIkQO4cNtEGWpZZYBAQA7
}

#===============================================================================

    image create photo A_Image\
        -format gif\
        -data {
R0lGODlhFAAUAKECAB8Ztf///4O/CYO/CSH5BAEKAAIALAAAAAAUABQAAAJHlI+py40Bg0uggjCP
rSGbGlRQZgVWkFmCFWRVYFSQYwWGFThWZAVBswkCAgxhMMCwKCo+hSWgsAQUloDCElBYFhaP9wtW
FAAAOw==
}

#===============================================================================

    image create photo B_Image\
        -format gif\
        -data {
R0lGODlhFAAUAKECAB8Ztf///4O/CYO/CSH5BAEKAAIALAAAAAAUABQAAAJElI+pyx0PYwO02ses
pm/VgFjBUgVJFSxVkFRMFT1UwGzas9jao1RBYgkoKgFFJaCoBBSVgKISe1QWOgvDZmlot9yutgAA
Ow==
}
#===============================================================================

    image create photo C_Image\
        -format gif\
        -data {
R0lGODlhFAAUAKECAB8Ztf///4O/CYO/CSH5BAEKAAIALAAAAAAUABMAAAI8lI+py30Bozug2tis
tnBppAWLpViLFUyJFaiIFbiHFciGFTDBYkEKEFFYIAjNQhMJaBqbjaqpiEqn1GgBADs=
}

#===============================================================================

    image create photo closeImage\
        -format gif\
        -data {
R0lGODlhFAAUAOfhAEUBAUkAA0sAAEwAAE4AAU8BAlACAFACA1EDAFIEAFMFAFsDAFQGAV0FAFcI
AF4HAowAAJ8AAKEAAqQBAK0AAa4AAqUEAJsHALADAKYGALEGAKcJALwFArIJAL0IAL0IA7MMALUO
AMAOALYRALcTAMERAMsOAsITAMwRA8QVAM4TAMUXAMUXCc8VAL0cDtAYANoWA78eBdsYANMcAMEh
CN0aANQdAMwiD8UlC9chAdgjAtkkBOMjAMorEOUlAO8kAN0pB/AmAM8wFOkqBNEzHdsyEt81C942
FvAzDeE4GOo3FOI5Gfw0Cf02C/Y5Ev83DN4/IOg+FPo9CehAJdpELfI/GvNAEvs+F91GLu1DIf9C
APhECf9DAvZDHutJGf9EEvhFIPVKCf5KAuRNNO5NK/1KJOdPNtZXN/9SBf5SFO5VLu1VOuhYOdZd
QOxZJ/JYMP9VKPFYN/NZOPRaOf5aIO5dRP9cK/FfQPtfMO1jP/5hI/dlSvFnSf5oLf9pJ/1tHfNw
VP9wOPVxT/92I/l3MdF9cfd3PvR3V/95Pfd5WfeBY/mBXv+EOviDavuHR+eJc9uNfviHZv2GZ/mI
Z/6NPfqLb/iPceqTgOWVhvqRcv6VT/qXdvuYd/+cU+ifjdejo/qef/ufgPOhi/qlg/umhP6ohvKq
nfaqkvOrnvmrjfusiPGvoN+4s+i+tP2/junGufbDtOjHwPTIt97OyfXJuNbQz9nT0v3RwP/Swf3S
x/DWzejY0+Da2drc2f/Uydvd2t3f3N7g3d/h3vPc2P7azdzi5ODi3+Hk4OPl4eTm4+Xn5OPo6+bo
5efp5ujq5+nr6PHs6u3v6+7w7e/x7vHz8PL08fr18/b49P339vf59vX6/fj69/n7+Pr8+fv9+vz/
+/7//IO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/
CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CYO/CSH+EUNyZWF0ZWQgd2l0aCBH
SU1QACH5BAEKAP8ALAAAAAAUABQAAAj+AP8JHEiwoEE8pVSNCsUp06RFiQTtubPGDBUcA0u5osSI
kBs/euik+XLFCZIhQG4MTNVp0J82n7ygEcOlCapGQXjISPFA4ChNf87YEsbKChcppq5Zk8QDRokG
AkE5alML2DFmrbqsusbNG7hKO0osELjJUKFewY41izbs2jZv4MDhMvLBgUBLiMJAOoasWTRq17jF
JRblBQkGAiMFQrMFEzNn0qhl8wbOVxYdL0YoEKiojxguUmI9m1Ytmzdsb2TMQNFBgcBDdrg08bTM
mbRq27yByzXlxYoOBQQCgtPk0jFkzqJRy9Ytri8oJSoQEMinzKNfwZA1iwbtGre44HCLEdlAQGAd
MHFmBTvGTNccWNu6xRUVwwIBgWyqBInDq9guNTIsQYs23ZzCAggWECDQGErwwEMer5ABwwwvFCGL
KCyM0IEEBAhExREyyKBDEjO8gMIKJwhBwwgdbHBBAAK50EMKJ5QgwgcjgNBBBRtsYIEEEkBQkAIK
JHBAAQQQIEAATDIJgEFQRilQQAA7
}

#===============================================================================

    image create photo refreshImage\
        -format gif\
        -data {
R0lGODlhFAAUAOeXAAEZPQIdRAEeUAceSAIkVQAoYgA3Yw82bgo3dgk6ZQM8hwg/gQRFegtEiQ9G
egZKhQxKhQVMqw9OlwBUlB9RlQ9VoiZTkAlcww9guw5itxlgrhNishZntxZotRdpvQ1vwxxtvyZr
vxJw1BtwyCZxtyZxxCFyy0FsqyNzwwV71ipyyR12ySZ2wyN5x0Z0tw2B30d1tQ6E5hyF7DWCyyGF
6y2G4SKM8z6JziaQ8CGR+SuP8UaK2DaP5CeT+SyW/C6X+1yQzzmZ4Dib4Tqb4TSa/Tmb+jid/jyd
+Tyf/0Gf+Vab4z6g/0Sf+Eeg90ih9kKi/0mh9l2d5UWj/E2k+E6k+Eml/1qj6FCl+FWl70yn/1in
5VCp/1Gp/1+n72Wn6Viq+WOp61es/3Gn5GSs71yu/2ut8GWw92Kx/2+y62i0/3Gz8Wy1/XC19Xm3
8HK5/nK5/3649Xy69Hi7/Hy8+n6+/4TA+ILB/4PB/YXB+4jB+YXC/4nD/IrF/4vF/ovF/5DH/5HI
/5LI/5LJ/pPJ/5XK/5rM/5zN+5vN/53O/57P/5/P/6DQ/6PR/6bS/6jT/6nU/6vU/6vV/6rW/6/X
/7nc/r7f/cXi////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////yH+EUNyZWF0ZWQgd2l0aCBH
SU1QACH5BAEKAP8ALAAAAAAUABQAQAjhAP8JHEiwoMF/Q4QYNOElTyFGjxwBOQiiSZUnSHTQkCEi
wEGBEwp2mEImTRcFO+RQENhmESJCfqx8nPkvRo4eP4wsqQLFA82PSvj8GRQIjgCBWixBWjTojhkS
AwsgsHACxoCBc8BAGPPmzJUNPz8ukNCAQFiBL3AckeKER4afKT4wMPBgRZIsXKhoEKjiLIo1dPRE
wTPnwNkQgw4pSiRmYJBKlAzVYYOlxb8SZfYskjQpkouBaCY1QgToRoKzcQSp6WPHDYuzMxz84/Al
zBYmIwZeiPCzQo0iRHzYwADg7NmAADs=
}

#===============================================================================

    image create photo aboutImage\
        -format gif\
        -data {
R0lGODlhFAAUAOehAAE9pApoygtoygBt0wFt0wB64QF74QCI7gCI7zyAzj2Bzg6M8GGDwkmJ0WGE
w4KCjoyMnI6OoI+Po5CQo5KSpXSg2Iag1J6etomi1p+ft6GhuqOjuqWlu6WlvKiowKiowaioxKmp
xIyw36urx6ysw368/LOz1IK+/ITA/J275YTB/Lm52Ki+5KLF9sHB2sHB3LTH6K7J+6bM9sXF5MbG
5sbG8rXM9MjI5cjI6rnN8snJ68nJ+svL6crK+sLO68zM587O6brT9MPQ/s3N/87O9c/P7s/P8M/P
8c7O/7jV+8TT88jT67/V8tHR8NDQ/tDQ/9LS6tHR/9LS/tLS/9PT9dTU8NTU8tPT/9TU/9XV/tXV
/9bW+9bW/cza9NbW/8/a9NfX/9jY/9nZ/9ra9dra/9De/tvb/Nvb/tvb/9nc/tzc99zc/93d/97e
897e/9/f/N/f/+Dg/+Hh++Hh/+Li9eLi9+Li/+Pj/+Tk/OTk/+Xl/eXl/+Hn+ebm/ebm/+fn/+jo
++jo/+np+Orq/+vr/+vt/uzt/e3t++3t/+7u++7u/O7u/+/v/O/v/e/v//Dw//Hx//Ly/vLy//Py
//Pz/fPz//Tz/vT0//b3/ff3/ff3//j4//r6//v6//v7//z8//39////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////yH+EUNyZWF0ZWQgd2l0aCBH
SU1QACH5BAEKAP8ALAAAAAAUABQAQAj+AP8JHEiwoEFFnjRVkiRpEpMAAnLcgYPGyxMpMwwalGCl
yAaNkUCB+uSJkwUAADAg+nOHDRsjBV/QIRSojAoUJ0oImTLkzQeDWfps4uSpUyZMmyANwnNjBMFG
Ij9pqsQnhYgKXwLlgUNGCxgcAnUwggTp0aNCMgoYaJFGDJYoZ2hoHMjBQwcQTnoQcTHX4IMLEPoO
3CIH0CFGiQS1AbJCIxdJn0B98rTEAQMfiwLlmWOFxEA9n0B98rTpkiUYLAwN2jNnjRc3JgRSAvVp
UyVJXRooSKDEjx02Ya5MOSKwTiWGZB8FGUDARpw1YKYMMRNi4I9GjxwhSrIAwYEFMbQmTMnTRIJG
F1DUxHFDxssUJDvGUBBMcAKVGlUi0CeogUeG/QD+ExAAOw==
}

#===============================================================================

    image create photo stopImage\
        -format gif\
        -data {
R0lGODlhFAAUAOftAJ8AAKEAAqIAAKwAAa4AAqUEALIJAL0IALMMALYRAMAOBQA8oswQAMQVAABC
ohQ9nwdEpAtFpQBJrwBKqQBKsBFGpwBLqgBNrN8eAAROrQhOr+AgCQxPsB1LrBNRshVSrABYtxhT
tARZuBpUrgdaswBcwQBdwiBXshBbuw9ctQBgvwBhuRJdtgBiuiBcnBVdt8s2ItwzEwBkvMw3I900
HQRlvhpfuR9huzFfmxxkqh9itg1nwBFowSNjviNkuBJqthRpwiVluSRmtCZmuhdqwxpqxChnuyho
thpsvxptuSpovClptxxtwCxpvitquC1rudVHMuREJCFvwg90xiNvwzZtqRJ1xyVwxNdKMxV2yDdw
pTlvqylyxhh3yfJIJf5KAkRxpyt2wy12xDd0vCx4vudPL/9LEi93xcJXUjl1vTB4xjp2vi96wSN9
yTJ5xyV+ykR4tEZ6tz59uUZ8svZVODmByO5cKexbPEqAtvVbOu5dPj6Ey+xgMM1mWDWJ0NdnVlCF
vGCHtN9sSvhmRWGItdduX1yKvN5wS2SKt2WLuGaMufFuTJeGmtV6aoWRnvV4WOx6Z4qVovx/LtmD
cZKXmZabnZecnvOGcNeOd4+iupOjtZijsfGQdZykrJemudmYg56mrqGmqZinupmou5qpvNubjJeq
w/OYee2af6mqtJqtxq2vrJ2xyZ6yyqyxs5+zy6m0wqK1zqO2z7zBw8HDv+LBu8nHy8fJxsnO0OrJ
wuPMydDSz87T1tHT0NLU0dPV0uLSzdTW09XX1OPUztLY2tbY1d3Y1vvRxtja1tnb19rc2djd4Nvd
2tze293f3N7g3d/h3uDi393j5eHk4Pnf1uPl4frg1+Tm4+Ln6uXn5OXq7e7o5+jq5+nr6Obs7v/o
5fvr5vzs5+7w7e/x7vfx8PL08fP18vf59vj69/n7+P/6+fr8+fv9+v//////////////////////
/////////////////////////////////////////////////////yH+EUNyZWF0ZWQgd2l0aCBH
SU1QACH5BAEKAP8ALAAAAAAUABQAQAj+AP8JHEiwoEEQHj6Ymlat4TRozpIF86XpTJsmAotQoQIm
0pQscn6Ju5QHmDZy7L5hKfCvgwMIsc6lmwbtWbNkyKA5GzVFTBCBN2y00HHkyBInT9aUknSIz5dB
dDA0+EdhwQNZ6NYlS4ZMWLBf0J6R+uFih0APEyywEjcO2rNnzZIhc5ZMlBg1QwSiOEEixYsXNmoE
GULljJs3dfb4ESOQx5AhW2CNSTNn1a1Tdmp1K7fuWAwEA2vgsFSpUypctv5siEKDAZQZBAL8K0GB
Qits3rxpwyZtGTFeuDIVKQJCIIUHDmShW9ewGjRnyaY9I5UkxxCBGSBUeFXOXDJkyISkBfv1rJko
LmeGCAxxIYMqbtx++fLVa9euZMg8dXEzRKCIESPAEQghhiCSSCKKHKgIIGq80YRAKvz1wgot1BDE
EFQw8gkmkzRSSB9oCNSDDzVUMYsroFBCSSioCGIMMI+AE04ZB/wDBBJMgLEJFVfEQUsznJixyDbm
qKMHAwT8UwITVmjhCBls4FHNOZB4oUsud1hDDQwBGGSQAgkYMEABBQTwT0AAOw==
}

#===============================================================================

    image create photo copyImage\
        -format gif\
        -data {
R0lGODlhFAAUAOfOADoyV1dKeFhLeVtJkVlMelxRql5UiGFUg19ViWVUimRXhmVYh2ZZiGNXsmda
iWhbimVZtHZdo1pphmdyin5spGJ2mYFsq3ptt297n3R8qHKBn3CDp3SDoXGEqHaFo4F90neGpHmI
poKGrXqJp46Du32Mq3+OrYCProGQr4OPtH6RtYSQtn+St4WRt5mKyY2M24aSuIuSs4eTuZyNzKKO
yZ2RvZ6PzqOPyqSQy6WRzKCUzaeTzo6dvaaWvZKdt6aWyqeXvqiYv6mZwJWguqaaxqqawaqaznir
0aqeynms0qmg0pmou6qix6ui1Juqvayj1q6l2LGl0rOm05evzZiwzq+qyLWo1Zmxz6+q1Zuy0LGt
y7Gs15yz0amxxoa537Kt2Z200qqyx6S0x7Ou2reu1KK23KO33Z253bqx17uy2Ki42Ka536q52cC0
1au62r212ri328G11ru31qy726283K690bq7xa693b652MG50q++37+62bO+2bS/2sG827XA27bB
3LnE0rvD2KHK5bzE2cHF1b/G3MDH3aXO6bfK5L7K2LjM5cjI38DM2rnN5sfL28HN27rO57vP6LzQ
6dLO4MbS4MPT59PP4cTU6NTQ4sfW6snY7MrZ7dPX583Z587a6Mvb7s/b6szc8Nba6tDd69jc7NLe
7Nnd7dPf7dre7tTg7t3e6ODe4tXh797f6eHf49bi8N/g6tni6uLg5OPh5eLi7eXi5t/k5uPj7ubj
6ODl6OPl4eTl7+Xu9+zs9+jw+erz+/Px9ez1/fD2+PL3+fP4+/T5/PX6/fb7/vz6/vf9//j+//z/
+/7//P//////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////yH+EUNyZWF0ZWQgd2l0aCBH
SU1QACH5BAEKAP8ALAAAAAAUABQAQAj+AP8JFBiBSJEiQoIA6UFh4EAUyng9YnSIECA+c9hMQgXj
Bw4rexz849DLE6A/ffTQcbPmTKJNGAQQEBAAwD8VyJrpXIbsmKIjTmzZqlKDxIUBAkcQc3XIkMU+
dzJKMpXixownaRQI7NBhw4YMXcLYuSV0VpUPDRyyUKZzp7JClQYdEYHEyI4vfh78M3HM16pTpUZ1
2qQJEypTMHTYkAJnwT8QwEoREgQIakYzjkDJiPJkzBgD/yqAGQ2Gi+ksqKlMkeCwtUALr3TpEvqK
FZMCrVUQM8a7GLFhYpbssmV2ywsIA9e2baYMWSNEXnjk2ROHTBs5CW4qW9Y8mbFisiBxBaozxEcm
Spf8iDyhLBiuWrFSBea0CRYqGR6t4GHwr4SxWE09dQcdGlGVAw1RvKFVCMKs0hRlfNCRUSSgpDCD
C0qggcA/HvzyCSCVRcWGGWUswkkMWEgBRRMH/KNBK6qYIqMpoYDCyY2WTODajjy2FhAAOw==
}

#===============================================================================

    image create photo A_ch_Image\
        -format gif\
        -data {
R0lGODlhFAAUAKUtAB4ZtB8ZtR4fqx4gqQtZBgxZBgxaBgxbBh9SaiVPehmLDBiNCx+MHBqQDR2S
Dh6VDiGVESKVEiWbEiScES+dIS6hHD6ZSS+jGj+aSSmoEyapEjKlITKuGDGvGT+pODqtKDivKDex
GzywLD2yKEKwMj6yKz+zKkC1I0ezNk26MmC9VLLcr/3+/f//////////////////////////////
/////////////////////////////////////////////yH+EUNyZWF0ZWQgd2l0aCBHSU1QACH5
BAEKAD8ALAAAAAAUABQAQAZywJ9wSCwai4FAS5hsLY/JAFHC6XhAjMJxGG1uud1wgPVDmSJfp/NL
jLbc7J/bOYd6f5/U5TdIWEoOcUMLCoKGX11Pgk1NiohJcnePSkySdmJ3JBttkEUAAisqIxAHYJQ/
FSchEwgYIhQGhg8ZGg0Eh2xBADs=
}

#===============================================================================

    image create photo B_ch_Image\
        -format gif\
        -data {
R0lGODlhFAAUAKUyAB4Zsx8ZtR4crx4fqx0tlR9BgSBGfgtZBgxZBgxaBgxbBh9SaiVPeiJuSiJ0
QSl0TRmLDBiNCxqQDR2SDh6VDh+VESGVESKVEiCWET6ZST+aSSmoEyapEjKlIUGdSTGoHjCrHDar
IT+pODivKDuwKjywLD+wJz6yKUKwMj+zKlG7NmC9UWy+XWzBXq/bq8nix+/37vX69f//////////
/////////////////////////////////////////////yH+EUNyZWF0ZWQgd2l0aCBHSU1QACH5
BAEKAD8ALAAAAAAUABQAQAZ3wJ9wSCwah4GkbMlUHn/JKKHxAYlGFcQxyuUut85iAFBYpS5Fppr5
hIaRb2J3HpDFjNFlS8V6wRgZJBNtRREQhIhtdHkyT3lyj3hxbgGOi0qNknViSQIuKB2Qm0UDBh4n
FgqiSQ8mIQ4LGiUYCYk/FBscEge2iEEAOw==
}

#===============================================================================

    image create photo C_ch_Image\
        -format gif\
        -data {
R0lGODlhFAAUAKUwAB4ZtB8ZtR4fqx4gqR0tlRwxjiBGfgtZBgxZBgxaBgxbBh9SaiVPeiJuSiJ0
QSl0TRmLDBiNCxqQDR2SDh6VDh+VESGVESKVEiCWET6ZST+aSSmoEyapEjKlIUGdSTGoHjCrHDar
ITmxJz+wJzyyKT2yKEKwMj2zKj+zKkKzMFG7NmC9UWy+XWzBXrbdtP3+/f//////////////////
/////////////////////////////////////////////yH+EUNyZWF0ZWQgd2l0aCBHSU1QACH5
BAEKAD8ALAAAAAAUABMAQAZuwJ9wSCwahYEk7MgsJgmNDyglqiCYyaw2AFs6lV5i4OVaoS7Mrjp8
zBrdb2UTm4W1VKzCgJEhTeZEERCAhHNbXF10SWJ1cVyFQ42QP5JGXiYdjIhEAAIGHiUWCl9JDyMh
DgsaJxgJhRQbHBIHREEAOw==
}

#===============================================================================

    image create photo prevConflImage\
        -format gif\
        -data {
R0lGODlhFAAUAOegAEsKAEkLAE4KAFsHAFUJAFkMAVkOAV0PAZIIAZcKAYwPBJoMAJUOBJ8MAaQO
AYoWBrYOAJEZCLkOAJAaCbQRAb4PAJgaB5EcCJgaCsQTApIkDpcjD7MdA88WApUnENQZAdgaALgn
BbknBcUkA74mBLooBcUoA8ooBMspBb8tB8ksBsssBMQuBsEvCM4sBdA3C8w5DtQ9CuBBCd5DCthG
DdxFDNtGDdpIDeBGF9lJDthLD+FIFtZMEddMENVNENNPEtVPEuJLF9FTFeRPGPpLDM1YF+FRJOdR
GetRGuhSGfpODeJTJudTGexTFONUJuJVJvVSEPpRDv9QD+NWKOxWE/9RDu9WE/pUEP9UD/9VD/pX
Ef9XEfpZE/BcFf9YEf9YEv9ZEvRcFvJdGP9aE/RdF/JeF/pcFOxgF/9bE/9bHfRfGP9dFP9dFf9d
FvpfFv9eFOpkGf9gFf9gFv9hFv9hGP9jF+tpHP9kF/9lGP9lGv9mGP9nGf9oGv9oHP9nK/5pG/9p
Gv9pG/9rG/9rHf9sHP9uHP9uIP9vHf9wH/9xHv9yHvp0IP90H/91IP90PP54Iv94Iv95Ivt6MP97
Jv9/L/qAPv+DOP2JR/+LXP+NXf+RYP+VY/+ZZ/+daf+gbf+hbP//////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////yH+EUNyZWF0ZWQgd2l0aCBH
SU1QACH5BAEKAP8ALAAAAAAUABQAQAjmAP8JHEiwoEGBJMpMomQJESFAeOrEsUJDBIGD/3ZgcuQn
jRQiMh5gJOgizCI7QlocGDkwCac8ctig0ZKjAUuCJlYEuCkQhZhHjRIV+nMGSAgABkF86JABiadB
eu7IMeODwgIJFSAcHKKpDZgtWKLUQHDTAgMMGzxomBCBJ8EWbgmu4FGEhQG3J8hAYpQIzo8UAkaq
UBOJkaJDgvjg6dKjRIGCI5pIqnTpk6FAe+q4oQLFRgwOAw4y6dSnzpw3XHQ4uHlkE501Y75cuZHg
ZpBMXrJgqaJkhoKbMJ5McbLECI4XF+LeDAgAOw==
}

#===============================================================================

    image create photo nextConflImage\
        -format gif\
        -data {
R0lGODlhFAAUAOegAEsKAEkLAE4KAFsHAFUJAFkMAVkOAV0PAZIIAZcKAYwPBJoMAJUOBJ8MAaQO
AYoWBrYOAJEZCLkOAJAaCbQRAb4PAJgaB5EcCJgaCsQTApIkDpcjD7MdA88WApUnENQZAdgaALgn
BbknBcUkA74mBLooBcUoA8ooBMspBb8tB8ksBsssBMQuBsEvCM4sBdA3C8w5DtQ9CuBBCd5DCthG
DdxFDNtGDdpIDeBGF9lJDthLD+FIFtZMEddMENVNENNPEtVPEuJLF9FTFeRPGPpLDM1YF+FRJOdR
GetRGuhSGfpODeJTJudTGexTFONUJuJVJvVSEPpRDv9QD+NWKOxWE/9RDu9WE/pUEP9UD/9VD/pX
Ef9XEfpZE/BcFf9YEf9YEv9ZEvRcFvJdGP9aE/RdF/JeF/pcFOxgF/9bE/9bHfRfGP9dFP9dFf9d
FvpfFv9eFOpkGf9gFf9gFv9hFv9hGP9jF+tpHP9kF/9lGP9lGv9mGP9nGf9oGv9oHP9nK/5pG/9p
Gv9pG/9rG/9rHf9sHP9uHP9uIP9vHf9wH/9xHv9yHvp0IP90H/91IP90PP54Iv94Iv95Ivt6MP97
Jv9/L/qAPv+DOP2JR/+LXP+NXf+RYP+VY/+ZZ/+daf+gbf+hbP//////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////yH5BAEKAP8ALAAAAAAUABQA
QAjmAP8JHEiwoMGCTDr1qTPnDRcdDg4aXMGjCAsDEgsGyeQlC5YqSmYoyKhCTSRGig4J4oOnS48S
BTLCeDLFyRIjOF5cyCjwyCY6a8Z8uXIjwcERTSRVuvTJUKA9ddxQgWIjBocBB0+QgcQoEZwfKQTw
LNhiLEELDDBs8KBhQgSzOzA58pNGChEZD8YO0dQGzBYsUWogGJuEUx45bNBoydHgIIgPHTIg8TRI
zx05ZnxQWCChAgSCJMpMomQJESFAeOrEsUJDBIGDKMQ8apSo0J8zQEIAGOsizCI7QlocMDvQxIoA
xJP/CwgAOw==
}

    image create photo helpImage\
        -format gif\
        -data {
R0lGODlhFAAUAOfqACEhISMjIyQkJDg4OD4+PkNDQ0pKSlNTU1RUVFpaWltbW11dXWBgYGhoaGlp
aXd3d3p6ehekCxqlDRymDR2nDh6nDn9/fyOmEB6oDh+oDyCoDymmEiKpECSpEIKCgiOqET+gIiWr
ESarEiarFCisE4aGhiuuFiyuFS2uFS2vFi6vFjStGy+wFjCwFkSoLoqKijWtKzWwGTKxGDauLDWx
GTOyGTSyGTixHDazGlijVY+Pj0GxJTu0HTy0ImahZT21HWGkXJGRkT22HT23Hj+3HkG3JUqzO0K5
IZWVlWaqVUS6IU21PJeXl0q7Jki8I5mZmZmZmkm9JEm+I121S5ybnFa6OE6/JpycnGS0VFO+Kk/A
Jl+7Mp6enmC5SlHBJ3CyYp+fn1PCKWu2W6CgoG62W2y2ZFXDKmO/NGW8TVbEKlfEK3S2bl7DMG65
ZlzFL6Cmn6WlpVzHLWLFMl3HLne5cXO7bmHHMl/IL3u5dGDIL366YmPHMWLIL2rFPmjHOqmpqWnI
OmXKM461i368d2XLMmbLM4u4iGXMMmbMM6iup33DX426iq2trYDEYJO6kJW9gY3AgJu6lrGxsbKy
srKys7W0tYPMapfDjbS3s4/Jcp7CjJfEjobOZbi3uKTBno7Nb6TEoJ7Ijru7u53KjpHScZHSd6XJ
mb6+vqrIpabLm67IqKnLnp7Qk8HBwcLCwqzMoMPDw63PobLNrcfHx8DOvLrRsLjSscnMyczMzNDP
0NHQ0cbVwrncqdHR0cPV09PT08jYwtPU09TU1M7Xysraw9bW1tfW18/az9LczsrhwNPb4dLgy93d
3d7e3t/f3+Dg4OHh4dnl1eHi4dPqyOPj4+Tk5OXl5ebm5uno/+bs5ubt6ezs7Ozt7O7u7vHx8fLy
8vLz8vT1+ff39/f3/vn4+fv7/fz8//39//7+/v7+////////////////////////////////////
/////////////////////////////////////////////////////yH+EUNyZWF0ZWQgd2l0aCBH
SU1QACH5BAEKAP8ALAAAAAAUABQAQAj+AP8JHDhwFsGDAq+9ikMIkUNEcnid0+ZCBYdBnRoc5FIJ
UyQ8ZdYIehMEwgCEzsTV8sOnD6dSlqoI6bHJmCSCroKhUeIkShMyX7DQUCGCAoxELwIcfCYOHLJY
o1LtkgatFcJm3BodKpRpmaZH0c6Fm8LCyC1GA5mZ0qJmzh02yczZAsFDBokJdP4sGDgJ16UaNlYA
8ZHjQoUIdahYEIBwoAEFCxAQAND4YDFr3b5520at183K18gRU+QmjRcpR7rIYgbr4K9vwAAh+oRO
ne1yrG6kQJWrxMBqw+w4PLNlzx496caJaTEClKgD/05RC6UmT8NApKahy5YkxgkNbShSORAojFYU
K2HMZFl1DNIPHCg6SHAEpoBAOLpUFRlCZIcybL5sIEIGESzyBAMHSdKKJ0uYEMIHGEwwgyFQeHBS
Yw8gMQYYVzChgwUJKFXZiI0FBAA7
}

    image create photo markImage\
        -format gif\
        -data {
R0lGODlhFAAUAMZbAAAbAAAdAAAeAAZXAwVeAg96Bw18Bg58Bg99Bw5+Bw9+BxB/CAyBBg6BBw+C
CA6EBwmKAwmKBBGICA+KBxKKCQ2NBw6NCA6OCA+OCA6PCBSOCheOCxeQCxaRCxeUDRmUDSGZEyOg
FiKlECGmEC6jHyOpESWpESSqESaqEierEierEyirEyesEyisEymsFCusFSmtFCqtFCqtFS+tFiyu
FSyuFi2vFS2vFi6vFjCwFzWxGjOyGTSyGT2vLDazGjezHzezIDu0HTm1HDy2HT23HkezNT+4H0G4
IEK5IEu7LUy+Kle7Rle7R1O9QVi7R1i8Rli8R1i/RVnARVnARlnAR1nASFrARl7BTV7CSm3IU3rP
YP//////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////yH+
EUNyZWF0ZWQgd2l0aCBHSU1QACH5BAEKAH8ALAAAAAAUABQAQAeWgH+Cg4SFhj1ZIIYXS1M0LQgC
hoMEA5OXmIIRUFhAG4MUOj47P1dNMiYJAZmsrYYVTlY2LguSHklIRkQdghlQUTEoBwCYDy8xKSUN
xK7Nzs+FFkUkzhhQUjguBa0VT1Y3KwurfyFaSkcfhBBQVDUqDsyDGkFDQjwcE0xVMCgKkpcSZuSw
EYPFCQP/WDEQMcJAPGgQWwUCADs=
}

    image create photo unmarkImage\
        -format gif\
        -data {
R0lGODlhFAAUAOeuACsAADMBAFAAAE0BAFUDAFwDAVkEAWsGAW4GAX4HAngKBIwHAZMIApUIAocN
BJMLA4sOBZ0LA64RBJ0WB7gPCqgVA6UXCLQVA68XBK0YDawbCaocCqwdCr8YCcYWDLMdCbseBM4Z
Ds0dD8weCb4jBcMhFMsgDrwkFdIhGM0mDMUtEc8rGtUqHcovENQsFNQvCMsxEdstCtEyENA0HuAy
DuQ2CuE2E+Y2CdU6FuU2EOk3DuY4Eu04C+o5C9s9Fds9Fu86DPI7DOg/FvM9DvQ9DtpCLPQ+DvRA
EPJAFvVAEOBEJ+VEGehEIdxGM+1FF+5FF+pGGvdDEvhDEuFJLPhFFflFFe1IG/lGFfVJGvpIF/tI
F/hJGeNNMPJLHPZKG/tKGvxKGf1LGvVNHvxMHP1NHPpOHedSMOlSMP1OHf5OHP5OHftPH+lTMPxQ
IP5QH+xUL/xRIO5ULf1RIfpSIv9RIPNUK/9SIfJWLf5UI/9UIv9UI/dWK/5VJP9WJP9XJf9XJv9Y
J/9YKP9ZKf9aKf9bKvBfOf9cK/FfOP9dLP9dLf9eLf9fLv9gL/9iMv9kM/9kNPlmOv9lNP9nN/9o
OP9pOf1qO/9qOv9rPP9sPP9tPf9uPvFxTPxvQf5wQP9wQf90Rf52SP92R/93Sf95S/98Tvx9UP9+
Uf+AUv+DVf2FWP+FWPiHX/+KXfmNZP//////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////yH+EUNyZWF0ZWQgd2l0aCBH
SU1QACH5BAEKAP8ALAAAAAAUABQAQAj+AP8JHEiwoEGCJThlkvRo0aA5OBQY7PBlyxMYEAgyiNHj
BYgDBzepMgVqxsA3jPR4aWGAoJJKjhQRCoSnTZowWqpE0SHhYJNVqU4UDLFHDpIRBimUGvVJUxwz
kwzxsbLhoMApnRoS+mNnjI0HB5n8yUOnzBIOCXZQiZLESJAaFQoKsEq3IIuDIkwcRNGK1alCBD3c
GYTGyQeDRVCREgUpw78zkQCt+eHAKpdQnjBRkqQIkBgVA+qysfSIESE/XSzQXXHoUiNEg7iqCZMl
RwSDdRIJAtQHDhQhYLJckZKECI8LA138cUMGi48JAP41oHFkCJAbJAgQTCFDQwGDCzAHIAhQt/zA
gAA7
}
    image create photo markAllConflictImage\
        -format gif\
        -data {
R0lGODlhFAAUAOeZAAAIAAAJAAAKACMAACQAAAALACcAACkAACsAAC0AAC8AAAAOAAAPADQAAAAQ
AAARAD4AAEcAAEsAAE0AAFAAAFsAAGAAAGMAAHoAAIQAALMAALQAALUAALYAALkAALoAALsAALwA
AL0AAL4AAL8AAMEAAMIAAAI5AcMAAMYAAMgAAM8AANAAANMAAJAUAJ4QAKQPANkAANoAANsAAJwT
ANwAAJYVAJ0TAAJBAZMWAJwUAJsVAGEnAOkAAGcnAGsoAC07ATk/AH4rAARhAUpUAwpnBQloBAhp
BAlpBAppBQlqBQpqBQdzAwhzBAp5BU5mBgt7BQx+Bil5CCp6CCp6CSd7CCZ8CCx7Cil9Cg+ICSCF
DBiPCyGRDSCSDSKbDyyZFR2fDh2hDiOgFiGlECKmECSnESanEiOoESSoESaoEiepEyeqEyarEiyq
FSesEiisEymtFCqtFCutFCyuFS2uFTCtGC2vFi+wFzurKjKxGDawGzWzGjizHzm0Gzy2HT22HUK2
Jj+4H0K5IEK5IUe4NEa7Ik23OUy7OEy7OU27OU27Ok67OE67OU28OFC9Olm9RlzBSWPBUmPBU2PC
U2TCU2bEVWfEVHbMXHbNWoqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqK
uIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqK
uIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqK
uIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqK
uIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqK
uIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuIqKuCH+EUNyZWF0ZWQgd2l0aCBH
SU1QACH5BAEKAP8ALAAAAAAUABQAQAj5AP8JHEiwYEELPWKkkEBwgAcZOq5QamRnTRGCTtrcoRPH
zZkjDwyKHKlgRAwQGij8E4Op0CAvPjh4yGGlEqI4ZZQEGMlTYIMOGXoONPBBBgwpj/AMERjkiRAU
ICIg4FDDhkRGc9IkYTAwih4/ffZ00TJJ0ZsySLj2bAImjJGQQuPKFXmgxAwTF+QmCBHjBhEgAARi
aDHBIIKiO6ZYcnRny78KMVisQAFBIIENM2hQobRojpolCwQauvTlBwkRKmK8qBIpkZw1ShwMzAJI
UKA/XHi4wCLpEBw0SGQbhFJnTx4+kAi9IYMkdE8mZuCwGXNEwNx/OE4UEBoQADs=
}

    image create photo markAllImage\
        -format gif\
        -data {
R0lGODlhFAAUAMZbAAAbAAAdAAAeAAZXAwVeAg96Bw18Bg58Bg99Bw5+Bw9+BxB/CAyBBg6BBw+C
CA6EBwmKAwmKBBGICA+KBxKKCQ2NBw6NCA6OCA+OCA6PCBSOCheOCxeQCxaRCxeUDRmUDSGZEyOg
FiKlECGmEC6jHyOpESWpESSqESaqEierEierEyirEyesEyisEymsFCusFSmtFCqtFCqtFS+tFiyu
FSyuFi2vFS2vFi6vFjCwFzWxGjOyGTSyGT2vLDazGjezHzezIDu0HTm1HDy2HT23HkezNT+4H0G4
IEK5IEu7LUy+Kle7Rle7R1O9QVi7R1i8Rli8R1i/RVnARVnARlnAR1nASFrARl7BTV7CSm3IU3rP
YP//////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////yH+
EUNyZWF0ZWQgd2l0aCBHSU1QACH5BAEKAH8ALAAAAAAUABQAQAfRgH+Cg4SFFkUkgxpBQ0I8HBNM
VTAoChhQUjguBYQSMzk2MSwnBgKFp6h/FU9WNysLAYIhWkpHHwwiIwYQUFQ1Kg4AqcOXmZt/s7Uf
hLy+wIeJnZ+howarra+xgouNj5GTlabDf7i6wuPoghFQWEAb6apOVjYuC+I9WSCnF0tTNC0IxP3x
kASJESIdBGWAEiUGigPr2r0TREGHjx0/rjSRYSJBBXn07AnCB+LBixgpSjTg5w+gQIIGERIYsLDh
w3OFKl7MuLGjtmEmUarEmW5mukAAOw==
}

    image create photo prevUnresolvImage\
        -format gif\
        -data {
R0lGODlhFAAUAKU0AAACAAcAAAQHAqwAAa4AAqUEAMEAAMMAAMQAAMYBALwFAs0AA9AAAMcEANcA
ANsAAtIDAOQAAN8FAABzAACDAEOiGz6oIEinIDqvJ0WuJ0qyLEq6KWK2Ml26NVHBMGK9MFnHN1zI
L2TIOmjKM3LTPHXXQHTcO3LcRHXdPHPdRXbePXvjQnnjS3rkTHvlTXzmToDqUYHrUoPtVZPwaP//
/////////////////////////////////////////////yH5BAEKAD8ALAAAAAAUABQAQAafwJ9w
SCwahZEIY9FIIFwslsp0wgiOBcfhoDiVShbAsciINGQx0HUsHEgYW1YKlRGziQyK/f6TmJswLy0s
G2tHBBEQcVIaAXcFD3AHJycmF3tjAZqbmnxFmJ59EjMhhnd+TTEvLh6mRRARCwsJCatyKROuELJM
TgeDKxwcHSMTRwNKcSkqdXdukimVl48OCwcGlCcVoEUFW1skIh9hoZ5BADs=
}

    image create photo nextUnresolvImage\
        -format gif\
        -data {
R0lGODlhFAAUAKU1AAACAAcAAAQHAp8AAKwAAa4AAqUEAMEAAMMAAMQAAMYBALwFAs0AA9AAAMcE
ANcAANsAAtIDAOQAAN8FAABzAACDAEOiGz6oIEinIDqvJ0WuJ0qyLEq6KWK2Ml26NVHBMGK9MFnH
N1zIL2TIOmjKM3LTPHXXQHTcO3LcRHXdPHPdRXbePXvjQnnjS3rkTHvlTXzmToDqUYHrUoPtVZPw
aP///////////////////////////////////////////yH5BAEKAD8ALAAAAAAUABQAAAacwJ9w
SCwajYGkMnkkXkCjEmKKMACawovJhFpMH1bsz4IqHxAM8BWLOZWnDUiY7VbBJ4R1U5NSte55Yhor
fnASgUhJGystfwgREgVKTiQeHR0sLS4ICQoODKARAkQZKCeMLS+dnw0SEqNFFCp+LzAKCqASok0c
mjAxng4SE7BNH7UynsMDYkIhMjPCDcXNIjQTxM1FFQ162kPe39pBADs=
}

    image create photo showHelpImage\
        -format gif\
        -data {
R0lGODlhFAAUAOfYAA1EpgFp0FhoggB64CJ0y0VtuF9vjlx3mwCK8mV2kGZ2kWZ3kmd3kgSL8mh4
k2l4lGl5k2l5lGp5lGp5lQ2P8V+CqHCAnnGDqnSEpWOLsWaNs3+Or02a3ICQsIGRsYGSs1+Z1IKS
s4OTtIOUtWyc13Kh1Y+gu4+kwX+pzZGlwaGkppKmwqOkpJSnw5WnxKOmqaSnqJmowJepxJepxZmp
xZupwaeoqZiqxYWu3Yau3pqrxpqrx52rw6mqq4Wx05at2Z+txKGuxaOvx6+vr6WxyIu53Kazype2
3Ki0y7C0uai1zau1yKq1zKq1zZC737S1taq2zaq2zqG43qu3zqu3z6C61LK4vLS4u7m4uK+7zrm8
vry8vLi+wrq+wbzAw7zCxsDDxZnM7cTExLHI4cXFxcfHx8jIyLLN4sTKzsLK2MrKysnLzMzMzMzM
zc3NzcbP1c3OzsPP48jP1b3R58PQ58/Pz7/S58HT6MvS38LU6NHS0sPU6cTV6dPT08XV6cbW6sfW
6tHV19XV1dbW1djY2NLa4NTa5dra2tzc3NXd6Nzd3d3d3N3d3d3d3tHh7t/f39vg5dvg69Tj793i
5dbk8Nrk7ODj5uPj4tjl8Nrm8uDl7eXl5d3n7tzn8t3o8d3o8t7o8tzp8ufn59/p8+Dp893q8+jo
6OHq8+Ds9Ovr6ujs8uTt9OTt9ejt8+Tu9ebu9O/v7+nx9/Dw8Orx+O/x8u3x+ezz+O3z+PDz9/Lz
9PLz9fPz8+70+fT09PD1+fH1+vH2+vP2+/b29vL3+/P3+/T4/PX4+/j4+PX5+/b5/Pf5/Pn5+ff6
/Pj6/Pj6/fr6+vn7/fv8/fz8/Pz9/v3+/v7+/v7+//7/////////////////////////////////
////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////yH+EUNyZWF0ZWQgd2l0aCBH
SU1QACH5BAEKAP8ALAAAAAAUABQAQAj+AP/9uzBChIgQHzx02IBBoMOH/5BUe3aoGrYfAAqkYrQF
0qgdEGOwcuVqVSEuSay88VQqlKMUEKdgm0lzGjRNWc4UqQDxX5BhazaZMjUmAIhBbMTAyCQDYpRq
1a5Zo2aTmSoUGXoKbEKzFyJGjwS1sQSM1ykaEIk407NMmrEcJI5cIlSnx6cbEHncsgVGjRwKCBr4
wKKCE6UWEA1MkMD4QQQIDhwwWKAggQCISpIp25ysGLFfiQ5oFUiF5sxq0Zq1qhJGg1Yopqsdy6UL
lyE8aZZYgMhkJqxHz4LRiWSqTKBbpEA+NBKtkbCZtaTEEYXIjRZQOiAKQQZH1i5aOAhFlFjURw2L
TjMgAvE1yQwjRU4GcEBDZsgXTC4g1pgV65WXJ110cYUNL1SCiiQrQGTCH38AAgiDfvCxRx532DHH
CaNl2FNAADs=
}

    image create photo infoImage\
        -format gif \
        -data {
R0lGODlhQAAwAOf/AAABAAIABQADBgAGEAQFEQIHFwAJHAANIgUXRAAbSAAaUwQeXgAhXwohWwAj
aAAlYwAlcQInYAApbQAqdQAteAwpfQAtfwEvgQIviQIvjwAzkgkwmAAzmQA1nA8zhwA2lgA4iwA4
nxU0lgA8lAY5oQg6mgA9mwo7lQA9qQA+pA07owBAmQBApgBCogBCqABCsARDnApEqwBHrABIrgBK
qgBKsABKsQBKtwBLsgBMswBNsgBNuAVNtABQrgBRvQBStwxPtg5QsABUuhBQtwBWvABWwwBXvhdS
ugRYvwBbxgpZwABcyQ1augBewwBfvgBfxABgxRJbwgBgxgBhzgBiyARjygBkzwBozQtlywBo1ABq
zwBq1wBr0BJmzRFowQBs0RVnzgBt0wBu1AFv1QNwzwBw3AZv1hxqyx5rzAxw1wB04EBmsBBx2A9y
0gB22wB33RRy2QB52AB53xhz2gB55gB64AB72ht03AJ74QB96Qh84hB95ACB7gCC5xN/3wCE6QCF
6xSB2hd/5gCG7ACI5wCI8wSI7h+C6R+D4weL4w6J8ACN+TuCyQCQ9SaH4QCR9xeL8gCS/wCT+QCT
/wCU/yyK5B6N9AOV+wCW/x2Q6VmDvACY/yKP9gCZ/g2W/DGO4gyX9laHxSOU5hOX/QCd/xeY/zaU
4SuY61yNyxme7wSk/yCc/CCe9zGa7leS0DWd8CWi9EGb6BKo/zeg7USd6yqk9l6Z1mib1D+l8kuk
7EOo9Tir/jet+Waj2lKp8Uet9D2w/Uuw912t6US1/0+z+Vmy81K1/EW5/o6pzUi6/4qr1Fa4/0q8
/1a7+2G4+lq+/5C01lzA/2W/+pW525i833fH/ZfB6ZfF5Y/H85bJ8KjI5ZvN9J3Q97DZ9cnV46fe
/q/d/rjh/dfg6N/h3ubg3+ri2uLk4cbq/+vl5OXn5Mzs/dXt/+jq5+/p6PLp4urs6ezu6/Pt7Pbu
5/Dy7/nx6ffx7/P18vr18/X39P727v/58v/5+Pn7+Pv9+v3//P///yH+EUNyZWF0ZWQgd2l0aCBH
SU1QACH5BAEKAP8ALAgAAAAwADAAQAj+AP8JHEiwoMGDCBMq/BcFyatkx5YlSyZrlEVPkho1gmRo
0J8+gvTUkePGTRgdLRYKLAKFGLFmvCRdmjlTks0k0+LBgzdvnj18+xb9kVMSTpowYbhooRJFR4mD
OqDMmpVJ0J+rWK/26WNJGrhv4MKGDTdKUBqkX7SA6UKFChEgQ2JoAIBQRhw7bPLqzQtnSq927ODN
w8fPn2F1mLRQgfLkCRIdNXToCAEBgEqCDUqw4IFEiRIkRIj8GMKjNA/JklmE4KBAwOXLToicSVQL
GC9eunDVgvUqU5wnPHS8PujkysRk0VRZXE7qBTJy46KbM5fOHR1BeuSUhJMGqRYgLRL+/ojCy1ew
RpDSq1+vJts9fP0My8f0x80cNmnCfNECpguV0DFccJAObZziSB0IJqhgHWHk4IQy3rAjjjam7CHH
F1xoAUYXVEABxROl6VADBwYsdEIMYHChxYosagFGGIdEggkpmGDCyRxRPBHFDzrUUIMMNYSQwQDD
DQfAkQAUqWRCPzQJRBA9LDmcEmfokswxxhxjjDG8sAJKI4MA8ocggvSBCCF+KKHDClIi8cpx0ciy
HCkhrKFJKKGg4oorttiSRh161CGHG3CkkQYYMoCgEhNtHLPMM8csZ5EnnoziAzTopMPOpu/AQw8f
fdQhhxtzsJFGGF9oQcUQKSR0xCn+vxDDCySNPGLrI43k2sgW1tQzDz788CMfJn/I4cYcbKQRxhda
gNEFEkikkIBBPFyBiy6wADLIttx2y8c2+/Ajn3yY9AEHG2mE8YUWYHRBxRNNyvABAAYNccoslZCp
77766oEgHGmwMQcchqYRxhdcaNFFF1RA8YRpKTiAUA1+fDJHSRhn/IQX7qDTDjw94cOPP89EsnBb
UDTGg2Q6hLAAAArFQIUbSNVssxrC5HMPP+OGM4ocjT2hhA4+1iADBwoAMNwJLCixcFtQU+Ghh0Ej
AYRkRcvQQQYFACBlQQx8EEIIKbAQw9kspBACBxxowEABAHwt99x0161kEqEpcQX+GW20gQYURAzx
AxB2F+QEEnHocswwwABzGy+64DJLKqdU7ggVPNBA9xRIJJLMMctMdIwsnTxiSXqGDPJHH2TqUYcc
dXShAwxLToEELMc9A4xFpNTAgw8+FJFEElZksUUadehRhxxuwMFGGDWsMBwSjhwXjSqSkoICMuWQ
Q4456ITvjhp66FGHHG7AkQZST8QQgUpE1LJMMtHsIulyNyBjzjjmpLMpO/LYgyDqIIeSwCENYfgC
F6AQAwoohAivMMYynrEKSo3CE6PwhCQ8UQRobOod8IBHT/KxiD/UQQ5umAMb0hCGL3CBCk9gwQMQ
QoRABIMYzgDFI2xik1s9Ygr+1KhHT+yBj2D5AxOAkENJ4JAGpHBBC11Qwg9ScICDHEEXvygGKyCh
qy5CohFmuMY98BEswxgGE38oCRzSgBQuaKELVCACElggAYMEgQq68IUvBmGI9aTHEICkQzb2wQ8z
mhETfXADHNKAFC5oYWFQaJIMNGCQH1wBF7k4xR8AAYhucfIqheBGPwxpxlEIgg1pQAoXtLAwKihh
CD+QgQgAUBAaIIEWs8iEILbCS16SyRM1CqYwSSEIpHxhRV1oCxSGUBoWWAAABtGBI2LhiPLxSxDl
q4Me3BAFHxQhCVPIAhvgkAakcEELYOgCFTxEBNOEAAEHqQERRJEIOdjznvj+nMMNGIGOdrADHvO4
Rz6wsQg5aAEMXWgLFJ5ABJaxQAMBQIgMnvCJOVh0DhizqBuScItNvWMe9sBHsPxxDkxwoS1QaMwP
dFADHcSAAwVQSAuI4IeC2TQNYeBCIOgBj3nggx+GrAYmPNQYJeigBkhlwQYIoJIRxEALYfiCVKfK
BS6kgQ+v6AY/DLOOZ4ziD0FDgg6QitQOVEAAwzFBDKigBTC4dWFwpUIX2OAGOHThCVF4AhJ4QFak
hiADBQDAkjzAAh5AIWpTg8IToqCEH/CAZWRlAQcqMAAA0G0CIVBBDHhAhCb9YAim4YEOZJCCDmwA
AgQAQOEIYgAEOMACGNATgAYwUAEHIMAAAQDAanfLW94GBAA7
}

    image create photo errorImage\
        -format gif\
        -data {
R0lGODlhQAAwAOf/AAABAAgAABABATMAADsAAEUBAEsAAFgBAmAAAXEAAG4CAH4AAngCAGgHAogA
AYMCAI0AAJMAAW0NAJgBAKAAAZAGAK0AAqUEAJUNALEFALsEAr0IA6oOALMMANIDAL4LALUOAMAO
ALYRALcTAMERAMsOAsMUANcPAM4UAMUXAMYZANAYANoWA9IbAMoeAPATAN0aANQdANUfAOgaAv0V
AN8eANchAtgiAOEgAOIiAOwgAPYeAeQkAO4iAO8kAOYnAvgiA+coA/AmAOgpAPEoAOorAOkrBfMp
APwnAPQrAfcuA/8sAOYzEPgwAP8uAOo3CPszAP83APc5Bf85APA9D/86Af86D/o9Cv1ADe9FGv9C
D/dEFv9EEexKIvZLIP9LEvZMKP9MFP9MHvFQJ/RRIPpPI+5UJuZVN/NSL/5SHf9UH/lWJfpXLf9W
KfNZMv9bKf5bMP9cK/9eLPRhNPlfPftgN/5hK/1hMv9jM/hkPv9kNP9lPP9qNv5qPP9qQ/9rPvtt
PN5zX+1yWP9wP/ZyUP9yQPlzS/9yRux3Wv9zTv90SP53Qf94Sf95UP96S/l7W/96V/J+Zv19Uf9+
TP9/Wf+AU+qEbP+DXP+DYvaGZf+FVf+GYtuOhP+JZOyNd/6MZeKThPuQbP+Pbf6SaP+VcOyahf+W
d/+Wff6Zcv6beeKhkvqef/iehf+de/+efN+nm/6hff6ig/+khf+lh/Sql/6ph/irk/+rj9qzruS0
q927rv+0oerAtv+8ptzFwfq/s+bGv//CqvvGsfbLwf/Lvf3RwN7Y19ja193a39je4Oja29Dg5//V
ytze2trf4t7g3dfk5dTl697j5uHj4Ofi4OPl4tfo7+Ln6tzp6vzi2Ovm5Obo5efq5ubr7uDt7unr
6Ors6f/n3fDr6fnp49/w9unu8ezu6+Xy8+/x7vjv6Ozy9Of09fbx7+X1/PHz8PD1+P/y7PP18uv5
+fv19PP4+/b49fX7/fD9/vn7+Pr8+fv9+v/8+vn+//z/+/7//P///yH+EUNyZWF0ZWQgd2l0aCBH
SU1QACH5BAEKAP8ALAgAAAAwADAAQAj+AP8JHEiwoMGDCBMq/NfDUK1YsWrdGsWIkaJCf/7o0ROn
oxo1YsJwGWllSpERCwXmoJQqVSxFhQopWvSnBrlq27h1U5dETZgr8/jl80eUWJgpSKdASUKkRYsL
B1f0oYRJzMc2atrEuQKkVLtu38yhcxevHj59RIvxSQoFShIiRHq0IEHCxAMAB0fkgJMUy7Jjx5xh
46WHS9IpS7BUSsevcbZWXnLkaNFBhOUOBwCkJNiAg4kWMlrIcNpihQm6ITZoGKFBxAgLEQgA2JwS
CRE3n1qlIhVKVKdNlII3OlTGSAsStA32IAXxVitFjMy0wOXtHKgihfhs7NhmyaPG/Mb+nQqDdAmU
HCISsvDzSdSmOBvj6+FzBdE6cObQuYtXD18+ouGowYUVSS0BRRJwlVCCCQ8c1MIeiYwURhhTWAJN
M81MU8023Jgjjy3i2FMPPvkQZaI/wdzRg2QkaKABCRcIsBAHOSzR1o1tJaEjXHD1MMQPkkm2Qgci
dGBkBwsEkNySTDaZUA1QQslCCy44mVIPVKAC0ZaxiCLJH3p01MZHYkwohhpXyCBCkz3MUUssstzS
SkWVAMJEF4wM8sdGHcWhhhhILIEFF1xYgdQSNWCQUg+otBLLLZVUNEkNvkjzzDTdAPMCH3rcYccV
ZTSmjz5EtZHUElAYUYMICWVBCin+rTDCR0YZDVLGGedsww046NxDCzv85KOPiZSEYUVSS0CRBBEr
rEBCAQadoMgmoujR57Vx2LFEJOqYg4478dSDjz7+UBKGFVYktQQUScCVgwkmqFCBQSZk0QgkYYgh
hhpXEKGKN9JUsw033JiDjjvu1INPPifCo4kaQCRBRA895LABXSIgcBAJOfwhBhZcTLGFLslg2Mw0
15QTihpTcFEJO/bgg48+J1ZihGQajCDCCBYYsNAKXCTFBSGGqMHFEkgj3ZaOREixyBpFzCBZDZYZ
OcIFBACQ3AUt8Og1xUMM8UOQOchggmUiGCkCBw8EYGVBCExg5AZ0mUDXCB1cQIH+AwUEAMDbgAcu
+OAL7TCDEWPkYUhwjRxSBxhP1LCCCoQP1AMdrcQCSystmWKKKJQ0csgfe+yRURtGrBB4D3PUsuUt
tXyiyCAZbdRRG2roGwahhP4wQpM9GFJLLLXcEoskFU3CSCF/8LFRnx/pGwahViA1RAfJUVFLLLXc
ksoik8xRgwyc1PDHIH9s1FEbaiDByi9wLHHYEkmoIMFCO7gBUS21VMSIB8i4xjOqcQ4mrIEPerhD
R6ZAB37YAx+NYUYYkLIEKORgBQ9ISA/G0IpWxIIUhfBfFgKBjWlUYxvyEMQV9GAHLlyhMfkwUSe4
gBSkQaEHMjBBAxCSA1KYohX+ouDDIIY4iEX0IBfX2AY3vvGOYdDACvPghz5MtI84YCEpSEsCEZwi
goPIwA2iEIUp7KAHPpjxjC9QRje4YQ50uIMe9sBHPky0CzEcZglQSAJcmmWCBhiEBYfohCgU0ZE7
yEcPcdiBNsphDnS4Ix71wIc+iPIHLljhMG1JAhGGYAIVlAACBjnBISjRiTaYsiOoVAMS0KCNcpgD
He6IRz3woQ9/9CIOVkgK0qCQBCL04AbwMkEFAFCQFbABEpQQw0c+IgYkoMEY3tgGN75hDnS4Ix71
wIc+TJSNRXBhCVBIAlzCZgK6kIABBzFCIhLBhQmJAQqvsEYymjGNbWyDG+D+QMc76BEPmenjRP5o
hR2I0IMh/GAFG9hACDowgIOYoAx+CAPvpuAGaGDoGdO4RjfksQo1HIId9qgHPvQB0GB4QTItGIEG
RqABCAAAISsQQxumgIUlWCIagMHQNaghCTEkhQuaYIc97IEPfRCFFFmQTAksIwINTCAACiHBFbiQ
FE9EIxrGyIQaprAEpCANCki4wiTGIYxK3IEMkqmBZYwkgggEICUcqMEUkoaUpLWlLTriUQ9mMIMg
yUAERxKBBRQAgORYIAdQ0JFivQYXiv2AbDIgQQdEYCQRdMABAXBSBTZQgxxQbAg9CBvZWLACErho
BEwVwQUUEADBMcACJCgvwQpKoAJ4mZMECd2ACCwwgQMEAACVIwgBEMCABzjgAQtIwAEGIAAABPe5
0K1cQAAAOw==
}

    image create photo warningImage\
        -format gif \
        -data {
R0lGODlhQAAwAOf/AAABAAQHAgsMFRMTGxEVIBgXGhkaIRgcHhweHB8dIB8fJxwgLDEgACAiICcj
FCAkJiQlIyQlLSgmGyImMicmKScoJiorMyssKj8sAy8tMC0vLCsvOzcwETEvPDAxOTMxNDEyMEYx
Ajw1Gz82ETU3NDc4QDc3Sjg6NzY6PTg4Szk6Qjw6PTc7SD48QD0+PD8/N1s9AEE+TUBBPz1BTUBB
SV5AAD9DRURCRUdGKV9LBVhMG1pNFXRJAE5ORnBLAnJLAGZRDHZPAHRSAGZWGGFYH39WAIVWAF5c
PnBfGoZcA3BgIpBaAGhhM45dAIpfAG9mLGxmPopkAJhhBJhlAJVoAJtoAIhuE59rApxuAnp0MqNu
AKJyAKZxAKlzAKd3Aqx2AKB7AoZ+Nax7ALB+AKyAALSCBbaDAK+HAJ+LHruHALWNALqMAr+LBJmT
K8GMAMONAKyVAruRAMCRAMaQALmVAMmSAMWVAKWcI8OYAs6WAM6cAMWgAMqfAMmeEMmeHrSoHdCk
Bs6jJMmpB86oHNCpDsitANSsAMm0AM+zAtWvOdmxHNawMdqyKta3Pti7Fda+ANu6OtbEAO+9ANq8
Uu69FOzAAOe+LdvAPurAJN+/T/TBBOHIAOHBSfjEAOHCWPDEHeXMH+LIVeTQAPPMAODSAPLLEuPH
avnLGefLdf/QAO3TGufYAObOaenPW+7QRunQZOnTT//WAPrTL/vYAOjVX//WFevdD+rZQurUderZ
S/fXO+zTie/bMfbXRf/cAOzeJe7ZXfXfGfDdPezcVvjhAu7aZe/dR+vcXe3abO3dT+zYhercZfne
K+zbc+/ZgOvbee7hNezgSP/iAO3hP/DfUercgfHjLPPkH+/biOrdiPnjIv/jEe7cj/DnIPDkQvLp
De/fff/nAO7dluvfkfTqEvzqAPHfku7fnvDfmfftAPvqF+3gpvbsFvTwAPHiov/uA/PhrvbyAO7j
r/fzA/3xBvn0APLlqv/0APXluPv2AP74APn6APv8AP3+AP//Af///yH+EUNyZWF0ZWQgd2l0aCBH
SU1QACH5BAEKAP8ALAgAAAAwADAAQAj+AP8JHEiwoMGDCBMqVMhmkbx159Ch40bR2ZoaCzMezKOH
IjZsmHIMQNAAwoUMSmoNS5aMGqgtGhO+CcUNW7VnzZAVA3bMF5EPJFzcyFLO2rVu3b59I0cuXTtB
QTKOGXSOGzZnz5ohQ7bs2LBkxoRBq6RmCBJDvtKla9eunr59/Pzx80e37paBeLtkcscNW7VnzZAV
OzZsGLVo06BZQ/qNXbp28/Tt41e3suVCPwLg3cy58780gUyhavRmi+fTqE/PYYVOHMVs2KpVe9as
2VZCUVLrHvhGEbpszp7VPrUjQQUNIEisYCJtGrTn1qx1K7N7sxxs3LBVe9YMWbFjhZP+GdN2yESM
P++6KWWXjm27evr07eO3qonnL4nWoeOGzdmzZlsVc8wwyRgzzTSx6GABCS7QEMY97cTHDz+WVahP
E5tlqOGGHHbo4Ycghiiihmr0gc86KJ5zDi5mjOjiQG9kss456FD0kWzPgIOHEC+CaIcy6FBkiRxA
jCDCEICUsswxTDpSRY8a5gEIOh/JpokDBzRQwQUgkFBCLMYYI8yBv4gBpUBvXMJNNtU808xWveyx
gAYgkOACC49oA0101yDVDTtx1ODiG7hwU80zzzSDTDHHFGbMLB64IMMMxFyD1DffkJNOOu7p80gS
H6bRBzrcYFPNM80gU8wxhSVjzIH+1tBDDzndfENOOu7Ft8+E/NDVzhQbjtHIOuhwg001zzSDTDHA
DJNMmNN0IsEDGpCwwhHhtNNOfLxWWBcZGODFhSfroMMNNtU80wwyxQAzDEvGTAONNcSEs4ko99DT
Tj36TOitZav4EECGRVyxBRcIJ6zwwldU4fDDU0Q8hRRNVNzEEkbwwEAAZ3bs8ccga2hGGWaMsUXI
IqYxCT7wyCMPN3ZQgbKHb+yCoooSobMIFjNvaAc6KqIjDkUfZXOJFz3jVYce50hEETayIVobLGMk
/c8chJwjDjfjvGIJJZJ84kozyBSzTC5p9DwHJOhwk00rcggwQAIPUDCBIbocUxj+NXLUEPIcoaCD
jTPVSMJBAQhAUIEGH7wwyzDJhOnNHkF8PAcr3GRTDaKacJAABBdoAAIKMvgSzYHPWYOIEx3b4Uw2
ziBamyxWKHCBBiScoAIa2zwXnTXXdLPJFD3OwQc32TjzTDNbFQNMKhFoQMIJMtgQzu/XIIUpO7Zc
4eIchJiDTTXPNLNVMccMwwwcHpwgAw1/qGMNUpiSs2k62nIhYhqMoIONM89oxlaWcYxhsCQcT2jB
DaBwD6Rgih3p0Ja24sMPMoRgQ3hJAyfQgY1qPKMZW1nGMYaRDGMIYxrvuEMb7tENTJEjHRKMjz74
QUN/0KEGGPxHGliBDmw4oxr+z2gGMopxjGEkI0zTgIYqSjGKYHyDHJvSlgxpyI/KFOIHG0qDMtDB
DWxU4xnNQEYxjlGYZBhjGqUAAwEeYIENCCIc2pqHPvZBRW9FwggZWgM6ziEObmCjGs9oBjKWcYxh
JMMYB+qEASoAghPYoAfvaEc94kPDf9GFFEHAyxc8sQ50cAMbznhGM5BRDGAUJhnGmAY0gjEKHHQg
BVAoBz3aoY990NCSdOHHEgIwECz4wR7o4AY2qvGMZiCjGMAYRjKMEY1pQCM63SDHprQVH37445rY
zCY2z8CADHXBD6GgBS2AAYtc5OIWtxAGL6DxC2tc4xrfIMc30qEtfeyDijQn3Ic+9amPVaghCAHQ
0EACQNCCGvSgCE1oQgXK0IY69KEQjahEHRoQADs=
}

    image create photo questionImage\
        -format gif \
        -data {
R0lGODlhQAAwAOf/AAABAAACBgQBBgYDCQkGCwwJDgoLFQ4MEBENGw4OIA4PFxESIxUSHxQUHBUU
KhoVJxgXLRcYKRsZJh0aNh4cKRscPB8gMR4fQCEhQiAiPh0iSCMkNSUjOikmNCcnSSMoTionTycp
RSkqPCYrQSssPi0qUi8tRS4tUCouVS0uXDAxTjMxSTMwWTM0Rjg2Tjc3SjU5UTs4UTo7Tj47VT88
VTs/VkA+YkBAUz9AXj1CZUJDVkZEaEVFZEhKdExMa0hNcVFOdE5QelRRd1NTclFTflVWdVtYclZa
c1lahltccF1agWFehWFhdl9gjGJgk2ViiWFlfmJjj2Zjl2hlgGJnmWZnlGhmmWVpj21pkWtvlW1u
mnBtoW5vqXNxpXVypnV1lnl2qnl5p3t4rXV6rYF9mn19q398sXl+sXt/soSAnYGBr4KCo32CtYSB
tn+Dt4iEoYCFuIaGqIiFu4OIvIqKrIqKuI2Jv4eLv42Mu4mNwY2RuY6Sx5KSwZWVt5GVypaWxZSY
zZmZvJ2ZtpmZyJaaz5ubyp2cv5yg1Z6hyqCg0KOi0qGk2qWk1KOm3Kio2Kqp2qaq4Kur262s3a6u
3q+v362w5rGw4bOy47G067W05ba15rO34Le26LS37rm43ba54rm46rq567a68b655by77Li888G8
6L6977q+9cC/8L7B68HA8cLB88XB7cPC9MDD+8TD9cjD78LF78XE9sbF98rF8cfG+MPH/sTI8sjH
+cnJ7crI+sfK9MvK/MzL8M/K98nM98zL/c3M/s7N/8/O88zP+c/O/9PO+tDP/87R+9LR9tXQ/NbR
/tDT/dTT+NfT8tHU/9LV/9bV+tPW/9TX9NfW+9rW9dTX/9nY/drZ/t3Z+Nva/9zb/9rd+93c/97e
9uLd/dzf/ePe/uDg+N7h/9/i/+Li+uTj++Dk/+fk9uXl/efn/ujo/+bq++np/+rq/+/r/fDs/uvv
/+zw/+3x/+7y//Hy/PLz/fP0//X1//b2//r3/Pv4/fz6/v77/////yH+EUNyZWF0ZWQgd2l0aCBH
SU1QACH5BAEKAP8ALAgAAAAwADAAQAj+AP8JHEjwkiVKkyRJcqRoEMGHECNG5KTMn799+fLNW1eO
XDhw3LYZcfAA2jJjw4LlouXKGikzBGPKjPmHE7ds2bBN2xkNGhMBAhAJC7bL1ixX1s5RE+UHiYCZ
UKMKlAOLVi5laBoQfKVtn799Ge3FK0dO3IkJIXZCW2ZsWLBctFwpaxO17kBL4LbpzYZtZzRoQAMM
E9YrFy1Xq0rFOvfISYCYkCNLnrxlUShOz+70ADD5H6x1/Pzxy3dvnjx47NaJ24ZtWjRmxoYJ63Uo
TOfbj6rNm1eOHDlx4LjpfZOAQTJmxowNC5bLFqxVwNKFurPitnU1mpYl57Yt+bBeuVb+YTrUZtGs
c/by7ct3b148eOzWidsJbdkwSXisxwRiZcsGgZzwMg8/+cBTDjnigMONXjUgIAM0yxgzzDC72ALL
KqVQs0kT+t1WRB2KkLIMM8kNE8wutszCSiqpfAMKGEQQ0OGMkm3hhRU7FADAjLe4Yg089uRzjz3z
xAMPO+Vgs9Msj/hB42SvaGORPxnZMw88JXygwQUVTPBFNMwkJ0wvufzCyh1PDmRJOP7sk88965Tj
GzjcbKPLEQssYMgyxgwTzC62wILKOansQcNtknFCDjjcNKpXNthM00wxwByTnDC95EKLK6kok04r
j1AhAKKTFYILNtNAAw0zy2yDzTT+0DQDTTXdnHOONaxgssginbCCiy/KEAOMLKZcwsggfBCk7LJ5
DNPLLtkMM0cHCihQgAAA6AHMPRZlZM888cCTAgggZLMTNMsYI0wwu5DSxrLLXgEHJ7QA8gNBstjj
zz4ZxVNOOeSAw40LDqwwDTTLJCfMLrbAkooykiAB78TKalIOOeKIA06j22SDzTRpJEFGcsMEk4st
sKxyCivn7IEDxTAPxEcm2OwUDTTMLJPcMML0kgstsLBSCzHjKHOHEAHErDS8LfigxBNPLLFFKKeE
ogo1bZiw9NZLb6GJKo5YYQEAXJdtNtevkOIKMc5oA0432UgDTCuZLHLI2Uqjoo3+Pfnwk9E88sDD
DjvlbDNNNMwsswwrhayBt7KpsGPRPhnZMw8dQbDwgQ1xRDMNNMsYM4wwu+RCCBaP/8NKPv7wk9E9
87BTzg59eBJIBhBwEA0zyQmziy3A5NJIFXhn0o0//GRkzzrl+AYON9tU48ICMDCTnDC95DLLKt+k
cgcJZ1cSjj/75LNOOb6B06ggESQggiHMJCdML7nM4koq7aSyBw1nK+JLOb4RBzgapRdsxIEBEmDG
MowxDGHswhazYEUqxkENUYhBAnhbRDW4oZdtZAMbO5kGFAhAAEQYQxjByIUtYLEKZaRDGaJwQwwA
8LhByGIbIYxGNJixjOQYQxj+wdgFLWihDFsRQxR+kMINppCISlyiEpA4hNn4cAloKM4Y01iHFm11
jnBUoxiw4EQlOoGLbrBDHmiMBzzYsQ5yYGMau7gEIOqgtCwwIjnCAMcyDuEGN6BhDF6QAhAkUYx5
7IMfGbHHPOIxuHJwYyfQWEZyhhGKO8TMDZIIhi2ccQw0HEBZrJiHRfiRj3vMQx7sKAcKMOABbEwj
GsxIjjB2YYteOEILMNNCHlyxCmXMQQQEOYU8/MGPjNwjHuXwDThUAAETTCMazEiOMHqRi1msQhqA
4EHMhuCFPSyiCgQBhj38kRF4lMM34ODGNmKwgBdEgxnJGUYvckELV6RCGZ/wiALXNjCCgchiHflg
h2/EAQ5u6AUbOjDADZiRHGH0Ihe0cEUqSjEORhDhcY2QhjgaxQ29ZAMbO5GFLFRhjGEEYxe2mAUr
UlGKZygDDBQQiExnStOa/uMPo+BGNrARwmhAYxkCAAAAhNGLXNACFqs4hSu+4QswkAAANo1qVNWg
CFxMIxrM8OEwgrGLXNACFqxIxTioEQs7IIEAUk2rVH1QhjsQohGTuAQlLEEJV6SCFKn4BiGCEAC1
+vWvMq3CI0LRCV+oQgoHAKxi1coFSWBCF49wwgEWS9moooETdXCCBQBQ2c7OlAo5KAAAPEvazgYE
ADs=
}

    image create photo preferencesImage\
        -format gif \
        -data {
R0lGODlhFAAUAOfxAK8OBwQ5aQM/eAY/dLgbEgdHgsEjFAhPkLsqIcgqG9crEgpaocczI6s7OLo5
L+EyFA1ir8M7KQ5mswZoxb9AMwdpxMBCOMFCPRBrugltywpwzuRBIRJwwg1xztBIOQ1zz+FFLKdU
SRF0zhB20BN2yhV3yRV3zxN50Bp6zxZ80cpXQq1dXBl+zxl/0h2B0RyC0yeBzx+E0h6F07tjWyGH
1CKH09JiUi6IwSWK1CWK1SeM1SiN1TmJzyqP1SuQ1kOLzTmO0y2S1i6T1zCT1MxxaTGW2GKNtUuS
zzSY2NB4cTWc2zec2TWd3LiAe5yIhjqe2jqf2jyg2Tyh2j2h2jyi3D2i3Oh7aF2azz2j3T2j3raJ
gVqe1T6n4z+n4l2i102q4G6jztyLe2Gm2qCcnLOalmaq3FWv4lev4nynzX6nzn6pzn+pztmVk36q
z2yv34Cs0IGs0IGtz2G15IKu0IOv0HCz4nmz2ISx0ISx0bSoqIWy0Wq55nK35MCnppKxzXW55oi2
1He753K957GxsXi9596nonu/6LS0tHrA6aG4zbW1tbW2tre2tn/C6be3t4DD6oDE6rq4t4HE6oLE
6ry4t7q6ut+yrLC/zb29vd21sM65t76+vozJ7L2/wMDAwMfAv8PDw77HzsLKzubCwM3JyNHJyc/K
yczNzs3Nzd7Jx8/Nzc7Ozs/Ozc/Pz9HPztDQ0NDR0ejLx9HR0dLS0tPS0tPT09LU1NTU1M3W3NTV
1dXV1dbV1O/PytXW1tbW1tfX19jY2NnZ2dra2tva2dvb29vc3Nzc3N3d3d7d3d7e3t/e3erc2t/f
3+Df3+Hf3t/g4OHh4eHi4uLi4ebh4OLi4uPj4/Hg3OTk5Obm5ebm5ujo6Orp6erq6uzs7O3t7O3u
7u/v7/Dw8Pbw7/Ly8u/z9fPz8/X19fb29vT3+fj4+Pf5+vn5+fn6+/v7+/z8/P39/f7+/v//////
/////////////////////////////////////////////////////yH+EUNyZWF0ZWQgd2l0aCBH
SU1QACH5BAEKAP8ALAAAAAAUABQAQAj+AP8JzFJlSpSDUaR04SKwoUMkgcp1E+apVJ5ZjKyYEjZH
hsN/LrbsmkVLFStXp0JdSuTnR4WPWCS1S8fLA6VONiJ8onZMT4+PO9xggzZrhoUkDsYA+3VLzQmY
j+C9c8dOHTpysTaIwmVnyEcohs6NK6YJAYEmi6hBM3Ynx0chfLxlm2YpGrNMCrT0+vWmxccaYpQR
QwVr1IpvlWrVepXmw8d/JUhwwCABwoIDBQYEeCwQixlOkxAJ2iPnzBcjT5gouQETkrt14qyNA7cM
hApbyQAF+UilUTpzyCgQKWTASTVqxvDo+LiEkDlwwXyxafAMk7NmxOjQ+FjkTzhu2oBc6dKVK8wD
UMDivPjoo862a6kSkInEIESrYLrapPiIo4y0ZK+QcgEAfTgy3ixrjPBRDF4MA8wrimwyyCGOyPLK
Kmho8BELQMABxhVH8AADCiaI0EEGEwjA2YorBgQAOw==
}

    image create photo automergeImage\
        -format gif \
        -data {
R0lGODlhFAAUAOeEAAAAAAICAgMDAwQEBAUFBQYGBgcHBwgICAkJCQ8PDxERERQUFBUVFSMjIyQk
JCUlJScnJygoKC8vL0cwAUkwADIyMjU1NU45BTo6Ojs7Ozw8PFI8AD09PUJCQkdHR25QCFhXVnNe
F4FdA3ZgGmBgYIFgD3llMG1tbXFxcXh4eH5+fn9/f6KCIKqED4SEhKqGF7WKFI+Pj7yPC8CPALqZ
I76aI8afFMqfDcSfIr6hMdOhBKGhocyiKs2lJKWlpcanWqurq8WvRtixIbCwsLGxsd2zH9S2N9e4
Mty4Kdq5Md+5J7e3t9+6KuW8INm9QLq6uui9Fbu7u9u/OLy8vMDAwN3FTcPDw8PFzOjLP+XQUfDR
OObRWs7Oz//TF9vPq/jUKu7VTP/VGtHR0f7XIt3Tu9TU1OXabPLaS//aJtXV1fbdS9jY2PjfT9vb
2/fkY9/f3/7lTuDg4N/g5P7mUP/nReLj5fTpd//sUv3rY//tUvvsa+bm5v/uYevr6+zs7P/4hfLy
8v/5iPj4+Pn5+f//////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////yH+EUNyZWF0ZWQgd2l0aCBH
SU1QACH5BAEKAP8ALAAAAAAUABQAQAjaAP8JHEiwoMF/LEJsqGFmIJE1ffbUIePFhMApgJ44OEDg
wMGPUMbg+aNlxkAjUl6I+CgwAgYIAgAAaEBCA0uBSmgMFKLmjhOWdviE+ZJjAsEoV3icOXLzQQcX
g96IWbLjRMETHiQMkGmgwM1/MVJk+EqWYBIcPT4i0VFETxCBMpjAyQPmw8EbbALN6UKnikAYIwi2
ILjFTRM0WSgQ5JJGzg8sNi4cLCEwQRRBguK0ARQHBMsKGA4wAGLFBwqWFjgskDngAACWVFQokBkA
QYCvQ/yUWeGgrO+PAQEAOw==
}

} ; # Load_Images

#===============================================================================

proc ::Yadt::Collect_Debug_Information { } {

    global auto_path argv tcl_platform errorCode errorInfo CVS_REVISION
    variable ::Yadt::OPTIONS

    set msg {}

    if [ info exists CVS_REVISION ] {
        lappend msg "CVS Revision: $CVS_REVISION"
    }
    if [ info exists OPTIONS(is_starkit) ] {
        lappend msg "Is Starkit: $OPTIONS(is_starkit)"
    }
    lappend msg "Tcl version: [ info tclversion ]"
    lappend msg "Executable: [ info nameofexecutable ]"
    lappend msg "Current directory (pwd): [ pwd ]"
    lappend msg "User Login (tcl_platform): $tcl_platform(user)"
    lappend msg "Hostname: [ info hostname ]"
    lappend msg "Platform: $tcl_platform(platform)"
    lappend msg "OS: $tcl_platform(os)  osVersion: $tcl_platform(osVersion)"
    lappend msg "Auto Path: <$auto_path>"
    lappend msg "argv: <$argv>"
    lappend msg "errorCode: <$errorCode>"
    lappend msg "errorInfo: <$errorInfo>"

    return [ join $msg \n ]
}

#===============================================================================

proc ::Yadt::Popup_Error_Message { err_msg { err_code "" } } {

    # Use pure Tcl/Tk only!  
    # Don't use procedures from additional loaded packages!
    # No catches should be used before
    # ::Yadt::Collect_Debug_Information execution below

    global ERROR_CODES  LOG_USER_CHOICE  CVS_REVISION argv

    set w .log_err_window_[ clock clicks -milliseconds]
    if [ winfo exists $w ] return

    if { $err_code == "" } {
        set err_code $ERROR_CODES(error) 
    }

    set wtitle "Yadt"
    if [ info exists CVS_REVISION ] {
        append wtitle " $CVS_REVISION"
    }
    append wtitle " Error"

    set wlabel "Error"

    # Switch by error code to re-define such widget
    # parameters as 'wlabel', 'wbitmap' and so on
    switch -- $err_code \
        $ERROR_CODES(ok) - \
        $ERROR_CODES(return) - \
        $ERROR_CODES(break)  - \
        $ERROR_CODES(cancel) - \
        $ERROR_CODES(continue) {
            # there is no error, do nothing
            return
        } \
        $ERROR_CODES(error) {
            #
        } \
        $ERROR_CODES(uerror) {
            #
        } \
        $ERROR_CODES(argerror) {
            set wlabel "Wrong Arguments"
        } \
        default {
            append err_msg "\n\nUnexpected error code <$err_code>."
            set err_code $ERROR_CODES(error)
        }

    # Complete error message depending on the error code
    switch -- $err_code \
        $ERROR_CODES(error) {
            if [ catch { ::Yadt::Collect_Debug_Information } debug_msg ] {
                append err_msg "\nDebug error: $debug_msg"
            } else {
                append err_msg "\n\n$debug_msg"
            }
        } \
        $ERROR_CODES(argerror) {
            append err_msg "\n\nArguments: <$argv>\n\nYadt [ ::Yadt::Get_Usage_String ]"
        }

    set height 20
    set width  55

    toplevel $w
    wm withdraw  $w
    wm resizable $w 1 1
    wm minsize $w 100 100
    wm title $w $wtitle
    wm protocol $w WM_DELETE_WINDOW "global LOG_USER_CHOICE; set LOG_USER_CHOICE 0"

    frame $w.labels
    if [ catch {
        ::Yadt::Load_Images
        label $w.labels.bitmap -image errorImage -anchor w 
    } ] {
        label $w.labels.bitmap -bitmap error -foreground red   -anchor w
    }
    label $w.labels.text   -text $wlabel -foreground black -anchor n
    catch {
        eval $w.labels.text configure -font $::Yadt::OPTIONS(default_title_font)
    }

    frame $w.scroller
    text $w.scroller.text \
        -height $height \
        -width $width \
        -state normal \
        -background white \
        -foreground black \
        -exportselection 0 \
        -selectbackground lightgray \
        -selectforeground black \
        -wrap word \
        -yscrollcommand [ list $w.scroller.yscroll set ]

    scrollbar $w.scroller.yscroll \
        -orient vertical \
        -command [ list $w.scroller.text yview ]

    frame $w.buttons
    ::ttk::button $w.buttons.close -text "Close" -image closeImage -compound left -command "global LOG_USER_CHOICE; set LOG_USER_CHOICE 0"
    ::ttk::button $w.buttons.save  -text "Save" -image saveImage -compound left -command [ list ::Yadt::Save_Error_Log $w.scroller.text ]

    # We have to pack our widgets in such way that in case of
    # main window reduction button 'Close' would desappear last:
    # - buttons:
    pack $w.buttons       -side bottom -expand no -fill x
    pack $w.buttons.close -side right -padx 10 -pady 10
    pack $w.buttons.save  -side left  -padx 10 -pady 10
    # - labels:
    pack $w.labels        -side top -expand no -fill x -pady 10 -padx 10
    pack $w.labels.bitmap -side left  -expand no -fill none
    pack $w.labels.text   -side right -expand y  -fill x
    # - scroller:
    pack $w.scroller         -side top -fill both -expand y -padx 10 -pady 0
    pack $w.scroller.yscroll -side right  -fill y    -expand n -anchor n
    pack $w.scroller.text    -side bottom -fill both -expand y -anchor s

    set x [expr {([winfo screenwidth  $w]-[winfo reqwidth  $w])/2}]
    set y [expr {([winfo screenheight $w]-[winfo reqheight $w])/2}]

    wm geometry $w +$x+$y
    wm deiconify $w

    set old [ focus ]
    focus $w
    tkwait visibility $w
    grab set $w

    $w.scroller.text insert end $err_msg
    $w.scroller.text configure -state disabled

    set LOG_USER_CHOICE -1
    vwait LOG_USER_CHOICE

    grab release $w
    catch { focus $old }
    destroy $w

    catch {
        variable ::Yadt::WIDGETS
        set wdgs [ concat [ ::Yadt::Get_Diff_Wdg_List ] \
                       [ ::Yadt::Get_Merge_Wdg_List ] ]
        ::Yadt::Restore_Cursor $wdgs
        ::Yadt::Restore_Cursor $WIDGETS(window_name)
    }
}

#===============================================================================

proc ::Yadt::Save_Error_Log { text_widget } {

    set err_msg [ $text_widget get 1.0 end ]
    set parent_win [ winfo toplevel $text_widget ]

    set output_file \
        [ tk_getSaveFile \
              -parent $parent_win \
              -filetypes { {"Log Files" {.log}} } \
              -defaultextension .log \
              -initialfile "error_file" \
              -title "Select Error Log File" ]
    if { $output_file == "" } return

    set fd [ open $output_file { WRONLY CREAT TRUNC } 0644 ]
    puts $fd $err_msg
    close $fd
}

#===============================================================================

proc bgerror { error_message } {

    ::Yadt::Popup_Error_Message $error_message
}

#===============================================================================

################################################################################
#
# YADT_PANED
#
################################################################################

#===============================================================================

variable ::Yadt::FRA

#===============================================================================

proc ::Yadt::Yadt_Paned_Save { wdg type } {

    variable ::Yadt::FRA

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

proc ::Yadt::Yadt_Paned_Resize { wdg } {

    variable ::Yadt::FRA

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

proc ::Yadt::Yadt_Paned { action wdg args } {

    variable ::Yadt::FRA

    switch -- $action {
        -create {
            eval panedwindow $wdg $args

            ::Yadt::Yadt_Paned_Save $wdg 0
            bind $wdg <ButtonRelease-1> "::Yadt::Yadt_Paned_Save %W 1"
            bind $wdg <ButtonRelease-2> "::Yadt::Yadt_Paned_Save %W 0"
            bind $wdg <Configure> "::Yadt::Yadt_Paned_Resize %W"
            return $wdg
        }
        -pack {
            eval pack $wdg $args
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
            ::Yadt::Yadt_Paned_Save $wdg 1
            event generate $wdg <Configure>
            ::Yadt::Yadt_Paned -fraction $wdg default
        }
        -configure {
            after idle eval $wdg configure $args
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

################################################################################
#
# MAIN
#
################################################################################

global ERROR_CODES
set ERROR_CODES(ok)       0
set ERROR_CODES(error)    1
set ERROR_CODES(return)   2
set ERROR_CODES(break)    3
set ERROR_CODES(continue) 4
set ERROR_CODES(uerror)   5
set ERROR_CODES(cancel)   6
set ERROR_CODES(argerror) 11

set err_code [ catch { ::Yadt::Run } err_msg ]
if { $err_code } {
    if [ catch { ::Yadt::Popup_Error_Message $err_msg $err_code } errmsg ] {
        puts stderr "$err_msg\n\nPopup Error Log Failed: $errmsg"
    }
    exit 1
}
