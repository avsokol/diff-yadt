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
variable ::Yadt::NO_NEWLINE_WARNING {\ No newline at end of file}
variable ::Yadt::NOLF
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

    ::YadtCvs::Ignore_No_CVS_Tag_Error stdout -code exitcode

    if { $exitcode != 0 } {
        return -code error "Error while executing <$cmd>:\n$stderr\n$stdout"
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
    set DIFF_FILES(orig_path,$index) "$filename"
    set DIFF_FILES(path,$index) "$filename"
    set DIFF_FILES(full_path,$index) "[ file join [ pwd ] $filename ]"
    set DIFF_FILES(tmp,$index) 0
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

        set cvsroot   [ ::YadtCvs::Determine_CVS_Root_From_File   $filename ]
        set cvsmodule [ ::YadtCvs::Determine_CVS_Module_From_File $filename ]

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
                set cvsroot [ ::YadtCvs::Determine_CVS_Root_From_File $filename ]
            }

            set f_cvsmodule [ ::YadtCvs::Determine_CVS_Module_From_File $filename ]

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
            set rev [ ::YadtCvs::Get_Work_Rev_From_Entries $filename ]
        }
        if { $rev < 0  ||  $rev == "" } {
            # Failed to obtain version from 'CVS/Entries' OR it is defined to
            # get version from the "cvs status" command:
            set rev [ ::YadtCvs::Get_Work_Rev_From_CVS $filename ]
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
    variable ::Yadt::OPTIONS

    if { $rev == "" } {
        set rev "HEAD"
    }

    set DIFF_FILES(label,$index) "$filename (CVS r$rev)"

    set abs_file [ file normalize $filename ]
    set n_file [ file nativename [ file normalize [ file join $OPTIONS(git_abs_dir) $abs_file  ] ] ]
    set filename [ string range $n_file [ expr [ string length $OPTIONS(git_abs_dir) ] + 1 ] end ]

    set vcs_cmd [ list $VCS_CMD -C $OPTIONS(git_abs_dir) show $rev:$filename ]

    return $vcs_cmd
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

    set DIFF_FILES(orig_path,$index) $filename

    set output_file_content_to -file
    if { $DIFF_TYPE == 2 && $OPTIONS(use_cvs_diff) && $OPTIONS(vcs) == "cvs" } {
        set output_file_content_to -variable
    }

    switch -- $output_file_content_to {
        -file {
            set DIFF_FILES(path,$index) [ ::Yadt::Temp_File $tailname ]
            set DIFF_FILES(full_path,$index) "[ file join [ pwd ] $DIFF_FILES(path,$index) ]"
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
            set DIFF_FILES(full_path,$index) "$DIFF_FILES(filename,$index) $DIFF_FILES(rev,$index)"
        }
        default {
            return -code error "Unsupported value <$output_file_content_to>\
             for 'output_file_content_to' variable in [ lindex [ info level 0 ] 0 ]"
        }
    }
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

    foreach fname [ ::Yadt::Tmp_Files_List get ] {
        file delete $fname
    }
    ::Yadt::Tmp_Files_List clear
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
# Interface procs to call from other YaDT packages                             #
################################################################################

#===============================================================================

proc ::Yadt::Get_Yadt_Option { key } {

    variable ::Yadt::OPTIONS

    if ![ info exists OPTIONS($key) ] {
        return -code error "Unknown key <$key> in YaDT Options"
    }

    return $OPTIONS($key)
}

#===============================================================================

proc ::Yadt::Get_Diff_Type {} {

    variable ::Yadt::DIFF_TYPE

    return $DIFF_TYPE
}

#===============================================================================

proc ::Yadt::Get_Current_Delta { file_id } {

    variable ::Yadt::DIFF_INT

    return $DIFF_INT(delta,$file_id)
}

#===============================================================================

proc ::Yadt::Incr_Delta { file_id value } {

    variable ::Yadt::DIFF_INT

    incr DIFF_INT(delta,$file_id) $value
}

#===============================================================================

proc ::Yadt::Create_Scr_Diff { diff_id start end type } {

    variable ::Yadt::DIFF_INT

    set DIFF_INT($diff_id,scrdiff) [ list $start $end $type ]
}

#===============================================================================

proc ::Yadt::Get_Diff_Scr_Params { diff_id args } {

    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::OPTIONS
    variable ::Yadt::DIFF_INT

    set is_exists [ ::CmnTools::Get_Arg -exists args -exists ]
    set for_diff_id [ ::CmnTools::Get_Arg -for_diff_id args -default 0 ]

    set start -1
    set end -1
    set type -1

    if { $DIFF_TYPE == 3 && $OPTIONS(merge_mode) == "expert" && $for_diff_id == 0 } {
        if { $is_exists } {
            return [ ::YadtDiff3::Get_Range $diff_id -exists ]
        }
        lassign [ ::YadtDiff3::Get_Range $diff_id ] start end type
    } else {
        if { $is_exists } {
            return [ info exists DIFF_INT($diff_id,scrdiff) ]
        }
        if [ info exists DIFF_INT($diff_id,scrdiff) ] {
            lassign $DIFF_INT($diff_id,scrdiff) start end type
        }
    }

    return [ list $start $end $type ]
}

#===============================================================================

proc ::Yadt::Get_Pdiff_For_Diff_Id { diff_id args } {

    variable ::Yadt::DIFF_INT
    variable ::Yadt::DIFF_TYPE

    switch -- $DIFF_TYPE {
        2 {
            if [ llength $args ] {
                return -code error "Waste arguments <$args>"
            }
            return $DIFF_INT($diff_id,pdiff)
        }
        3 {
            set f_id [ ::CmnTools::Get_Arg -file_id args ]
            return $DIFF_INT($diff_id,$f_id,pdiff)
        }
    }
}

#===============================================================================

proc ::Yadt::Init_Scrinline_For_Diff_Id { diff_id } {

    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::DIFF_INT

    for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
        set DIFF_INT(scrinline,$diff_id,$i) 0
    }
}

#===============================================================================

proc ::Yadt::Get_Diff_File_Label { file_id } {

    variable ::Yadt::DIFF_FILES

    return $DIFF_FILES(label,$file_id)
}

#===============================================================================

proc ::Yadt::Set_Diff_File_Label { file_id value } {

    variable ::Yadt::DIFF_FILES

    set DIFF_FILES(label,$file_id) $value
}

#===============================================================================

proc ::Yadt::Tmp_Files_List { action args } {

    variable ::Yadt::WDG_OPTIONS

    switch -- $action {
        clear {
            set WDG_OPTIONS(tempfiles) {}
        }
        get {
            return $WDG_OPTIONS(tempfiles)
        }
        add {
            set fname [ ::CmnTools::Get_Arg -file args ]
            lappend WDG_OPTIONS(tempfiles) $fname
        }
        default {
            return -code error "Unsupported action <$action>"
        }
    }
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
        "^--ignore-blanks$" -
        "^--initline$" -
        "^--inlinetag$" -
        "^--inlineinstag$" -
        "^--inlinechgtag$" -
        "^--merge$" -
        "^--merge1$" -
        "^--merge2$" -
        "^--merge-backup-suffix$" -
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
            "^--ignore-blanks$" {
                set OPTIONS(ignore_blanks) 1
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
                set DIFF_FILES(merge1) [ string trim [ lindex $argv $argindex ] ]
                if { $DIFF_FILES(merge1) == "" } {
                    return -code $ERROR_CODES(argerror) "Missed file name for <$arg> argument."
                }
                set DIFF_FILES(merge1) [ file join [ pwd ] $DIFF_FILES(merge1) ]
            }
            "^--merge2$" {
                set OPTIONS(preview_shown) 1
                set WDG_OPTIONS(preview_shown,is_set) 1
                set OPTIONS(show_diff_lines) 1
                set WDG_OPTIONS(show_diff_lines,is_set) 1

                incr argindex
                set DIFF_FILES(merge2) [ string trim [ lindex $argv $argindex ] ]
                if { $DIFF_FILES(merge2) == "" } {
                    return -code $ERROR_CODES(argerror) "Missed file name for <$arg> argument."
                }
                set DIFF_FILES(merge2) [ file join [ pwd ] $DIFF_FILES(merge2) ]
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
            "^--merge-backup-suffix$" {
                incr argindex
                set OPTIONS(backup_merged) 1
                set OPTIONS(merge_bkp_suffix) [ lindex $argv $argindex ]
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
                                          ::YadtCvs::Split_CVS_Conflicts \
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
                                          ::YadtCvs::Split_CVS_Conflicts \
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
            ::YadtCvs::Detect_VCS [ file dirname $fname ]
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
                return -code $ERROR_CODES(argerror) "Invalid parameters specified: --merge2 can be used only in 3-way merge."
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
            if { $option == "lftag" } continue
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

    set yadt_rev_title ": [ file tail $DIFF_FILES(label,1) ] vs. [ file tail $DIFF_FILES(label,2) ]"

    if { $DIFF_TYPE == 3 } {
        append yadt_rev_title  " vs. [ file tail $DIFF_FILES(label,3) ]"
    }

    wm title $WIDGETS(window_name) "$WDG_OPTIONS(yadt_title) $yadt_rev_title"
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
    set CVS_REVISION [ lindex [ split "$Revision: 3.300 $" ] 1 ]

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
    lappend auto_path [ file join $cur_pwd tcllib lib ]

    set WDG_OPTIONS(yadt_title) "Yadt"

    set WIDGETS(window_name) .yadt
    set WIDGETS(pref) .yadt_pref
    set WIDGETS(help_name) .yadt_help
    set WIDGETS(pref_help) .yadt_pref_help

    package require BWidget 1.8
    package require CmnTools
    package require YadtCvs
    package require YadtImg
    package require YadtLcs
    package require YadtDiff2
    package require YadtDiff3
    package require YadtPaned
    package require struct::list

    ::Yadt::Init_Opts
    ::YadtImg::Load_Images

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

    ::Yadt::Update_Save_Menu_Tooltip

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

    set OPTIONS(current_merge_mode) $OPTIONS(merge_mode)

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
        \t --ignore-blanks\n\
        \t\t- if set, blanks are ignored while finding file differences\n\
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
        \t\t - defines a 3-way merge mode. Acceptable values: <normal> or <expert>. Default is <normal>\n\n
        \t--merge-backup-suffix <bkp_suffix>\n\
        \t\t - if set, before saving merged file, it will be backed up with a suffix .<bkp_suffix>"
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
    #     Note: - actual only for diff2,
    #           for diff3 - use_cvs_diff = 0 will be used anyway
    #           - local copy of repository is mandatory;
    #           - if called outside of local repository dir - use --chdir to get there,
    #             otherwise "cvs diff" will fail.
    #
    # cvs_ver_from_entry - the way of determining working CVS version
    #     1 - from CVS/Entries file
    #     0 - from "cvs status" output
    # Note: any operation with cvs can slow down the whole YaDT execution time
    #
    # Paramater merge_mode accepts the following values: normal, expert
    #
    # Parameter use_diff is an experimental parameter, when it equals to zero 
    # YaDT will compare files without external diff utility usage.
    # However, there are cases, when such comparing is much slower than via 'diff',
    # therefore it should not be used in production for now.
    # See ::struct::list::LlongestCommonSubsequence2 description for more details.
    array set OPTIONS {
        align_acc    0
        autocenter   1
        automerge    0
        backup_merged 0
        merge_bkp_suffix "bkp"
        ignore_blanks 0
        cvsroot      ""
        cvsmodule   ""
        diff_layout  "vertical"
        geometry     ""
        merge_mode   "normal"
        use_cvs_diff 0
        use_diff     1
        preview_shown   0
        show_diff_lines 1
        show_inline 0
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
        default_merge_title ""
        merge_saved        0
        initline           0
        initlineno         -1
        mapborder          0
        mapheight          0
        merge1set          0
        merge2set          0
        sourcercfile       1
        thumb_min_height   10
        thumb_height       10
        tempfiles {}
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

    ::Yadt::Define_Fonts

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
            lftag      "-background darkgrey -foreground black -font $OPTIONS(default_italic_font)"
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
            lftag      "-background darkgrey -foreground black -font $OPTIONS(default_italic_font)"
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

proc ::Yadt::Define_Fonts {} {

    global tcl_platform
    variable ::Yadt::OPTIONS

    switch -- $tcl_platform(platform) {
        unix {
            switch -- $tcl_platform(os) {
                Linux {
                    set isize 9
                    set fsize 10
                    set tsize 12
                }
                Darwin {
                    set isize 9
                    set fsize 10
                    set tsize 12
                }
                default {
                    return -code error "Unsupported platform os: <$tcl_platform(os)>"
                }
            }

            if [ catch {
                set font_family "Lucida Console"
                set defFont    [ font create -family $font_family -size $fsize -slant roman  -underline 0 -weight normal ]
                set titleFont  [ font create -family $font_family -size $tsize -slant roman  -underline 0 -weight bold ]
                set italicFont [ font create -family $font_family -size $isize -slant italic -underline 0 -weight normal ]
            } ] {
                set font_family [ font configure TkFixedFont -family ]
                set defFont    [ font create -family $font_family -size $fsize -slant roman  -underline 0 -weight normal ]
                set titleFont  [ font create -family $font_family -size $tsize -slant roman  -underline 0 -weight bold ]
                set italicFont [ font create -family $font_family -size $isize -slant italic -underline 0 -weight normal ]
            }
        }
        windows {
            set defFont "{{Lucida Console} 8}"
            set titleFont "{ Helvetica 12 bold }"
            set italicFont "{{Lucida Console} 8 italic}"
        }
        default {
            return -code error "Unsupported platform: <$tcl_platform(platform)>"
        }
    }

    set OPTIONS(default_font) $defFont
    set OPTIONS(default_title_font) $titleFont
    set OPTIONS(default_italic_font) $italicFont 
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
    variable ::Yadt::DIFF_FILES
    variable ::Yadt::DIFF_INT
    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::CURRENT_MERGES
    variable ::Yadt::LCSDATA
    variable ::Yadt::WDG_OPTIONS

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
            ::YadtDiff3::Wipe
            array unset DIFF_FILES strings,*
            array unset DIFF_FILES test_strings,*
            array unset DIFF_FILES content,*
            set DIFF_INT(delta,3) 0
            set DIFF_INT(scrinline,0,3) 0
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

    return $translation
}

#===============================================================================

proc ::Yadt::Is_No_Wdg_Last_EOL { wdg } {

    return [ expr ![ regexp {\.0$} [ $wdg index "end-1line lineend" ] ] ]
}

#===============================================================================

proc ::Yadt::Is_Last_Line_Envolved { diff_id index { last_line "" } } {

    variable ::Yadt::TEXT_NUM_WDG
    variable ::Yadt::DIFF_TYPE

    if { $last_line != "" } {
        upvar $last_line line
    }

    switch -- $DIFF_TYPE {
        2 {
            lassign [ ::Yadt::Get_Pdiff_For_Diff_Id $diff_id ] thisdiff s(1) e(1) s(2) e(2) type
        }
        3 {
            lassign [ ::Yadt::Get_Pdiff_For_Diff_Id $diff_id -file_id $index ] \
                thisdiff($index) s($index) e($index) type($index)
        }
    }

    set num_end($index) [ lindex [ string trim [ $TEXT_NUM_WDG($index) get 1.0 end ] ] end ]
    set line $e($index)
    if { $num_end($index) == $e($index) } {
        return 1
    }
    return 0
}

#===============================================================================

proc ::Yadt::Get_Diff_Id_Content { diff_id index } {

    variable ::Yadt::TEXT_WDG

    lassign [ ::Yadt::Get_Diff_Scr_Params $diff_id ] start end type

    return [ $TEXT_WDG($index) get $start.0 $end.end ]
}

#===============================================================================

proc ::Yadt::Load_Files {} {

    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::DIFF_FILES
    variable ::Yadt::TEXT_WDG
    variable ::Yadt::OPTIONS
    variable ::Yadt::WIDGETS
    variable ::Yadt::NO_NEWLINE_WARNING
    variable ::Yadt::NOLF

    set translation [ ::Yadt::Get_Line_End_Translation ]

    set NOLF(global) 0

    for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
        if { ![ info exists DIFF_FILES(path,$i) ] && \
                 ![ info exists DIFF_FILES(content,$i) ] } {
            continue
        }

        set DIFF_FILE(content,$i) [ ::Yadt::Get_File_Content $i -translation $translation ]

        # load file in diff widget
        $TEXT_WDG($i) delete 1.0 end
        $TEXT_WDG($i) insert 1.0 $DIFF_FILE(content,$i)

        set NOLF($i) [ ::Yadt::Is_No_Wdg_Last_EOL $TEXT_WDG($i) ]
        if { $NOLF($i) } {
            set NOLF(global) 1
        }

        if { $i == 1 } {
            ::Yadt::Load_Merge_File $DIFF_FILE(content,1)
        }
        update
    }

    if { $NOLF(global) } {
        for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
            if { $NOLF($i) } {
                $TEXT_WDG($i) insert end $NO_NEWLINE_WARNING\n
            }
        }
    }
}

#===============================================================================

proc ::Yadt::Get_Diff_Files_Info { key } {

    variable ::Yadt::DIFF_FILES

    return $DIFF_FILES($key)
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
    variable ::Yadt::NO_NEWLINE_WARNING

    for { set j $MERGE_START } { $j <= $DIFF_TYPE } { incr j } {
        $MERGE_TEXT_WDG($j) delete 1.0 end
        $MERGE_TEXT_WDG($j) insert 1.0 $content
        $MERGE_TEXT_WDG($j) edit modified 0

        set nolf [ ::Yadt::Is_No_Wdg_Last_EOL $MERGE_TEXT_WDG($j) ]
        if { $nolf } {
            $MERGE_TEXT_WDG($j) insert end $NO_NEWLINE_WARNING\n
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
    variable ::Yadt::WDG_OPTIONS
    variable ::Yadt::CURRENT_MERGES

    set force   [ ::CmnTools::Get_Arg -force   args -default 0 ]
    set type    [ ::CmnTools::Get_Arg -type    args -default yesno ]
    set save_as [ ::CmnTools::Get_Arg -save_as args -default 0 ]
    set caller  [ ::CmnTools::Get_Arg -caller  args -default "" ]

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

    set status 1

    if { $caller != "" } {
        $caller configure -state disabled
    }

    set res [ catch {
        for { set i 1 } { $i <= [ expr { $DIFF_TYPE - $MERGE_START + 1 } ] } { incr i } {
            if [ ::Yadt::Save_One_Merged_File $i -save_as $save_as -parent $WIDGETS(window_name) ] {
                set status_msg "Merged File Saved"
                set WDG_OPTIONS(merge_saved) 1
            } else {
                set status 0
                set status_msg "Merged File Saving Cancelled"
            }
            ::Yadt::Status_Msg menustatus $status_msg
        }
        ::Yadt::Update_Save_Menu_Tooltip
        array set CURRENT_MERGES [ ::Yadt::Save_Current_Merges ]
    } errmsg ]

    if { $caller != "" } {
        $caller configure -state normal
    }

    if { $WDG_OPTIONS(merge_saved) && $status } {
        ::Yadt::Set_Save_Operation_State "disabled"
    }

    if { $res } {
        return -code $res $errmsg
    }

    return $status
}

#===============================================================================

proc ::Yadt::Request_File_Name { ind } {

    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::DIFF_FILES
    variable ::Yadt::WIDGETS

    set file_types {
        { {All Files}         {*} }
    }

    if [ info exists DIFF_FILES(merge$ind) ] {
        set file_ext [ file extension $DIFF_FILES(merge$ind) ]
        set file_ext_len [ string length $file_ext ]
        if { $file_ext_len > 0 && $file_ext_len <= 5 } {
            set file_ext_descr "[ string totitle [ string trimleft $file_ext "." ] ] files"
            set file_types [ linsert $file_types 0 [ list "$file_ext_descr" "$file_ext" ] ]
        }
        set initial_dir [ file dirname $DIFF_FILES(merge$ind) ]
        set initial_file [ file tail $DIFF_FILES(merge$ind) ]
    } else {
        set initial_dir "[ pwd ]"
        set initial_file merged_[ file tail $DIFF_FILES(orig_path,$ind) ]
    }

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

proc ::Yadt::Is_Save_Dialog_Required { ind args } {

    variable ::Yadt::DIFF_FILES
    variable ::Yadt::WDG_OPTIONS

    set save_as   [ ::CmnTools::Get_Arg -save_as   args -default 0 ]

    if { $save_as || ![ info exists DIFF_FILES(merge$ind) ] } {
        return 1
    }

    return 0
}

#===============================================================================

proc ::Yadt::Save_One_Merged_File { ind args } {

    variable ::Yadt::DIFF_FILES
    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::MERGE_TEXT_WDG
    variable ::Yadt::MERGE_START
    variable ::Yadt::OPTIONS
    variable ::Yadt::WDG_OPTIONS

    set save_as   [ ::CmnTools::Get_Arg -save_as   args -default 0 ]
    set parent    [ ::CmnTools::Get_Arg -parent    args -default "." ]

    set backup $OPTIONS(backup_merged)

    if [ ::Yadt::Is_Save_Dialog_Required $ind -save_as $save_as ] {
        set file_name [ ::Yadt::Request_File_Name $ind ]
        if ![ string length $file_name ] {
            return 0
        }
    } else {
        set file_name $DIFF_FILES(merge$ind)
    }

    set merge_idx $DIFF_TYPE
    if { $DIFF_TYPE == 3  &&  $MERGE_START != $DIFF_TYPE } {
        set merge_idx [ expr { $DIFF_TYPE - $MERGE_START + $ind } ]
    }

    set dir_name [ file dirname $file_name ]
    if ![ file exists $dir_name ] {
        file mkdir $dir_name
    }
    if ![ file isdirectory $dir_name ] {
        return -code error "Specified directory <$dir_name> is not a directory."
    }

    set bkp_errcode 0
    if { $backup && [ file exists $file_name ] && [ file isfile $file_name ] } {
        set bkp_errcode [ catch { file copy -force $file_name $file_name.$OPTIONS(merge_bkp_suffix) } bkp_errmsg ]
    }

    set saved [ ::Yadt::Save_Merged_Widget_Content_To_File $merge_idx $file_name ]

    if { $saved } {
        set DIFF_FILES(merge$ind) $file_name
        ::Yadt::Update_Merge_Title $merge_idx
        $MERGE_TEXT_WDG($merge_idx) edit modified 0
    }

    if { $bkp_errcode } {
        tk_messageBox \
            -message "Failed to save backup for '$file_name':\n$bkp_errmsg" \
            -type ok \
            -icon warning \
            -title Warning
    }

    return $saved
}

#===============================================================================

proc ::Yadt::Save_Merged_Widget_Content_To_File { merge_idx file_name } {

    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::DIFF2
    variable ::Yadt::DIFF_INT
    variable ::Yadt::TEXT_NUM_WDG
    variable ::Yadt::MERGE_TEXT_WDG
    variable ::Yadt::WIDGETS
    variable ::Yadt::NO_NEWLINE_WARNING
    variable ::Yadt::NOLF

    if { $NOLF(global) } {

        # variable last_merged_method shows which merge method is
        # applied to the last diff. If the last diff does not envolve
        # the last file line this variable equals 0
        set last_merged_method 0
        set confirm 1

        switch -- $DIFF_TYPE {
            2 {
                set diff_id [ llength $DIFF2(diff) ]
            }
            3 {
                set diff_id [ ::YadtDiff3::Get_Diff_Num ]
            }
        }

        # getting last diff files lines
        for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
            set cnt($i) [ ::Yadt::Get_Diff_Id_Content $diff_id $i ]
            # removing no newline mark if any
            if { $NOLF($i) } {
                set cnt($i) [ string range $cnt($i) \
                                  0 [ expr [ string length $cnt($i) ] - [ string length $NO_NEWLINE_WARNING ] - 1 ] ]
            }
        }

        switch -- $DIFF_TYPE {
            2 {
                lassign [ ::Yadt::Get_Pdiff_For_Diff_Id $diff_id ] thisdiff s(1) e(1) s(2) e(2) type

                set num_end(1) [ $TEXT_NUM_WDG(1) get end-2lines end-1lines-1char ]
                set num_end(2) [ $TEXT_NUM_WDG(2) get end-2lines end-1lines-1char ]

                if { $num_end(1) == $e(1) || $num_end(2) == $e(2) } {
                    # last diff envolves last line
                    set last_merged_method $::Yadt::DIFF_INT(normal_merge$diff_id)
                }

                # detecting whether we need a confirmation from user about LF type save
                if { $NOLF(1) == $NOLF(2) || $last_merged_method == 0 || ( $last_merged_method != -1 && $cnt(1) == $cnt(2) ) } {
                    set confirm 0
                }
            }
            3 {
                for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
                    lassign [ ::Yadt::Get_Pdiff_For_Diff_Id $diff_id -file_id $i ] \
                        thisdiff($i) s($i) e($i) type($i)
                    set num_end($i) [ $TEXT_NUM_WDG($i) get end-2lines end-1lines-1char ]
                }

                if { $num_end(1) == $e(1) || $num_end(2) == $e(2) || $num_end(3) == $e(3) } {
                    # last diff envolves last line
                    set last_merged_method $::Yadt::DIFF_INT(normal_merge$diff_id,$merge_idx)
                }

                # detecting whether we need a confirmation from user about LF type save
                if { ( $NOLF(1) == $NOLF(2) && $NOLF(1) == $NOLF(3) ) || \
                         $last_merged_method == 0 || \
                         ( $last_merged_method != -1 && $cnt(1) == $cnt(2) && $cnt(1) == $cnt(3) ) } {
                    set confirm 0
                }
            }
        }

        if { $last_merged_method != -1 && $last_merged_method != 0 } {
            # finding which file adds the last line in a merged file
            set last_merged_method [ lindex [ split $last_merged_method {} ] end ]                    
        }

        set answer "yes"
        if { $confirm } {
            set answer [ tk_messageBox \
                             -message "You have files with different LF at the end.\
                                       Should YaDT add new line at the end of a merged file?" \
                             -type yesnocancel \
                             -icon question \
                             -default yes \
                             -title "Attention!" \
                             -parent $WIDGETS(window_name) ]
        }
                
        if { $answer == "cancel" } {
            return 0
        }

        # Getting merged widget content.
        # Note: NOLF(global) == 1 - means that at least one file has NOLF at the end
        # 1. if last_merged_method == 0 - last diff doesn't envolve last line
        #                               - all files has no LF at the end
        #                               - merge widget has nonewline mark at the end
        # 2. if last_merged_method == -1 - means that last diff envolves last line and 
        #                                 at least one file has NOLF at the end.
        #                                 User should be asked how to save a merged file: with LF or not.
        # 3. if last_merged_method != -1 - means that the last diff envolves last line and
        #    and NOLF($last_merged_method) == 1 - means the last line has nonewline mark at the end - 
        #                                 get content the way as in p.1.
        #    and NOLF($last_merged_method) == 0 -means  the last line has NO nonewline mark at the end -
        #                                 get content normally
        # 4. NOLF(global) == 0 means all files have LF at the end - take content normally.

        if { $last_merged_method == 0 || ($last_merged_method != -1 && $NOLF($last_merged_method) ) } {
            set content [ $MERGE_TEXT_WDG($merge_idx) get 1.0 end-1lines-1char-[ string length $NO_NEWLINE_WARNING ]char ]
        } elseif { $answer == "no" } {
            set content [ $MERGE_TEXT_WDG($merge_idx) get 1.0 end-2char ]
        } else {
            set content [ $MERGE_TEXT_WDG($merge_idx) get 1.0 end-1lines ]
        }
    } else {
        set content [ $MERGE_TEXT_WDG($merge_idx) get 1.0 end-1lines ]
    }

    set f_handle [ open "$file_name" w ]
    puts -nonewline $f_handle $content
    close $f_handle

    return 1
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
    variable ::Yadt::DIFF_INT
    variable ::Yadt::OPTIONS
    variable ::Yadt::TMP_OPTIONS

    $WIDGETS(tool_bar).ignore_blanks configure -state disabled
    ::Yadt::Start_New_Diff_Wrapper
    $WIDGETS(tool_bar).ignore_blanks configure -state normal

    ::Yadt::Set_Diff_Indicator $DIFF_INT(pos) 0 1

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
    ::Yadt::Set_Diff_Combo_Values
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

    ::Yadt::Update_Widgets

    if { $OPTIONS(automerge) } {
        ::Yadt::Auto_Merge3
    }
    ::Yadt::Focus_Active_Window
}

#===============================================================================

proc ::Yadt::Do_Diff {} {

    ::Yadt::Exec_Diff
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
                set DIFF2(diff) [ ::Yadt::CVS_Diff ]
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

    if { !$OPTIONS(use_diff) } {
        # Even in case we do not have diff, we can compare files manually
        # Although, in some cases performance is not good, see
        # ::struct::list::LlongestCommonSubsequence2 description for details
        return [ ::YadtLcs::Compare2 $id1 $id2 $OPTIONS(ignore_blanks) lcsdata ]
    }

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

    set diffs [ ::YadtDiff2::Analyze_Out_Diff2 $diff_stdout -diff ]

    if { $DIFF_TYPE == 2 } {
        return $diffs
    }

    ::Yadt::Get_File_Strings $id1 $id2

    set len($id1) [ llength $DIFF_FILES(strings,$id1) ]
    set len($id2) [ llength $DIFF_FILES(strings,$id2) ]

    set lcsdata [ ::YadtLcs::Convert_Diff2_To_Lcs_Data $diffs $id1 $id2 $len($id1) $len($id2) ]

    while {1} {
        set test_lcsdata [ ::YadtLcs::Try_To_Split_Diffs_Having_Lcs \
                               $diffs $id1 $id2 $lcsdata \
                               $DIFF_FILES(strings,$id1) $DIFF_FILES(strings,$id2) ]
        if { $test_lcsdata == $lcsdata } break
        set lcsdata $test_lcsdata
        set diffs [ ::YadtLcs::Convert_Lcs_Data_To_Diff2 $lcsdata $len($id1) $len($id2) ]
    }

    return $diffs
}

#===============================================================================

proc ::Yadt::Exec_Diff3 {} {

    variable ::Yadt::LCSDATA

    ::Yadt::Status_Msg menustatus "Comparing A vs B ..."
    update
    ::Yadt::Exec_Diff2 1 2 LCSDATA(12)
    ::Yadt::Status_Msg menustatus "Comparing A vs C ..."
    update
    ::Yadt::Exec_Diff2 1 3 LCSDATA(13)
    ::Yadt::Status_Msg menustatus "Comparing B vs C ..."
    update
    ::Yadt::Exec_Diff2 2 3 LCSDATA(23)

    ::Yadt::Status_Msg menustatus "Consolidating found differences ..."
    update
    set LCSDATA(unchanged) [ ::YadtLcs::Find_Unchanged_Diff3_Lines_From_Lcs_Data LCSDATA ]
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

    ::YadtCvs::Ignore_No_CVS_Tag_Error stderr

    if { $exitcode < 0 || $exitcode > 1 || [ regexp "diff aborted" $stderr ] } {
        return -code error "Diff-utility failed:\nExitcode: <$exitcode>\nError message: <$stderr>"
    }

    set diffs [ ::YadtDiff2::Analyze_Out_Diff2 $diff_stdout -cvs -filename $DIFF_FILES(filename,1) ]

    return $diffs
}

#===============================================================================

proc ::Yadt::Update_Num_Lines {} {

    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::TEXT_WDG
    variable ::Yadt::TEXT_NUM_WDG
    variable ::Yadt::TEXT_INFO_WDG

    set min_num 0

    set endline end-1lines

    for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
        set lines_num($i) [ lindex [ split [ $TEXT_WDG($i) index $endline ] . ] 0 ]
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

proc ::Yadt::Collect_Diff3_From_Lcs { prev_idx_arr idx_arr diff_count warn } {

    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::DIFF_INT

    upvar $prev_idx_arr prev_idx
    upvar $idx_arr idx
    upvar $diff_count count
    upvar $warn warning

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

        ::YadtDiff3::Set_Part_Diff3_For_Diff_Id $count $i $ds($i)$op($i)
        set DIFF_INT($count,$i,pdiff) \
            [ ::YadtDiff3::Analyze_Diff3 $count $i $ds($i)$op($i) ]
    }

    ::YadtDiff3::Set_Which_File_For_Diff_Id $count [ ::YadtDiff3::Find_Which_File_For_Diff_Id $count warning ]
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

proc ::Yadt::Gather_File_Strings_By_Diff_Id { diff_id file_num { lastlf "" }} {

    variable ::Yadt::DIFF_FILES
    variable ::Yadt::DIFF_INT
    variable ::Yadt::NOLF

    if { $lastlf != "" } {
        upvar $lastlf lf
    }

    foreach [ list thisdiff($file_num) s($file_num) e($file_num) type($file_num) ] \
        $DIFF_INT($diff_id,$file_num,pdiff) { }

    if { $e($file_num) == [ llength $DIFF_FILES(strings,$file_num) ] } {
        set lf $NOLF($file_num)
    }

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

proc ::Yadt::Diff_Size { diff_id method args } {

    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::OPTIONS

    set for_diff_id [ ::CmnTools::Get_Arg -for_diff_id args -default 0 ]

    switch -- $DIFF_TYPE {
        2 {
            return [ ::Yadt::Diff2_Size $diff_id $method ]
        }
        3 {
            if { $OPTIONS(merge_mode) == "normal" || $for_diff_id } {
                return [ ::Yadt::Diff3_Size $diff_id $method ]
            }
            return [ ::Yadt::Range3_Size $diff_id $method ]
        }
    }
}

#===============================================================================

proc ::Yadt::Diff2_Size { diff_id method } {

    lassign [ ::Yadt::Get_Pdiff_For_Diff_Id $diff_id ] thisdiff s(1) e(1) s(2) e(2) type

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

    variable ::Yadt::DIFF_TYPE

    for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
        lassign [ ::Yadt::Get_Pdiff_For_Diff_Id $diff_id -file_id $i ] \
            thisdiff($i) s($i) e($i) type($i)
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

    lassign [ ::YadtDiff3::Get_Range $diff_id ] start end type

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
    variable ::Yadt::NO_NEWLINE_WARNING
    variable ::Yadt::NOLF

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

    lassign [ ::Yadt::Get_Diff_Scr_Params $diff_id ] start end type

    for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
        set new_lines($i) 0
    }

    set newlines 0
    set newtext ""

    set method_len [ string length $new_method ]
    set m_num 0

    set nolf 0

    foreach i [ split $new_method {} ] {
        incr m_num

        set new_lines($i) [ ::Yadt::Diff_Size $diff_id $i ]
        incr newlines $new_lines($i)

        # Here we also consider different LF in compared files
        if { $NOLF(global) && [ ::Yadt::Is_Last_Line_Envolved $diff_id $i ] && $NOLF($i) } {
            set add_text [ $TEXT_WDG($i) get $start.0 $start.0+$new_lines($i)lines-[ string length $NO_NEWLINE_WARNING ]char-1char ]
            if { $m_num == $method_len } {
                append add_text $NO_NEWLINE_WARNING
                set nolf 1
            }
            append add_text \n
        } else {
            set add_text [ $TEXT_WDG($i) get $start.0 $start.0+$new_lines($i)lines ]
        }
        append newtext $add_text
    }

    set info_lines {}

    for { set i 1 } { $i <= $newlines } { incr i } {
        append info_lines " \n"
    }

    $MERGE_TEXT_WDG(2) insert mark${diff_id} $newtext diff
    ::Yadt::Enable_Merge_Info_Wdg
    $MERGE_INFO_WDG(2) insert mark${diff_id} $info_lines diff
    ::Yadt::Disable_Merge_Info_Wdg

    if { $nolf } {
        set start [ $MERGE_TEXT_WDG(2) index end-1lines-1char-[ string length $NO_NEWLINE_WARNING ]char  ]
        set end [ $MERGE_TEXT_WDG(2) index "end-1lines-1char-[ string length $NO_NEWLINE_WARNING ]char lineend" ]
        $MERGE_TEXT_WDG(2) tag add lftag $start $end
    }
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

proc ::Yadt::Count_Diff_Id_Merged_Lines { diff_id target } {

    variable ::Yadt::DIFF_INT

    set lines 0

    switch -- $DIFF_INT(method$diff_id,$target) {
        normal {
            set method $DIFF_INT(normal_merge$diff_id,$target)
            set lines [ ::Yadt::Diff3_Size $diff_id $method ]
        }
        expert {
            foreach range [ ::YadtDiff3::Get_Ranges_For_Diff_Id $diff_id ] {
                incr lines [ ::Yadt::Count_Range_Id_Merged_Lines $range $target ]
            }
        }
    }

    return $lines
}

#===============================================================================

proc ::Yadt::Count_Range_Id_Merged_Lines { range_id target } {

    variable ::Yadt::DIFF_INT

    set lines 0

    set method $DIFF_INT(expert_merge$range_id,$target)
    if { $method != -1 } {
        foreach i [ split $method {} ] {
            incr lines [ ::Yadt::Range3_Size $range_id $i ]
        }
    }

    return $lines
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
    variable ::Yadt::NO_NEWLINE_WARNING
    variable ::Yadt::NOLF

    set diff_id [ ::CmnTools::Get_Arg -pos  args -default $DIFF_INT(pos) ]
    set mark [ ::CmnTools::Get_Arg -mark args -default 1 ]

    ::Yadt::Enable_Merge_Info_Wdg

    # Delete lines for oldmethod if any
    set oldlines [::Yadt::Count_Diff_Id_Merged_Lines $diff_id $target ]

    if { $oldlines > 0 } {
        $MERGE_INFO_WDG($target) delete mark${target}_$diff_id \
            "mark${target}_$diff_id+${oldlines}lines"
        $MERGE_TEXT_WDG($target) delete mark${target}_$diff_id \
            "mark${target}_$diff_id+${oldlines}lines"
    }

    # reset ranges method
    foreach range [ ::YadtDiff3::Get_Ranges_For_Diff_Id $diff_id ] {
        set DIFF_INT(expert_merge$range,$target) $new_method
    }

    if { $new_method == -1 } {
        # No lines to add
        return
    }

    lassign [ ::Yadt::Get_Diff_Scr_Params $diff_id ] start end type
    if { $start == -1 && $end == -1 && $type == -1 } return

    # Add lines for new method
    for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
        set new_lines($i) 0
    }

    set newlines 0
    set newtext ""

    set method_len [ string length $new_method ]
    set m_num 0
    set nolf($target) 0

    foreach i [ split $new_method {} ] {
        incr m_num
        set addtext ""
        for { set j $start } { $j <= $end } { incr j } {
            set f_line($i) [ $TEXT_NUM_WDG($i) get $j.0 $j.end ]
            if { $f_line($i) == "" } continue

            # Here we also consider different LF in compared files
            set last [ ::Yadt::Is_Last_Line_Envolved $diff_id $i last_line($i) ]
            if { $NOLF(global) && $NOLF($i) && $last && $last_line($i) == $f_line($i) } {
                set add_text [ $TEXT_WDG($i) get $j.0 $j.0+1lines-[ string length $NO_NEWLINE_WARNING ]char-1char ]
                if { $m_num == $method_len } {
                    append add_text $NO_NEWLINE_WARNING
                    set nolf($target) 1
                }
                append add_text \n
            } else {
                set add_text [ $TEXT_WDG($i) get $j.0 $j.0+1lines ]
            }
            append addtext $add_text
        }

        set new_lines($i) [ ::Yadt::Diff_Size $diff_id $i ]
        incr newlines $new_lines($i)

        append newtext $addtext
    }

    set info_lines {}

    for { set i 1 } { $i <= $newlines } { incr i } {
        append info_lines " \n"
    }

    # Actually inserting newtext in merge widget
    $MERGE_TEXT_WDG($target) insert mark${target}_$diff_id $newtext diff
    $MERGE_INFO_WDG($target) insert mark${target}_$diff_id $info_lines diff

    if { $nolf($target) } {
        set start [ $MERGE_TEXT_WDG($target) index end-1lines-1char-[ string length $NO_NEWLINE_WARNING ]char  ]
        set end [ $MERGE_TEXT_WDG($target) index "end-1lines-1char-[ string length $NO_NEWLINE_WARNING ]char lineend" ]
        $MERGE_TEXT_WDG($target) tag add lftag $start $end
    }
    update

    set DIFF_INT(method$diff_id,$target) normal

    # Coloring merge preview
    ::Yadt::Color_Merge_Tag $diff_id $target $new_method $new_lines(1) $new_lines(2) $new_lines(3)

    if { $mark } {
        $MERGE_INFO_WDG($target) tag add \
            currtag mark${target}_$diff_id \
            "mark${target}_$diff_id+${newlines}lines"
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
    variable ::Yadt::NO_NEWLINE_WARNING
    variable ::Yadt::NOLF

    set diff_id [ ::CmnTools::Get_Arg -pos  args -default $DIFF_INT(pos) ]
    set r_id [ ::YadtDiff3::Get_Diff_Id_For_Range $diff_id ]
    set mark [ ::CmnTools::Get_Arg -mark args -default 1 ]

    ::Yadt::Enable_Merge_Info_Wdg

    # Clean lines at first if we have to
    set oldlines [::Yadt::Count_Diff_Id_Merged_Lines $r_id $target ]

    if { $oldlines > 0 } {
        $MERGE_INFO_WDG($target) delete mark${target}_$r_id \
            "mark${target}_$r_id+${oldlines}lines"

        $MERGE_TEXT_WDG($target) delete mark${target}_$r_id \
            "mark${target}_$r_id+${oldlines}lines"
    }

    lassign [ ::Yadt::Get_Diff_Scr_Params $diff_id ] start end type
    if { $start == -1 && $end == -1 && $type == -1 } return

    set newlines 0
    set newtext ""
    set nolf($target) 0
    set add_nolf_warn 0

    foreach range [ ::YadtDiff3::Get_Ranges_For_Diff_Id $r_id ] {
        lassign [ ::YadtDiff3::Get_Range $range ] r_start r_end r_type

        set method $DIFF_INT(expert_merge$range,$target)
        if { $r_start == $start && $r_end == $end } {
            set method $new_method
        }

        if { $method == -1 } continue

        set method_len [ string length $method ]
        set m_num 0

        foreach i [ split $method {} ] {

            incr m_num

            incr newlines [ ::Yadt::Diff_Size $range $i ]

            set addtext ""
            for { set j $r_start } { $j <= $r_end } { incr j } {
                set f_line($i) [ $TEXT_NUM_WDG($i) get $j.0 $j.end ]
                if { $f_line($i) == "" } continue

                # Here we also consider different LF in compared files
                set last [ ::Yadt::Is_Last_Line_Envolved $r_id $i last_line($i) ]
                if { $NOLF(global) && $NOLF($i) && $last && $last_line($i) == $f_line($i) } {
                    set add_text [ $TEXT_WDG($i) get $j.0 $j.0+1lines-[ string length $NO_NEWLINE_WARNING ]char-1char ]
                    if { $m_num == $method_len } {
                        if { $nolf($target) == 0 } {
                            set add_nolf_warn 1
                            set nolf($target) 1
                        }
                    }
                    append add_text \n
                } else {
                    set add_text [ $TEXT_WDG($i) get $j.0 $j.0+1lines ]
                }
                append addtext $add_text
            }

            append newtext $addtext
        }
    }

    if { $add_nolf_warn } {
        set newtext [ string trimright $newtext ]
        append newtext $NO_NEWLINE_WARNING\n
    }

    set info_lines {}
    for { set i 1 } { $i <= $newlines } { incr i } {
        append info_lines " \n"
    }

    # Actually inserting newtext in merge widget
    $MERGE_TEXT_WDG($target) insert mark${target}_$r_id $newtext diff
    $MERGE_INFO_WDG($target) insert mark${target}_$r_id $info_lines diff
    if { $nolf($target) } {
        set start [ $MERGE_TEXT_WDG($target) index end-1lines-1char-[ string length $NO_NEWLINE_WARNING ]char  ]
        set end [ $MERGE_TEXT_WDG($target) index "end-1lines-1char-[ string length $NO_NEWLINE_WARNING ]char lineend" ]
        $MERGE_TEXT_WDG($target) tag add lftag $start $end
    }
    update

    set DIFF_INT(method$r_id,$target) expert

    # Coloring merge preview
    ::Yadt::Color_Range_Tags_Inside_Diff $target $diff_id $new_method

    if { $mark } {
        set range_size [ ::Yadt::Diff_Size $diff_id $new_method ]
        set offset [ ::Yadt::Get_Range_Offset_Inside_Diff $diff_id $target ]

        set m_start "mark${target}_$r_id+${offset}lines"
        set m_end "mark${target}_$r_id+${offset}lines+${range_size}lines"

        $MERGE_INFO_WDG($target) tag add currtag $m_start $m_end
        if { $OPTIONS(merge_mode) == "expert" } {
            $MERGE_INFO_WDG($target) tag add textcurrtag $m_start $m_end
            $MERGE_TEXT_WDG($target) tag add textcurrtag $m_start $m_end
        }
    }
    ::Yadt::Disable_Merge_Info_Wdg
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

    variable ::Yadt::DIFF_INT
    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::MERGE_START
    variable ::Yadt::MERGE_TEXT_WDG

    lassign [ ::Yadt::Get_Diff_Scr_Params $range ] start end type

    set diff_id [ ::YadtDiff3::Get_Diff_Id_For_Range $range ]

    for { set j $MERGE_START } { $j <= $DIFF_TYPE } { incr j } {
        set offset($j) 0
    }

    foreach r [ ::YadtDiff3::Get_Ranges_For_Diff_Id $diff_id ] {
        array unset lines

        lassign [ ::YadtDiff3::Get_Range $r ] r_start r_end r_type

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

    variable ::Yadt::DIFF_INT
    variable ::Yadt::OPTIONS

    switch -- $OPTIONS(merge_mode) {
        normal {
            set num_diff [ ::YadtDiff3::Get_Diff_Num ]
        }
        expert {
            set num_diff [ ::YadtDiff3::Get_Ranges_Num ]
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

    ::YadtPaned::Paned -configure $WIDGETS(diff_paned) -orient $orient

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

    array unset current_merges

    set num_diff [ llength $DIFF2(diff) ]

    for { set i 1 } { $i <= $num_diff } { incr i } {
        set current_merges(merge$i) $DIFF_INT(normal_merge$i)
    }

    return [ array get current_merges ]
}

#===============================================================================

proc ::Yadt::Save_Current_Merges3 {} {

    variable ::Yadt::DIFF_INT
    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::MERGE_START
    variable ::Yadt::OPTIONS

    array unset current_merges

    switch -- $OPTIONS(merge_mode) {
        normal {
            set num_diff [ ::YadtDiff3::Get_Diff_Num ]
        }
        expert {
            set num_diff [ ::YadtDiff3::Get_Ranges_Num ]
        }
    }

    for { set i 1 } { $i <= $num_diff } { incr i } {

        for { set j $MERGE_START } { $j <= $DIFF_TYPE } { incr j } {
            set current_merges(merge$i,$j) $DIFF_INT($OPTIONS(merge_mode)_merge$i,$j)
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

    if { $type == "-current" } {
        $WIDGETS(mark$target) configure -image $new_image
    }

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

    variable ::Yadt::DIFF_INT
    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::MERGE_START
    variable ::Yadt::OPTIONS

    switch -- $OPTIONS(merge_mode) {
        normal {
            set num_diff [ ::YadtDiff3::Get_Diff_Num ]
        }
        expert {
            set num_diff [ ::YadtDiff3::Get_Ranges_Num ]
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
                    set diff_id [ ::YadtDiff3::Get_Diff_Id_For_Range $diff_id ]
                }
                if [ ::YadtDiff3::Get_Which_File_For_Diff_Id $diff_id ] continue
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

    variable ::Yadt::DIFF_INT
    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::MERGE_START
    variable ::Yadt::OPTIONS

    set pos $diff_id
    if { $OPTIONS(merge_mode) == "expert" } {
        set pos [ ::YadtDiff3::Get_Diff_Id_For_Range $diff_id ]
    }

    switch -- [ ::YadtDiff3::Get_Which_File_For_Diff_Id $pos ] {
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
            return -code error "Internal error: Invalid DIFF3 format found: <[ ::YadtDiff3::Get_Which_File_For_Diff_Id $diff_id ]>"
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
    variable ::Yadt::DIFF_INT
    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::MERGE_START
    variable ::Yadt::OPTIONS

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
                set num_diff [ ::YadtDiff3::Get_Diff_Num ]
            }
            expert {
                set num_diff [ ::YadtDiff3::Get_Ranges_Num ]
            }
        }
    }

    if { $num_diff == 0 } {
        return $resolved
    }

    for { set i 1 } { $i <= $num_diff } { incr i } {

        set diff_id $i
        if { $OPTIONS(merge_mode) == "expert" } {
            set diff_id [ ::YadtDiff3::Get_Diff_Id_For_Range $diff_id ]
        }

        if { $target == "all" } {
            for { set j $MERGE_START } { $j <= $DIFF_TYPE } { incr j } {
                if { $type == "-confl" && [ ::YadtDiff3::Get_Which_File_For_Diff_Id $diff_id ] } {
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
            if { $type == "-confl" && [ ::YadtDiff3::Get_Which_File_For_Diff_Id $diff_id ] } {
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
            set num_diff [ ::YadtDiff3::Get_Diff_Num ]
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

    variable ::Yadt::DIFF_INT
    variable ::Yadt::OPTIONS
    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::MERGE_START
    variable ::Yadt::WIDGETS

    if { $DIFF_TYPE != 3 } return

    switch -- $OPTIONS(merge_mode) {
        normal {
            set num_diff [ ::YadtDiff3::Get_Diff_Num ]
            set units "Differences"
        }
        expert {
            set num_diff [ ::YadtDiff3::Get_Ranges_Num ]
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
        $TEXT_WDG($i) tag delete {*}[ $TEXT_WDG($i) tag names ]
        $TEXT_NUM_WDG($i) tag delete {*}[ $TEXT_NUM_WDG($i) tag names ]
        $TEXT_INFO_WDG($i) tag delete {*}[ $TEXT_INFO_WDG($i) tag names ]
    }
}

#===============================================================================

proc ::Yadt::Prepare_Mark_Diffs {} {

    variable ::Yadt::OPTIONS
    variable ::Yadt::WIDGETS
    variable ::Yadt::MAP_COLOR

    foreach tag { currtag textcurrtag difftag deltag instag inlinetag inlineinstag inlinechgtag chgtag overlaptag sel lftag } {
        foreach win [ concat [ ::Yadt::Get_Diff_Wdg_List ] $WIDGETS(diff_lines_text) ] {
            $win tag configure $tag {*}$OPTIONS($tag)
        }
    }
    $WIDGETS(diff_lines_files) tag configure sel {*}$OPTIONS(sel)
}

#===============================================================================

proc ::Yadt::Add_Lines {} {

    variable ::Yadt::DIFF2
    variable ::Yadt::DIFF_INT
    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::WIDGETS
    variable ::Yadt::LCSDATA
    variable ::Yadt::DIFF_FILES
    variable ::Yadt::WDG_OPTIONS

    set combo_values {}
    set combo_width 10

    switch -- $DIFF_TYPE {

        2 {
            set num_diff [ llength $DIFF2(diff) ]
            set DIFF_INT(count) 0

            foreach diff $DIFF2(diff) {
                set result [ ::YadtDiff2::Analyze_Diff2 $diff ]

                if { $result != "" } {
                    incr DIFF_INT(count)
                    set DIFF_INT($DIFF_INT(count),pdiff) "$result"
                    ::YadtDiff2::Align_One_Diff2 $DIFF_INT(count)
                    set combo_value [ format "%-6d: %s" $DIFF_INT(count) $diff ]
                    lappend combo_values $combo_value
                    set combo_width [ ::CmnTools::MaxN $combo_width [ string length $combo_value ] ]
                }
            }
            set diff_num $DIFF_INT(count)
        }

        3 {
            set warn {}
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

                ::Yadt::Collect_Diff3_From_Lcs prev_idx idx count warn
                set prev_idx(1) $idx(1)
                set prev_idx(2) $idx(2)
                set prev_idx(3) $idx(3)
            }

            # Last diff, if any
            for { set j 1 } { $j <= $DIFF_TYPE } { incr j } {
                set prev_idx($j) $idx($j)
                set idx($j) [ llength $DIFF_FILES(strings,$j) ]
            }
            ::Yadt::Collect_Diff3_From_Lcs prev_idx idx count warn

            set num_diff [ ::YadtDiff3::Get_Diff_Num ]
            set DIFF_INT(count) 0

            ::YadtDiff3::Add_Diff3_Info_Strings

            ::Yadt::Status_Msg menustatus "Analyzing differences ..."

            set every [ ::Yadt::Get_Diff_Update_Period $num_diff ]

            set tk_wndsys [ tk windowingsystem ]

            for { set i 1 } { $i <= $num_diff } { incr i } {
                set show 0
                if { $every > 1 } {
                    if { [ expr $i % $every ] == 0 } {
                        set show 1
                        if { $tk_wndsys != "aqua" } {
                            update
                        }
                    }
                }
                
                incr DIFF_INT(count)
                ::Yadt::Status_Msg menustatus "Analyzing difference $i of $num_diff ..." $show
                ::YadtDiff3::Align_One_Diff3 $i
                set combo_value [ format "%-6d: %s: %s: %s" \
                                      $DIFF_INT(count) \
                                      [ ::YadtDiff3::Get_Part_Diff3_For_Diff_Id $i 1 ] \
                                      [ ::YadtDiff3::Get_Part_Diff3_For_Diff_Id $i 2 ] \
                                      [ ::YadtDiff3::Get_Part_Diff3_For_Diff_Id $i 3 ] ]
                lappend combo_values $combo_value
                set combo_width [ ::CmnTools::MaxN $combo_width [ string length $combo_value ] ]
            }

            ::Yadt::Status_Msg menustatus "Analyzing differences ...Done"

            for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
                set len($i) [ llength $DIFF_FILES(strings,$i) ]
            }
            for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
                set fnum($i) [ expr $len($i) + [ ::Yadt::Get_Current_Delta $i ] ]
            }

            ::Yadt::Status_Msg menustatus "Append final lines ..."
            ::YadtDiff3::Append_Final_Lcs_Lines fnum

            set diff_num $DIFF_INT(count)

            if [ llength $warn ] {
                ::Yadt::Msg_Box "Warning" \
                    "There was an error processing differences:\
                    \n[ join $warn \n ]" \
                    "ok" \
                    "warning"
            }
        }
    }

    set WDG_OPTIONS(diffs_combo_values) $combo_values
    if { $DIFF_TYPE == 3 } {
        ::Yadt::Status_Msg menustatus "Creating ranges indexes ..."
        set WDG_OPTIONS(ranges_combo_values) [ ::YadtDiff3::Create_Combo_Values_Based_On_Ranges ]
    }

    ::Yadt::Set_Diff_Combo_Values -width $combo_width

    return $diff_num
}

#===============================================================================

proc ::Yadt::Get_Diff_Update_Period { num_diff } {

    set every 1

    if { $num_diff > 20000 } {
        return 1000
    }
    if { $num_diff <= 20000 && $num_diff > 10000 } {
        return 500
    }
    if { $num_diff <= 10000 && $num_diff > 5000 } {
        return 200
    }

    if { $num_diff <= 5000 && $num_diff > 1000 } {
        return 100
    }

    if { $num_diff <= 1000 && $num_diff > 100 } {
        return 50
    }

    return 1
}

#===============================================================================

proc ::Yadt::Set_Diff_Combo_Values { args } {

    variable ::Yadt::WIDGETS
    variable ::Yadt::OPTIONS
    variable ::Yadt::WDG_OPTIONS
    variable ::Yadt::DIFF_TYPE

    set width [ ::CmnTools::Get_Arg -width args -default "" ]

    if { $width != "" } {
        $WIDGETS(diff_combo) configure -width $width
    }

    switch -- $DIFF_TYPE {
        2 {
            set values $WDG_OPTIONS(diffs_combo_values)
        }
        3 {
            switch -- $OPTIONS(merge_mode) {
                normal {
                    set values $WDG_OPTIONS(diffs_combo_values)
                }
                expert {
                    set values $WDG_OPTIONS(ranges_combo_values)
                }
            }
        }
    }

    $WIDGETS(diff_combo) configure -values $values
    $WIDGETS(diff_combo) set ""
}

#===============================================================================

proc ::Yadt::Update_Merge_Marks {} {

    variable ::Yadt::DIFF2
    variable ::Yadt::DIFF_INT
    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::MERGE_START
    variable ::Yadt::MERGE_TEXT_WDG
    variable ::Yadt::MERGE_INFO_WDG
    variable ::Yadt::OPTIONS

    for { set i $MERGE_START } { $i <= $DIFF_TYPE } { incr i } {
        $MERGE_TEXT_WDG($i) tag delete {*}[ $MERGE_TEXT_WDG($i) tag names ]
        $MERGE_INFO_WDG($i) tag delete {*}[ $MERGE_INFO_WDG($i) tag names ]
    }

    foreach tag { merge1tag merge2tag merge3tag textcurrtag sel lftag } {
        foreach win [ ::Yadt::Get_Merge_Wdg_List ] {
            $win tag configure $tag {*}$OPTIONS($tag)
        }
    }

    foreach tag { currtag } {
        foreach win [ ::Yadt::Get_Merge_Wdg_List 0 "info" ] {
            $win tag configure $tag {*}$OPTIONS($tag)
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
            set num_diff [ ::YadtDiff3::Get_Ranges_Num ]
            for { set i 1 } { $i <= $num_diff } { incr i } {
                for { set j $MERGE_START } { $j <= $DIFF_TYPE } { incr j } {
                    set DIFF_INT(method$i,$j) $OPTIONS(merge_mode)
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

    set num_diff [ ::YadtDiff3::Get_Diff_Num ]
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
    variable ::Yadt::MERGE_START
    variable ::Yadt::DIFF2
    variable ::Yadt::OPTIONS
    variable ::Yadt::TEXT_WDG
    variable ::Yadt::TEXT_NUM_WDG
    variable ::Yadt::MERGE_TEXT_WDG
    variable ::Yadt::NO_NEWLINE_WARNING
    variable ::Yadt::NOLF

    switch -- $DIFF_TYPE {
        2 {
            set num_diff [ llength $DIFF2(diff) ]
        }
        3 {
            switch -- $OPTIONS(merge_mode) {
                normal {
                    set num_diff [ ::YadtDiff3::Get_Diff_Num ]
                }
                expert {
                    set num_diff [ ::YadtDiff3::Get_Ranges_Num ]
                }
            }
        }
    }

    for { set i 1 } { $i <= $num_diff } { incr i } {
        ::Yadt::Set_Tag $i difftag
    }

    ::Yadt::Toggle_Inline_Tags

    if { $NOLF(global) } {
        for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
            if { $NOLF($i) } {
                set num_cnt($i) [ $TEXT_NUM_WDG($i) get 1.0 end ]
                set num_end($i) [ lindex [ string trim $num_cnt($i) ] end ]

                set line [ expr [ lsearch [ split $num_cnt($i) \n ] $num_end($i) ] + 1 ]
                set start($i)  [ $TEXT_WDG($i) index "$line.0+1line-1char-[ string length $NO_NEWLINE_WARNING ]char" ]
                set end($i) [ $TEXT_WDG($i) index "$start($i) lineend" ]

                $TEXT_WDG($i) tag add lftag $start($i) $end($i)
            }
        }

        for { set j $MERGE_START } { $j <= $DIFF_TYPE } { incr j } {
            set start($j) [ $MERGE_TEXT_WDG($j) index end-1lines-1char-[ string length $NO_NEWLINE_WARNING ]char  ]
            set end($j) [ $MERGE_TEXT_WDG($j) index "end-1lines-1char-[ string length $NO_NEWLINE_WARNING ]char lineend" ]
            $MERGE_TEXT_WDG($j) tag add lftag $start($j) $end($j)
        }
    }
}

#===============================================================================

proc ::Yadt::Toggle_Inline_Tags {} {

    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::DIFF2
    variable ::Yadt::OPTIONS

    ::Yadt::Prepare_Mark_Diffs

    set num_diff [ expr { $DIFF_TYPE == 2 ? \
                              [ llength $DIFF2(diff) ] : \
                              [ ::YadtDiff3::Get_Diff_Num ] } ]

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
    variable ::Yadt::TEXT_NUM_WDG
    variable ::Yadt::TEXT_INFO_WDG
    variable ::Yadt::MERGE_TEXT_WDG
    variable ::Yadt::MERGE_INFO_WDG
    variable ::Yadt::OPTIONS

    if ![ ::Yadt::Get_Diff_Scr_Params $diff_id -exists ] return
    lassign [ ::Yadt::Get_Diff_Scr_Params $diff_id ] start end type

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

    variable ::Yadt::DIFF_INT
    variable ::Yadt::TEXT_NUM_WDG
    variable ::Yadt::TEXT_INFO_WDG
    variable ::Yadt::MERGE_TEXT_WDG
    variable ::Yadt::MERGE_INFO_WDG
    variable ::Yadt::OPTIONS
    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::MERGE_START

    lassign [ ::Yadt::Get_Diff_Scr_Params $diff_id ] start end type
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
            set diff_id [ ::YadtDiff3::Get_Diff_Id_For_Range $diff_id ]
        }
    }

    # Check differences of fragments
    switch -- [ ::YadtDiff3::Get_Which_File_For_Diff_Id $diff_id ] {
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

proc ::Yadt::Current_Tag { action diff_id args } {

    variable ::Yadt::DIFF_INT
    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::MERGE_START
    variable ::Yadt::OPTIONS
    variable ::Yadt::TEXT_WDG
    variable ::Yadt::MERGE_TEXT_WDG

    set setpos      [ ::CmnTools::Get_Arg -setpos args -default 1 ]
    set for_diff_id [ ::CmnTools::Get_Arg -for_diff_id args -default 0 ]

    switch -- $action {
        remove -
        add {}
        default {
            return -code error "Unsupported action <$action>"
        }
    }

    ::Yadt::Current_Text_Tag $action $diff_id -for_diff_id $for_diff_id
    ::Yadt::Current_Merge_Tag $action $diff_id -for_diff_id $for_diff_id

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

proc ::Yadt::Current_Text_Tag { action diff_id args } {

    variable ::Yadt::TEXT_WDG
    variable ::Yadt::TEXT_NUM_WDG
    variable ::Yadt::TEXT_INFO_WDG
    variable ::Yadt::OPTIONS
    variable ::Yadt::DIFF_TYPE

    set for_diff_id [ ::CmnTools::Get_Arg -for_diff_id args -default 0 ]

    lassign [ ::Yadt::Get_Diff_Scr_Params $diff_id -for_diff_id $for_diff_id ] start end type
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

                if { $DIFF_TYPE == 3 && $OPTIONS(merge_mode) == "expert" } {
                    ::Yadt::Add_Tag $TEXT_WDG($i) textcurrtag $start $end
                }

                if { $OPTIONS(taginfo) } {
                    ::Yadt::Add_Tag $TEXT_INFO_WDG($i) currtag $start $end
                    if { $DIFF_TYPE == 3 && $OPTIONS(merge_mode) == "expert" } {
                        ::Yadt::Add_Tag $TEXT_INFO_WDG($i) textcurrtag $start $end
                    }
                }
                if { $OPTIONS(tagln) } {
                    ::Yadt::Add_Tag $TEXT_NUM_WDG($i) currtag $start $end
                    if { $DIFF_TYPE == 3 && $OPTIONS(merge_mode) == "expert" } {
                        ::Yadt::Add_Tag $TEXT_NUM_WDG($i) textcurrtag $start $end
                    }
                }
            }
        }
    }
}

#===============================================================================

proc ::Yadt::Current_Merge_Tag { action diff_id args } {

    variable ::Yadt::DIFF_INT
    variable ::Yadt::MERGE_TEXT_WDG
    variable ::Yadt::MERGE_INFO_WDG
    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::MERGE_START
    variable ::Yadt::OPTIONS

    if { $diff_id == 0 } return

    set for_diff_id [ ::CmnTools::Get_Arg -for_diff_id args -default 0 ]

    set mode $OPTIONS(merge_mode)

    switch -- $DIFF_TYPE {
        2 {
            for { set j $MERGE_START } { $j <= $DIFF_TYPE } { incr j } {
                # If there is no merge window variables DIFF_INT(normal_merge...) do not exist
                if [ info exists DIFF_INT(${mode}_merge$diff_id) ] {
                    set lines [ ::Yadt::Diff_Size $diff_id $DIFF_INT(${mode}_merge${diff_id}) ]
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
                        set lines($j) [ ::Yadt::Count_Diff_Id_Merged_Lines $diff_id $j ]
                    }
                }
                expert {
                    if { $for_diff_id } {
                        set mode normal
                    }
                    for { set j $MERGE_START } { $j <= $DIFF_TYPE } { incr j } {
                        if { $for_diff_id == 0 } {
                            set offset($j) [ ::Yadt::Get_Range_Offset_Inside_Diff $diff_id $j ]
                            set lines($j) [ ::Yadt::Count_Range_Id_Merged_Lines $diff_id $j ]
                        } else {
                            set offset($j) 0
                            set lines($j) [ ::Yadt::Count_Diff_Id_Merged_Lines $diff_id $j ]
                        }
                    }

                    if { $for_diff_id == 0 } {
                        set diff_id [ ::YadtDiff3::Get_Diff_Id_For_Range $diff_id ]
                    }
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

    variable ::Yadt::DIFF_INT

    lassign [ ::Yadt::Get_Diff_Scr_Params $range ] start end type

    set diff_id [ ::YadtDiff3::Get_Diff_Id_For_Range $range ]

    set lines 0

    foreach r [ ::YadtDiff3::Get_Ranges_For_Diff_Id $diff_id ] {

        lassign [ ::YadtDiff3::Get_Range $r ] r_start r_end r_type

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

    if { $num_t1 == "" } {

        if ![ ::Yadt::Get_Yadt_Option align_acc ] {
            if { $num_t2 != "" } {
                set curtag2 instag
            }
            if { $num_t3 != "" } {
                set curtag3 instag
            }
            return
        }

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
            if [ ::YadtDiff3::Get_Which_File_For_Diff_Id $diff_id ] {
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
        $element tag raise lftag
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
        lassign [ split $element "," ] dummy diff_id file_id

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
    $WIDGETS(diff_lines_files) configure {*}$OPTIONS(textopt)
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
    $WIDGETS(diff_lines_text) configure {*}$OPTIONS(textopt)
    pack $WIDGETS(diff_lines_text) -side left -fill both -expand 1

    ::YadtPaned::Paned -create $WIDGETS(main_paned) -orient vertical -opaqueresize 0 -showhandle 0
    ::YadtPaned::Paned -pack $WIDGETS(main_paned) -side top -fill both -expand yes -pady 0 -padx 0
    set WIDGETS(top_wnd) [ ::YadtPaned::Paned -add $WIDGETS(main_paned) top_wnd ]
    set WIDGETS(bottom_wnd) [ ::YadtPaned::Paned -add $WIDGETS(main_paned) bottom_wnd ]

    if { !$OPTIONS(preview_shown) } {
        ::YadtPaned::Paned -hide $WIDGETS(main_paned) $WIDGETS(bottom_wnd)
    }

    ::YadtPaned::Paned -init $WIDGETS(main_paned)

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
    ::YadtPaned::Paned -create $WIDGETS(diff_paned) -orient $orient -opaqueresize 0 -showhandle 0
    ::YadtPaned::Paned -pack $WIDGETS(diff_paned) -side top -fill both -expand yes -pady 0 -padx 0

    bind $WIDGETS(mapCanvas) <ButtonPress-1>   \
        [ list ::Yadt::Handle_Map_Event B1-Press   %y ]
    bind $WIDGETS(mapCanvas) <Button1-Motion>  \
        [ list ::Yadt::Handle_Map_Event B1-Motion  %y ]
    bind $WIDGETS(mapCanvas) <ButtonRelease-1> \
        [ list ::Yadt::Handle_Map_Event B1-Release %y ]

    for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
        
        set p_frame [ ::YadtPaned::Paned -add $WIDGETS(diff_paned) file$i ]

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
        $TEXT_NUM_WDG($i) configure {*}$OPTIONS(textopt)
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
        $TEXT_INFO_WDG($i) configure {*}$OPTIONS(textopt)
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
        $TEXT_WDG($i) configure {*}$OPTIONS(textopt)
        pack $TEXT_WDG($i) -fill both -side left -expand 1
    }

    ::YadtPaned::Paned -init $WIDGETS(diff_paned)

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

    ::YadtPaned::Paned -create $WIDGETS(bottom_wnd).merge_paned -orient horizontal -opaqueresize 0 -showhandle 0
    ::YadtPaned::Paned -pack $WIDGETS(bottom_wnd).merge_paned -side top -fill both -expand yes -pady 0 -padx 0

    for { set i $MERGE_START } { $i <= $DIFF_TYPE } { incr i } {

        set p_frame [ ::YadtPaned::Paned -add $WIDGETS(bottom_wnd).merge_paned fr$i ]

        set title_frame [ frame $p_frame.frame ]
        pack $title_frame -side top -fill x -expand 0

        set WIDGETS(merge_title_$i) [ entry $title_frame.title -justify center -state readonly -relief flat ]

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
        $MERGE_INFO_WDG($i) configure {*}$OPTIONS(textopt)

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
        $MERGE_TEXT_WDG($i) configure {*}$OPTIONS(textopt)

        pack $MERGE_INFO_WDG($i) -fill both -side left -expand 0
        pack $MERGE_TEXT_WDG($i) -fill both -side left -expand 1

        ::Yadt::Update_Merge_Title $i
    }

    ::YadtPaned::Paned -init $WIDGETS(bottom_wnd).merge_paned

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

    set title $WDG_OPTIONS(default_merge_title)
    set help_text $title

    set ind 1
    if { $DIFF_TYPE == 3  &&  $MERGE_START != $DIFF_TYPE } {
        set ind [ expr $i - $DIFF_TYPE + 2 ]
    }
    if [ info exists DIFF_FILES(merge$ind) ] {
        if { $DIFF_FILES(merge$ind) != $title } {
            set title $DIFF_FILES(merge$ind)
            set help_text $title
        }
    }

    if { $title == $WDG_OPTIONS(default_merge_title) } {
        set merge_text "Merged File is not defined"
    } else {
        set merge_text "Merged File: $title"
    }

    $WIDGETS(merge_title_$i) configure -state normal
    $WIDGETS(merge_title_$i) delete 0 end
    $WIDGETS(merge_title_$i) insert end $merge_text
    $WIDGETS(merge_title_$i) configure -state readonly

    set WDG_OPTIONS($MERGE_TEXT_WDG($i)) $merge_text

    DynamicHelp::add $WIDGETS(merge_title_$i) -type balloon -text $help_text
}

#===============================================================================

set ::Yadt::Text_Widget_Proc {

    variable ::Yadt::TEXT_WDG
    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::WIDGETS
    variable ::Yadt::MAP_TITLE_SHORT
    variable ::Yadt::WDG_OPTIONS

    set real "[ lindex [ info level [ info level ] ] 0 ]_"

    set result [ $real $command {*}$args ]
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
                    lassign [ split [ $WDG_OPTIONS(active_window) index insert ] "." ] ln col
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

    set result [ $real $command {*}$args ]
    if { $command == "mark" } {
        if { [ lindex $args 0 ] == "set" && [ lindex $args 1 ] == "insert" } {
            set WDG_OPTIONS(cursor_position) ""
            for { set i $MERGE_START } { $i <= $DIFF_TYPE } { incr i } {
                if { "${WDG_OPTIONS(active_window)}_" == "$MERGE_TEXT_WDG($i)_" } {
                    lassign [ split [ $WDG_OPTIONS(active_window) index insert ] "." ] ln col
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

    set WIDGETS(underline,file,recompute) 0
    set WIDGETS(underline,file,save) 0
    set WIDGETS(underline,file,save_as) 17
    set WIDGETS(underline,file,write_cvs) 15
    set WIDGETS(underline,file,save_exit) 1
    set WIDGETS(underline,file,exit) 2

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
        -underline $WIDGETS(underline,file,recompute)
    $WIDGETS(menu_file) add separator

    $WIDGETS(menu_file) add command \
        -label $WIDGETS(menu_item,file,save) \
        -command "::Yadt::Save_Merged_Files" \
        -image saveImage \
        -compound left \
        -state normal \
        -underline $WIDGETS(underline,file,save)

    $WIDGETS(menu_file) add command \
        -label $WIDGETS(menu_item,file,save_as) \
        -command [ list ::Yadt::Save_Merged_Files -save_as 1 ] \
        -image saveAsImage \
        -compound left \
        -state normal \
        -underline $WIDGETS(underline,file,save_as)

    if { $DIFF_TYPE == 3 } {
        $WIDGETS(menu_file) add separator
        $WIDGETS(menu_file) add command \
            -label $WIDGETS(menu_item,file,write_cvs) \
            -command "::YadtCvs::Save_CVS_Like_Merge_File" \
            -image saveAsCvsImage \
            -compound left \
            -state disabled \
            -underline $WIDGETS(underline,file,write_cvs)
    }

    $WIDGETS(menu_file) add separator
    $WIDGETS(menu_file) add command \
        -label $WIDGETS(menu_item,file,save_exit) \
        -command "::Yadt::Save_And_Exit" \
        -image saveExitImage \
        -compound left \
        -state normal \
        -underline $WIDGETS(underline,file,save_exit)
    $WIDGETS(menu_file) add command \
        -label $WIDGETS(menu_item,file,exit) \
        -image stopImage \
        -compound left \
        -command "Yadt::Exit" \
        -underline $WIDGETS(underline,file,exit)

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
    set WIDGETS(popup_item,find_nearest) "Find Nearest"

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

    catch { tk_popup $WIDGETS(popup_merge_mode_menu) $x $y }
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

    catch { tk_popup $WIDGETS(popup_menu) $x $y }
}

#===============================================================================

proc ::Yadt::Draw_Toolbar_Elements { } {

    variable ::Yadt::WIDGETS
    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::MERGE_START

    set WIDGETS(tool_bar) [ ::ttk::frame $WIDGETS(window_name).toolbar -relief groove -style Toolbutton ]
    pack $WIDGETS(tool_bar) -side top -fill x -expand 0

    ::Yadt::Draw_Common_Toolbar_Elements

    ::Yadt::Draw_Combo_Toolbar_Element
    ::Yadt::Draw_Toolbar_Separator $WIDGETS(tool_bar).sep1

    switch -- $DIFF_TYPE {
        2 {
            ::Yadt::Draw_Navigation_Toolbar_Elements
            ::Yadt::Draw_Toolbar_Separator $WIDGETS(tool_bar).sep2
            ::Yadt::Draw_Toolbar_Elements2
            ::Yadt::Draw_Toolbar_Separator $WIDGETS(tool_bar).sep3
        }
        3 {
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

    bind $WIDGETS(diff_combo) <<ComboboxSelected>> \
        "::Yadt::Move_Indicator_To
         ::Yadt::Focus_Active_Window
        "
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
         -side left

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
             -side left
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
            -side left
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
        -side left
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

    ::ttk::button $WIDGETS(tool_bar).save \
        -text "Save" \
        -image saveImage \
        -takefocus 0 \
        -state normal \
        -style Toolbutton \
        -command [ list ::Yadt::Save_Merged_Files -caller $WIDGETS(tool_bar).save ]
    pack $WIDGETS(tool_bar).save -side left
    lappend elements $WIDGETS(tool_bar).save

    if { 0 } {
        # don't pack the button 'SaveAs' to prevent users from selecting a 
        # wrong path for the merge result:
        ::ttk::button $WIDGETS(tool_bar).save_as \
            -text "Save As..." \
            -image saveAsImage \
            -takefocus 0 \
            -state normal \
            -style Toolbutton \
            -command [ list ::Yadt::Save_Merged_Files -save_as 1 -caller $WIDGETS(tool_bar).save_as ]
        pack $WIDGETS(tool_bar).save_as -side left

        set WDG_OPTIONS(tooltip,$WIDGETS(tool_bar).save_as) \
            "Save merged file as..."
        lappend elements $WIDGETS(tool_bar).save_as
    }

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

    global tcl_platform

    set relief groove
    if { $tcl_platform(platform) == "unix" } {
        set relief ridge
    }

    label $wdg \
        -image [ image create photo ] \
        -highlightthickness 0 \
        -bd 1 \
        -width 0 \
        -height 22 \
        -relief $relief
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

            if { $off1 != 0 || [ ::YadtDiff3::Get_Which_File_For_Diff_Id $diff_id ] } {
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

            if { $off2 != 0 || [ ::YadtDiff3::Get_Which_File_For_Diff_Id $diff_id ] } {
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

            if { $off3 != 0 || [ ::YadtDiff3::Get_Which_File_For_Diff_Id $diff_id ] } {
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
            set num_diff [ ::YadtDiff3::Get_Diff_Num ]
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

    ::Yadt::Move_Thumb {*}[ $TEXT_WDG(1) yview ]
}

#===============================================================================

proc ::Yadt::Map_Resize { args } {

    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::DIFF2
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
            set num_diff [ ::YadtDiff3::Get_Diff_Num ]
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

    variable ::Yadt::MAP_COLOR

    lassign [ ::Yadt::Get_Diff_Scr_Params $ind ] start end type
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

    variable ::Yadt::MAP_COLOR

    lassign [ ::Yadt::Get_Diff_Scr_Params $ind ] start end type
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

    if ![ ::YadtDiff3::Get_Which_File_For_Diff_Id $ind ] {
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

    variable ::Yadt::MERGE_START
    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::WIDGETS

    set wdg_list {}
    for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
        lappend wdg_list $WIDGETS(file_title_$i)
    }

    for { set i $MERGE_START } { $i <= $DIFF_TYPE } { incr i } {
        lappend wdg_list $WIDGETS(merge_title_$i)
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

    variable ::Yadt::OPTIONS
    variable ::Yadt::WDG_OPTIONS
    variable ::Yadt::WIDGETS
    variable ::Yadt::DIFF_TYPE

    set key_events [ list <Button-3> ]
    if { [ tk windowingsystem ] == "aqua" } {
        set key_events [ list <Button-2> <Control-Button-1> ]   
    }

    # Popup menu
    foreach wdg [ concat [ ::Yadt::Get_Diff_Wdg_List ] \
                      [ ::Yadt::Get_Merge_Wdg_List ] \
                      $WIDGETS(mapCanvas) ] {
        foreach key $key_events {
            bind $wdg $key { 
                ::Yadt:::Show_Popup_Menu %X %Y 
            }
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
            foreach key $key_events {
                bind $wdg $key {
                    ::Yadt:::Show_Merge_Mode_Popup_Menu %X %Y 
                }
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
    ::Yadt::Update_Save_Buttons_State
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

    ::Yadt::Update_Save_Buttons_State
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

    ::Yadt::Update_Save_Buttons_State
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

proc ::Yadt::Status_Msg { type msg { update 1 } } {

    variable ::Yadt::WDG_OPTIONS

    set ::Yadt::WDG_OPTIONS($type) $msg
    if { $update } {
        update idletasks
    }
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

    $WDG_OPTIONS(active_window) {*}$cmd_args
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

    $WDG_OPTIONS(active_window) {*}$cmd_args
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
            ::YadtPaned::Paned -show $WIDGETS(main_paned) $WIDGETS(bottom_wnd)
        }
        0 {
            # Hide merge window
            ::YadtPaned::Paned -hide $WIDGETS(main_paned) $WIDGETS(bottom_wnd)
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

    if { $DIFF_TYPE == 2 } {
        return
    }

    if { $OPTIONS(current_merge_mode) == $OPTIONS(merge_mode) } {
        return
    }

    switch -- $OPTIONS(merge_mode) {
        normal {
            set DIFF_INT(pos) [ ::YadtDiff3::Get_Diff_Id_For_Range $DIFF_INT(pos) ]
        }
        expert {
            ::Yadt::Current_Tag remove $DIFF_INT(pos) -for_diff_id 1
            set DIFF_INT(pos) [ ::YadtDiff3::Get_Top_Range_For_Diff_Id $DIFF_INT(pos) ]
        }
    }

    ::Yadt::Set_Diff_Combo_Values
    ::Yadt::Set_Diff_Indicator $DIFF_INT(pos) 0 1

    set OPTIONS(current_merge_mode) $OPTIONS(merge_mode)
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

    if ![ ::Yadt::Get_Diff_Scr_Params $DIFF_INT(pos) -exists ] return
    lassign [ ::Yadt::Get_Diff_Scr_Params $DIFF_INT(pos) ] start end type

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
    ::Yadt::Move_Thumb {*}[ $TEXT_WDG(1) yview ]
    $WIDGETS(v_scroll) set {*}[ $TEXT_WDG(1) yview ]

    ::Yadt::Merge_Center
}

#===============================================================================

proc ::Yadt::Diff3_Center {} {

    variable ::Yadt::WIDGETS
    variable ::Yadt::DIFF_INT
    variable ::Yadt::WDG_OPTIONS
    variable ::Yadt::OPTIONS
    variable ::Yadt::TEXT_WDG
    variable ::Yadt::TEXT_NUM_WDG
    variable ::Yadt::TEXT_INFO_WDG
    variable ::Yadt::DIFF_TYPE

    if ![ ::YadtDiff3::Get_Diff_Num ] return

    lassign [ ::Yadt::Get_Diff_Scr_Params $DIFF_INT(pos) ] start end type
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
    ::Yadt::Move_Thumb {*}[ $TEXT_WDG(1) yview ]
    $WIDGETS(v_scroll) set {*}[ $TEXT_WDG(1) yview ]

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
    $WIDGETS(v_scroll_merge) set {*}[ $MERGE_TEXT_WDG($MERGE_START) yview ]
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

    if { $DIFF_INT(count) == 0 } return

    set difflines {}
    for { set j $MERGE_START } { $j <= $DIFF_TYPE } { incr j } {
        set num [ ::Yadt::Diff_Size $DIFF_INT(pos) $DIFF_INT($OPTIONS(merge_mode)_merge$DIFF_INT(pos),$j) ]
        lappend difflines $num
    }

    set difflines [ ::CmnTools::MaxN {*}$difflines ]

    for { set i $MERGE_START } { $i <= $DIFF_TYPE } { incr i } {

        if { !$OPTIONS(syncscroll) && \
                 $WDG_OPTIONS(active_window) != $MERGE_TEXT_WDG($i) } continue

        set yview [ $MERGE_TEXT_WDG($i) yview ]
        set ywindow [ expr { [ lindex $yview 1 ] - [ lindex $yview 0 ] } ]

        set pos $DIFF_INT(pos)
        set offset 0
        if { $OPTIONS(merge_mode) == "expert" } {
            set offset [ ::Yadt::Get_Range_Offset_Inside_Diff $DIFF_INT(pos) $i ]
            set pos [ ::YadtDiff3::Get_Diff_Id_For_Range $DIFF_INT(pos) ]
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
    $WIDGETS(v_scroll_merge) set {*}[ $MERGE_TEXT_WDG($MERGE_START) yview ]
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

    ::Yadt::Set_Diff_Indicator $diff 0 1
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

    switch -- $OPTIONS(merge_mode) {
        normal {
            set num_diff [ ::YadtDiff3::Get_Diff_Num ]
        }
        expert {
            set num_diff [ ::YadtDiff3::Get_Ranges_Num ]
        }
    }

    set top $line_num

    for { set low 1; set high $num_diff; set diff_id [ expr { ($low + $high) / 2 } ] } \
        { $diff_id >= $low } \
        { set diff_id [ expr { ($low + $high) / 2 } ] } {

            for { set i 1 } { $i <= $DIFF_TYPE } { incr i } {
                switch -- $search_type {
                    pdiff {
                        foreach [ list thisdiff($i) s($i) e($i) type($i) ] \
                            $DIFF_INT($diff_id,$i,$search_type) { }
                    }
                    scrdiff {
                        lassign [ ::Yadt::Get_Diff_Scr_Params $diff_id ] \
                            s($i) e($i) type($i)
                    }
                }
            }

            if { $s(1) > $top } {
                set high [ expr { $diff_id - 1 } ]
            } else {
                set low [ expr { $diff_id + 1 } ]
            }
        }

    set diff_id [ ::CmnTools::MaxN 1 [ ::CmnTools::MinN $diff_id $num_diff ] ]

    if { $diff_id > 0 && $diff_id < $num_diff } {

        switch -- $OPTIONS(merge_mode) {
            normal {
                set nexts(1) [ lindex $DIFF_INT([ expr $diff_id + 1 ],scrdiff) 0 ]
                set e(1) [ lindex $DIFF_INT($diff_id,scrdiff) 1 ]
            }
            expert {
                lassign [ ::Yadt::Get_Diff_Scr_Params [ expr $diff_id + 1 ] ] \
                    nexts(1) dummy1 dummy2
                lassign [ ::Yadt::Get_Diff_Scr_Params $diff_id  ] \
                    dummy1 e(1) dummy2
            }
        }

        if { $nexts(1) - $top < $top - $e(1) } {
            incr diff_id
        }
    }

    return $diff_id
}

#===============================================================================

proc ::Yadt::Set_Diff_Indicator { value { relative 1 } { setpos 1 } { value_type "" } } {

    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::DIFF2
    variable ::Yadt::DIFF_INT
    variable ::Yadt::OPTIONS

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
                    set num_diff [ ::YadtDiff3::Get_Diff_Num ]
                }
                expert {
                    set num_diff [ ::YadtDiff3::Get_Ranges_Num ]
                }
            }
        }
    }

    if { $num_diff == 0 } {
        ::Yadt::Update_Widgets
        return
    }

    if { $value == "last" } {
        set value $num_diff
        set relative 0
    }

    if { $DIFF_INT(pos) != 0 } {
        ::Yadt::Current_Tag remove $DIFF_INT(pos)
    }

    if { $value_type == "normal" && \
             $OPTIONS(merge_mode) == "expert" && \
             $DIFF_TYPE == 3 } {
        set value [ ::YadtDiff3::Get_Top_Range_For_Diff_Id $value ]
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

    set found [ ::Yadt::Find_Conflict $value ]

    if { $found } {
        ::Yadt::Set_Diff_Indicator $found 0 1 "normal"
        ::Yadt::Update_Widgets
    }
}

#===============================================================================

proc ::Yadt::Find_Conflict { direction } {

    variable ::Yadt::DIFF_INT
    variable ::Yadt::OPTIONS

    set num_diff [ ::YadtDiff3::Get_Diff_Num ]

    switch -- $OPTIONS(merge_mode) {
        normal {
            set diff_id $DIFF_INT(pos)
        }
        expert {
            set diff_id [ ::YadtDiff3::Get_Diff_Id_For_Range $DIFF_INT(pos) ]
        }
    }

    if { $num_diff == 0 } {
        return 0
    }

    set found 0

    switch -- $direction {
        1 {
            for { set i [ expr $diff_id + 1 ] } { $i <= $num_diff } { incr i } {
                if ![ ::YadtDiff3::Get_Which_File_For_Diff_Id $i ] {
                    set found $i
                    break
                }
            }
        }
        -1 {
            for { set i [ expr $diff_id - 1 ] } { $i > 0 } { incr i -1 } {
                if ![ ::YadtDiff3::Get_Which_File_For_Diff_Id $i ] {
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

    variable ::Yadt::DIFF_INT
    variable ::Yadt::OPTIONS

    switch -- $OPTIONS(merge_mode) {
        normal {
            set num_diff [ ::YadtDiff3::Get_Diff_Num ]
        }
        expert {
            set num_diff [ ::YadtDiff3::Get_Ranges_Num ]
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
    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::OPTIONS

    set diff_id $DIFF_INT(pos)

    switch -- $DIFF_TYPE {
        2 {
            set num_diff $DIFF_INT(count)
            ::Yadt::Update_Widgets2 $num_diff
        }
        3 {
            switch -- $OPTIONS(merge_mode) {
                normal {
                    set num_diff [ ::YadtDiff3::Get_Diff_Num ]
                }
                expert {
                    set num_diff [ ::YadtDiff3::Get_Ranges_Num ]
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

    # Status bar
    set units "diffs"
    if { $DIFF_TYPE == 3 && $OPTIONS(merge_mode) == "expert" } {
        set units "ranges"
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

    set state disabled
    if { $num_diff > 0 } {
        set state normal
    }

    $WIDGETS(tool_bar).center_cur configure -state $state

    switch -- $state {
        "disabled" {
            $WDG_OPTIONS(map_image) blank
            $WIDGETS(diff_combo) configure -values {}
            $WIDGETS(diff_combo) set ""
        }
        "normal" {
            set i [ expr $diff_id - 1 ]
            catch { $WIDGETS(diff_combo) current $i }
            $WIDGETS(diff_combo) selection clear
        }
    }
}

#===============================================================================

proc ::Yadt::Update_Save_Buttons_State {} {

    variable ::Yadt::WDG_OPTIONS

    if { $WDG_OPTIONS(merge_saved) } {
        ::Yadt::Set_Save_Operation_State "normal"
    }
}

#===============================================================================

proc ::Yadt::Set_Save_Operation_State { state } {

    variable ::Yadt::WIDGETS

    $WIDGETS(tool_bar).save configure -state $state
    $WIDGETS(menu_file) entryconfigure $WIDGETS(menu_item,file,save) -state $state
    $WIDGETS(menu_file) entryconfigure $WIDGETS(menu_item,file,save_exit) -state $state
}

#===============================================================================

proc ::Yadt::Update_Save_Menu_Tooltip {} {

    variable ::Yadt::DIFF_TYPE
    variable ::Yadt::MERGE_START
    variable ::Yadt::WIDGETS
    variable ::Yadt::WDG_OPTIONS
    variable ::Yadt::DIFF_FILES

    set save_text "Save merged file"

    if [ info exists DIFF_FILES(merge1) ] {
        append save_text " - $DIFF_FILES(merge1)"
        if { $DIFF_TYPE == 3  &&  \
                 $MERGE_START != $DIFF_TYPE && \
                 [ info exists DIFF_FILES(merge2) ] } {
            append save_text ",$DIFF_FILES(merge2)"
        }
    }

    if [ info exists WIDGETS(menu_item,file,save) ] {
        set WDG_OPTIONS(tooltip,$WIDGETS(menu_item,file,save)) $save_text
    }
    if [ info exists WIDGETS(menu_item,file,save_exit) ] {
        set WDG_OPTIONS(tooltip,$WIDGETS(menu_item,file,save_exit)) "$save_text - and Exit"
    }
    if { [ info exists WIDGETS(tool_bar) ] && [ winfo exists $WIDGETS(tool_bar).save ] } {
        set WDG_OPTIONS(tooltip,$WIDGETS(tool_bar).save) $save_text
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

    ::ttk::notebook $wdg.nb
    pack $wdg.nb -fill both -expand 1
    $wdg.nb add [ frame $wdg.nb.soptions ] -text "Standard"
    $wdg.nb add [ frame $wdg.nb.aoptions ] -text "Advanced"
    ttk::notebook::enableTraversal $wdg.nb

    ::Yadt::Draw_Standard_Options_Tab $wdg.nb.soptions
    ::Yadt::Draw_Advanced_Options_Tab $wdg.nb.aoptions

    update
    set w [ winfo reqwidth $wdg ]
    set h [ winfo reqheight $wdg ]

    BWidget::place $wdg $w $h center $WIDGETS(window_name) 
    wm deiconify $wdg

    ::Yadt::Main_Window_Configure_Event
}

#===============================================================================

proc ::Yadt::Draw_Standard_Options_Tab { wdg } {

    variable ::Yadt::WDG_OPTIONS
    variable ::Yadt::PREF

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
}

#===============================================================================

proc ::Yadt::Draw_Advanced_Options_Tab { wdg } {

    TitleFrame $wdg.align_options -text "Diff Alignment Algorythm" -relief groove -bd 2 -side left
    pack $wdg.align_options -side top -fill x -expand 0 -padx 2 -pady 2

    set frame1 [ $wdg.align_options getframe ]

    ::Yadt::Pref_Check_Button $frame1 align_acc
    # File translation Parameters

    TitleFrame $wdg.translation -text "File end of line (EOL) translation (diffs recalculation required)" -relief groove -bd 2 -side left
    pack $wdg.translation -side top -fill x -expand 0 -padx 2 -pady 2

    foreach param_value [ list windows unix auto ] {
        ::Yadt::Pref_Radio_Button [ $wdg.translation getframe ] translation $param_value -state normal
    }


    TitleFrame $wdg.merge_options -text "Merged File Options" -relief groove -bd 2 -side left
    pack $wdg.merge_options -side top -fill x -expand 0 -padx 2 -pady 2
    set frame1 [ $wdg.merge_options getframe ]
    ::Yadt::Pref_Check_Button $frame1 backup_merged
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

            ::CmnTools::Parse_WM_Geometry $TMP_OPTIONS(geometry) -width width -height height -left left -top top
            set current_geometry ${width}x${height}
            if [ info exists left ] {
                append current_geometry "$left"
            } else {
                append current_geometry "+[ expr ( [ winfo screenwidth . ] -  [ winfo width $WIDGETS(window_name) ] ) / 2 ]"
            }
            if [ info exists top ] {
                append current_geometry "$top"
            } else {
                append current_geometry "+[ expr ( [ winfo screenheight . ] -  [ winfo height $WIDGETS(window_name) ] ) / 2 ]"
            }

            set tmp_geometry $TMP_OPTIONS(geometry,width)x$TMP_OPTIONS(geometry,height)
            if { $TMP_OPTIONS(geometry,x) >= 0 } {
                append tmp_geometry "+"
            }
            append tmp_geometry "$TMP_OPTIONS(geometry,x)"
            if { $TMP_OPTIONS(geometry,y) >= 0 } {
                append tmp_geometry "+"
            }
            append tmp_geometry "$TMP_OPTIONS(geometry,y)"

            if { $tmp_geometry != $current_geometry } {
                set state normal
            }
            continue
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
    set PREF(align_acc) {Align B vs C when A is empty}
    set PREF(backup_merged) {Backup merged file before save}
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
        align_acc     ::Yadt::Recompute_Diffs
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

        set idx [ lsearch $keys align_acc ]
        if { $idx != -1 } {
            if { $OPTIONS(align_acc) != $TMP_OPTIONS(align_acc) } {
                set rediff 1
                set OPTIONS(align_acc) $TMP_OPTIONS(align_acc)
                set keys [ lreplace $keys $idx $idx ]
                lappend delayed_cmds $special_keys(align_acc)
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
            align_acc {
            }
            translation {
                ::Yadt::Start_New_Diff_Wrapper
                set TMP_OPTIONS(translation) $OPTIONS(translation)
            }
            backup_merged {
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

Preferences are located on two notebook pages: Stadard and Advanced. Note, before modifying Advanced options, make sure that you exactly know what they means.

<hdr>Standard Options</hdr>

Standard options are organized in several groups: <cmp>Geometry</cmp>, <cmp>Position</cmp>, <cmp>Layout</cmp>, <cmp>Display</cmp>, <cmp>Navigation</cmp> and <cmp>Text Markup</cmp> options.

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

<hdr>Advanced Options</hdr>

Advanced options are organized in similar way as Standard options.

<hdr>Diff Alignment Algorythm</hdr>

<bld>$PREF(align_acc)</bld>
Used during 3-way comparisson. If set, YaDT will try to align part in file B vs part in file C when appropriate part in file A is empty. The idea is that sometimes, the first way of alignment is much clearer to read but sometimes the second one is.

<hdr>File end of line translation</hdr>

This option defines how to treat line ending, or end of line (EOL) in files being compared.
By default, this option is set to the platform specific value, but sometimes it is needed to change it, for example while comparing windows-styled files from unix-like systems. Differences will be recalculated to take effect.

<hdr>Merge File Options</hdr>

<bld>$PREF(backup_merged)</bld>
If set, merged file 'FILENAME.EXT' before saving will be backed up as 'FILENAME.EXT.bkp'.
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

    ::YadtImg::Load_Images

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
        --ignore-blanks
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
        --merge-backup-suffix BKP_SUFFIX
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
        <cmd>--ignore-blanks</cmd> - if set, blanks will be ignored while finding files differences
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

        <cmd>--merge-backup-suffix BKP_SUFFIX</cmd> - if set, before saving merged file, it will be backed up with a suffix .BKP_SUFFIX

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

        This operation is also available only for comparing three files.
        By default, any conflicts are considered (marked) as unresolved. After the decision which parts of compared files should be taken for merge, the conflict can be marked as resolved. Before saving file, it is better to mark all conflicts as resolved, however it is possible to save merge file despite of conflicts marked as unresolved. Also, it is possible to save merge file even if not all conflicts are resolved.

        To move between unresolved conflicts the following buttons are used:

        <img>prevUnresolvImage</img> - Move to the previous unresolved conflict
        <img>nextUnresolvImage</img> - Move to the next unresolved conflict

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

<bld>Saving merge file</bld>

After all conflicts (if any) are resolved and merge file is ready, button <img>saveImage</img> or <img>saveAsImage</img> will save the merge file.
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

    $widget configure -font { Helvetica 10 }

    $widget tag configure bld \
        -font { Helvetica 10 bold }

    $widget tag configure cmp \
        -font { Courier 10 bold }

    $widget tag configure hdr \
        -font { Helvetica 14 bold } \
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
        -font { Helvetica 14 bold } \
        -foreground blue \
        -justify center
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
        ::YadtImg::Load_Images
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
