################################################################################
#
#  make_yadt.tcl - contains procedures used to create yadt starkit
# 
################################################################################

package provide MakeYadt 1.0

namespace eval ::MakeYadt {

}

#===============================================================================

proc ::MakeYadt::Get_Common_Files_List { src_dir } {

    set src_files_list {}

    set files_list [ list \
                         common_tools.tcl \
                         yadt_cvs.tcl \
                         yadt_dot_cvs.tcl \
                         yadt_git.tcl \
                         yadt_hg.tcl \
                         yadt_diff2.tcl \
                         yadt_diff3.tcl \
                         yadt_images.tcl \
                         yadt_lcs.tcl \
                         yadt_paned.tcl \
                         yadt_ranges.tcl \
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

    set img_dir [ file join BWidget.1.8.0 images ]
    set files_list [ list \
                         error.gif \
                         info.gif \
                         question.gif \
                         warning.gif \
                        ]
    foreach file $files_list {
        lappend src_files_list [ file join $img_dir $file ]
    }

    # Add files from a few directories according to pattern corresponding to each directory:

    set pattern($src_dir/BWidget.1.8.0)      *.tcl
    set pattern($src_dir/BWidget.1.8.0/lang) *.rc

    set start [ expr [ string length $src_dir ] + 1 ]

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

proc ::MakeYadt::Get_Platform_Specific_Files_List { platform src_dir { tmp_files {} } } {

    if [ llength $tmp_files ] {
        upvar $tmp_files tmp_src_files
    }

    set fname .toolsrc
    set rcfile [ file join $src_dir $fname ]

    array unset content
    set src_files_list {}

    if { $platform == "Linux" } {
        # consider for Linux cvs and diff should be installed
        set tmp_src_files {}
        return $src_files_list
    }

    foreach utility [ list cvs diff ] {
        set content($utility) {}
        set exe_name $utility
        if { $platform == "windows" } {
            set exe_name ${utility}.exe
        }
        lappend src_files_list $exe_name
        lappend content($utility) $exe_name
        if { $utility == "diff" && $platform == "windows" } {
            foreach dll [ list libiconv2.dll libintl3.dll ] {
                lappend src_files_list $dll
                lappend content($utility) $dll
            }
        }
    }

    parray content

    set cnt {}
    foreach name [ array names content ] {
        lappend cnt [ concat $name $content($name) ]
    }

    set fd [ open $rcfile w+ ]
    puts $fd [ join $cnt \n ]
    close $fd

    lappend tmp_src_files [ file join $src_dir $fname ]

    lappend src_files_list $fname

    return $src_files_list
}

#===============================================================================

