################################################################################
#
#  yadt_dot_cvs - module for YaDT
#           provides procs for working with cvs.exe
#
#
#
#------------------------------------------------------------------------------
#
#  Packages  required:
#  Packages  dependencies: YaDT
#
################################################################################

package provide YadtDotCvs 1.0

#===============================================================================

namespace eval ::YadtDotCvs {

}

#===============================================================================

proc ::YadtDotCvs::Get_Work_Rev_From_Entries { file } {

    # Retuns:
    # revision value from .cvs/Entries file;
    # -1 - file .cvs/Entries is absent;
    # -2 - the revision information is not found in .cvs/Entries.

    set filename [ file tail $file ]
    set dirname [ file dirname $file ]

    set entries_file [ file join $dirname .cvs Entries ]

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

proc ::YadtDotCvs::Get_Work_Rev_From_Dot_CVS { filename cvs_cmd } {

    set cvsroot [ ::YadtDotCvs::Determine_Dot_CVS_Root_From_File $filename ]

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

proc ::YadtDotCvs::Determine_Dot_CVS_Root_From_File { filename } {

    set fname [ file join [ file dirname $filename ] .cvs Root ]

    set cvsroot [ ::Yadt::Read_File $fname -nonewline ]

    if { $cvsroot == "" } {
        return -code error "Couldn't determine cvs.exe Root"
    }

    return $cvsroot
}

#===============================================================================

proc ::YadtDotCvs::Determine_Dot_CVS_Module_From_File { filename } {

    set fname [ file join [ file dirname $filename ] .cvs Repository ]

    set content [ ::Yadt::Read_File $fname -nonewline ]

    if { $content == "" } {
        return -code error "Couldn't determine cvs.exe Module"
    }

    return $content
}

#===============================================================================
