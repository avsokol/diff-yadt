################################################################################
#
#  yadt_hg - module for YaDT
#            provides procs for working with Mercurial
#
#
#
#------------------------------------------------------------------------------
#
#  Packages  required:
#  Packages  dependencies:
#
################################################################################

package provide YadtHG 1.0

#===============================================================================

namespace eval ::YadtHG {

}

#===============================================================================

proc ::YadtHG::Ignore_No_HG_Revision { hg_out args } {

    upvar $hg_out out

    set code [ ::CmnTools::Get_Arg -code args -default "" ]
    if { $code != "" } {
        upvar $code exitcode
    }

    if [ regsub {no such file in rev} $out "" out ] {
        set exitcode 42
    }
}

#===============================================================================
