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
                         yadt.tcl \
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

    set src_files_list [ list cvs diff diff3 ]
    if { $platform == "windows" } {
        set src_files_list [ list cvs.exe diff.exe diff3.exe ]
    }

    return $src_files_list
}

#===============================================================================

