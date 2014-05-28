###########################################################################
#
#  common_tools.tcl
#
#  Various helpful procedures.
#
#
###########################################################################

package provide CmnTools 1.0
     
namespace eval ::CmnTools {

}

#==========================================================================

proc ::CmnTools::MinN { args } {
    return [ lindex [ lsort -integer $args ] 0 ]
}

#===============================================================================

proc ::CmnTools::MaxN { args } {
    return [ lindex [ lsort -integer $args ] end ]
}

#==========================================================================
#
# ::CmnTools::Get_Arg 
#                  - extract keyword argument <$argname> value from the
#                    list of arguments <arg_lst>.
#                  - check if specified <$argname> argument exists in
#                    the <arg_lst> list. It is supposed that argument has
#                    no associated value.
#
# argname - the name of desired argument. If there is no argument with the
#           <$argname> name and there is no default value then "Argument
#           <$argname> not found" error will be raised unless -exists
#           option is used.
# arg_lst - the _name_ of the argument list.
# args    - opttional parameters for an argument extraction:
#   -default <$value> - default value for the <$argname> argument if it is
#                       not found in the <arg_lst> list.
#   -keepinlist       - keep extracted argument in the <arg_lst> list. The
#                       default is to remove argument name and value from
#                       the <arg_lst> list. 
#   -exists           - check if specified <$argname> argument exists in
#                       the <arg_lst> list. When used without the 
#                       -keepinlist option then only the argument's name
#                       will be deleted from the <$arg_lst> list.
#
#    Examples:
#
#    set arglst [ list -argname1 argval1 -argname2 argval2 ]
#    set arg1 [ Get_Arg -argname1 arglst ]
#    set arg3 [ Get_Arg -argname3 arglst -default arg3default ]
#    set arg3 [ Get_Arg -argname3 arglst -keepinlist -default arg3default ]
#
#    set arglst [ list -argname0 -argname1 argval1 -argname2 argval2 ]
#    set arg0 [ Get_Arg -argname0 arglst -exists ]
#    set arg1 [ Get_Arg -argname1 arglst -exists -keepinlist ]
#    set arg1 [ Get_Arg -argname1 arglst -exists ] # WARNING!
# After the last command the arglst will be:
#   {-argname0 argval1 -argname2 argval2 }
#
proc ::CmnTools::Get_Arg { argname arg_lst args } {

    upvar $arg_lst arglst

    if ![ info exists arglst ] { set arglst {} }
    set options $args

    set keepinlist 0
    set idx [ lsearch -exact $options -keepinlist ]
    if { $idx >= 0 } {
        set keepinlist 1
        set options [ lreplace $options $idx $idx ]
    }

    set checkifexists 0
    set idx [ lsearch -exact $options -exists ]
    if { $idx >= 0 } {
        set checkifexists 1
        set options [ lreplace $options $idx $idx ]
        if { [ llength $options ] > 0 } {
            return -code error "Wrong options <$options>"
        }
    }

    set has_default 0
    set idx [ lsearch -exact $options -default ]
    if { $idx >= 0 } {
        set has_default 1
        if { [ llength $options ] == 2 } {
            set default [ lindex $options [ expr {$idx + 1} ] ]
            set options [ lreplace $options $idx [ expr {$idx + 1} ] ]
        } else {
            return -code error "Wrong options <$options>"
        }
    }

    if { [ llength $options ] > 0 } {
        return -code error "Unknown options <$options>"
    }

    set idx [ lsearch -exact $arglst $argname ]

    if { $idx < 0 } {
        if { $checkifexists } {
            return 0
        } elseif { $has_default } {
            return $default
        }
        return -code error "Argument <$argname> not found"
    }

    if { $checkifexists } {
        if { $keepinlist == 0 } {
            set arglst [ lreplace $arglst $idx $idx ]
        }
        return 1
    }

    set vidx [ expr {$idx + 1} ]

    if { $vidx >= [ llength $arglst ] } {
        return -code error "<$argname> argument value not found"
    }

    set argval [ lindex $arglst $vidx ]

    if { $keepinlist == 0 } {
        set arglst [ lreplace $arglst $idx $vidx ]
    }

    return $argval
}

#===============================================================================

proc ::CmnTools::Parse_WM_Geometry { geometry args } {

    set win_width     [ ::CmnTools::Get_Arg -width    args -default "" ]
    set win_height    [ ::CmnTools::Get_Arg -height   args -default "" ]
    set win_left      [ ::CmnTools::Get_Arg -left     args -default "" ]
    set win_top       [ ::CmnTools::Get_Arg -top      args -default "" ]
    set win_position  [ ::CmnTools::Get_Arg -position args -default "" ]
    set position_only [ ::CmnTools::Get_Arg -position_only args -exists ]

    if { $geometry == "" } { return 1 }

    # 1. If optional parameter '-position_only' does not exist and any of the rest of optional
    #    parameters ('width', or 'height', or 'left', or 'top') is required to be defined, then
    #    it is possible that procedure returns success (1) but required parameter is undefined.
    # 2. If optional parameter '-position_only' does exist, then optional parameters describing
    #    dimensions of the window ('width', or 'height') MUST NOT be required to be defined.

    if { $position_only == 1  &&  ( $win_width != "" || $win_height != "" ) } {
	return -code error "While parsing expression that describes ONLY position of the window \
                            any dimension of the window (either width or height) may not be defined."
    }

    if { $win_width != "" } {
        upvar $win_width width
        if [ info exists width ] { unset width }
    }
    if { $win_height != "" } {
        upvar $win_height height
        if [ info exists height ] { unset height }
    }
    if { $win_left != "" } {
        upvar $win_left left
        if [ info exists left ] { unset left }
    }
    if { $win_top != "" } {
        upvar $win_top top
        if [ info exists top ] { unset top }
    }
    if { $win_position != "" } {
        upvar $win_position position
    }

    set position $geometry

    if { $position_only == 0 } {
	if [ regexp {^([0-9]+)[x]([0-9]+)([+\-0-9]*)$} $geometry dummy width height position ] {
	    if { $position == "" } { 
		return 1
	    }
	}
    }

    if [ regexp {^([+-][-]?[0-9]+)([+-][-]?[0-9]+)$} $position dummy left top ] {
        return 1
    }

    return 0
}

#===============================================================================

proc ::CmnTools::Parse_Yadt_Customization_Data { data } {

    set result {}
    foreach line [ split $data "\n" ] {
        set line [ string trim $line ]
        if ![ regexp "^define (.+) <(.+)>$" $line dummy name value ] continue
        lappend result $name $value
    }

    return $result
}

#===============================================================================

proc ::CmnTools::Obtain_Result_From_Error_Code { args } {

    global errorCode

    set rc  [ ::CmnTools::Get_Arg -default_value args -default 127 ]

    switch [ lindex $errorCode 0 ] {
        NONE        { set rc 0 }
        CHILDSTATUS { set rc [ lindex $errorCode 2 ] }
    }

    return $rc
}

#===============================================================================
