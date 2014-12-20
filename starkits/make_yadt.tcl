################################################################################
#
#  make_yadt.tcl - contains procedures used to create yadt starkit
# 
################################################################################

package provide MakeYadt 1.0

namespace eval ::MakeYadt {

}

#===============================================================================

proc ::MakeYadt::Get_Common_Files_List { syren_src_dir } {

    set src_files_list {}

    set files_list [ list \
                         common_tools.tcl \
                         ya_lcs.tcl \
                         yadt.tcl \
                         tcllib1.18/cmdline/pkgIndex.tcl \
                         tcllib1.18/cmdline/cmdline.tcl \
                         tcllib1.18/cmdline/typedCmdline.tcl \
                         tcllib1.18/pkgIndex.tcl \
                         tcllib1.18/struct/pkgIndex.tcl \
                         tcllib1.18/struct/struct.tcl \
                         tcllib1.18/struct/list.tcl
                        ]
    foreach file $files_list {
        lappend src_files_list $file
    }

    set src_dir [ file join BWidget.1.8.0 images ]
    set files_list [ list \
                         error.gif \
                         info.gif \
                         question.gif \
                         warning.gif \
                        ]
    foreach file $files_list {
        lappend src_files_list [ file join $src_dir $file ]
    }

    # Add files from a few directories according to pattern corresponding to each directory:

    set pattern($syren_src_dir/BWidget.1.8.0)      *.tcl
    set pattern($syren_src_dir/BWidget.1.8.0/lang) *.rc

    set start [ expr [ string length $syren_src_dir ] + 1 ]

    foreach src_dir  [ array names pattern ] {
        foreach full_fname [ glob -directory $src_dir $pattern($src_dir) ] {
            set fname [ string range $full_fname $start end ]
            if { $fname != "" } {
                lappend src_files_list $fname
            }
        }
    }

    return $src_files_list
}

#===============================================================================

proc ::MakeYadt::Get_Platform_Specific_Files_List { platform syren_src_dir } {

    set fname .toolsrc
    set rcfile [ file join $syren_src_dir $fname ]

    set content {}
    set src_files_list {}

    foreach utility [ list cvs diff ] {
        set exe_name $utility
        if { $platform == "windows" } {
            set exe_name ${utility}.exe
        }
        lappend src_files_list $exe_name
        lappend content [ list $utility $exe_name ]
    }

    set fd [ open $rcfile w+ ]
    puts $fd [ join $content \n ]
    close $fd

    lappend src_files_list $fname

    return $src_files_list
}

#===============================================================================

