################################################################################
#
#  yadt_git - module for YaDT
#            provides procs for working with GIT
#
#
#
#------------------------------------------------------------------------------
#
#  Packages  required:
#  Packages  dependencies:
#
################################################################################

package provide YadtGit 1.0

#===============================================================================

namespace eval ::YadtGit {

}

#===============================================================================

proc ::YadtGit::Ignore_No_Git_Revision { git_out args } {

    upvar $git_out out

    set code [ ::CmnTools::Get_Arg -code args -default "" ]
    if { $code != "" } {
        upvar $code exitcode
    }

    if [ regsub {exists on disk, but not in} $out "" out ] {
        set exitcode 42
    }

    if [ regsub {does not exist in} $out "" out ] {
        set exitcode 42
    }
}

#===============================================================================

