################################################################################
#
#  kit_maker - tool for starkits generation
#
################################################################################



################################################################################
# Some helpfull additional procs                                               #
################################################################################

#===============================================================================

proc Popup_Error_Msg { title msg args } {
 
    global errorInfo

    if ![ ::CmnTools::Get_Arg -noerrorInfo args -exists  ] {
        append msg "\n\nerrorInfo: <$errorInfo>"
    }

    if ![ catch { package present Tk } ] {
        tk_messageBox -icon error -type ok -title $title -message $msg
    } else  {
        puts stdout "ERROR: $title\n\t$msg"
    }
}

#===============================================================================

################################################################################
# Kit creation and check procedures                                            #
################################################################################

#===============================================================================

proc Make_Kits_Wrapper { { kit_list "" } } {

    global ERROR_CODES

    Set_Controls_State disabled
    Log_Handler -clear

    set res [ catch { Make_Kits $kit_list } errmsg ]

    if { $res } {
        Log_Handler -puts "ERROR: $errmsg"
        if { $res == $ERROR_CODES(uerror) } {
            Popup_Error_Msg "Error while creating starkits" $errmsg -noerrorInfo
        } else {
            Popup_Error_Msg "Error while creating starkits" $errmsg
        }
    } else {
        Log_Handler -puts "Finished."
    }

    Set_Controls_State normal
}

#===============================================================================

proc Make_Kits { { kit_list "" } } {

    global MAKE_OPTIONS GUI_CFG tcl_platform
    global SUPPORTED_KITS SUPPORTED_PLATFORMS
    global ERROR_CODES

    if ![ catch { package present Tk } ] {
        set kit_list $GUI_CFG(selected_target)
    } 

    set target_platforms [ Get_Target_Platforms ]

    if { $target_platforms == "" } {
        return -code $ERROR_CODES(uerror) "You didn't select any target platform"
    }

    Log_Handler -puts "Starkit directory: <$MAKE_OPTIONS(starkit_dir)>"
    Log_Handler -puts "Generated starkits output dir: <$MAKE_OPTIONS(output_dir)>\n"

    Log_Handler -puts "Setting up SDX..."
    set sdx_exe sdx
    if { $tcl_platform(platform) == "windows" } {
        set sdx_exe $sdx_exe.exe
    }

    if { $tcl_platform(platform) == "unix" } {
        set MAKE_OPTIONS(sdx) [ file join  $MAKE_OPTIONS(starkit_dir) $tcl_platform(os) $sdx_exe ]
    } else {
        set MAKE_OPTIONS(sdx) [ file join  $MAKE_OPTIONS(starkit_dir) $tcl_platform(platform) $sdx_exe ]
    }
    Log_Handler -puts "Setting up SDX...Done"

    file mkdir $MAKE_OPTIONS(output_dir)

    ::StarkitGenerator::Generate_Kits \
        $MAKE_OPTIONS(sdx) \
        $kit_list \
        $MAKE_OPTIONS(kit_type) \
        $target_platforms \
        $MAKE_OPTIONS(starkit_dir) \
        $MAKE_OPTIONS(output_dir) \
        $MAKE_OPTIONS(embed_tools) \
        -logcmd [ list Log_Handler -puts ]

    Log_Handler -puts ""
    Log_Handler -puts "Generated starkits <$kit_list>\nfor <$target_platforms> are located in:\n\t<$MAKE_OPTIONS(output_dir)>\n"
}

#===============================================================================

################################################################################
# Logs procedures                                                              #
################################################################################

#===============================================================================

proc Log_Handler { action { msg "" } } {

    global GUI_CFG ERROR_CODES

    switch -- $action {
        -clear {
            if [ info exist GUI_CFG(log_widget) ] {
                $GUI_CFG(log_widget) configure -state normal
                $GUI_CFG(log_widget) delete 1.0 end
                $GUI_CFG(log_widget) configure -state disabled
                update
            }
        }
        -puts {
            if [ info exist GUI_CFG(log_widget) ] {
                $GUI_CFG(log_widget) configure -state normal
                $GUI_CFG(log_widget) insert end "$msg\n"
                $GUI_CFG(log_widget) see end
                $GUI_CFG(log_widget) configure -state disabled
                update
            } else {
                puts stdout $msg
            }
        }
        -get_log {
            if [ info exist GUI_CFG(log_widget) ] {
                return [ $GUI_CFG(log_widget) get 1.0 end ]
            } else {
                return ""
            }
        }
        default { return -code $ERROR_CODES(error) "Unexpected action: <$action>" }
    }
}

#===============================================================================

proc Save_Log { } {

    global MAKE_OPTIONS

    set fname [ tk_getSaveFile \
                    -defaultextension ".txt" \
                    -initialfile maker_log \
                    -initialdir $MAKE_OPTIONS(starkit_dir) \
                    -parent . ]
    if { $fname == "" } return

    if [ catch {
        set fd [ open $fname {WRONLY CREAT} ]
        puts $fd [ Log_Handler -get_log ]
        close $fd
    } errmsg ] {
        Log_Handler -puts "Couldn't save log <$fname>: $errmsg"
    }
}

#===============================================================================

proc Exit_Kit_Maker { { wdg "" } } {

    if { $wdg == "" } {
        exit 0
    }

    destroy $wdg
}

#===============================================================================

################################################################################
# Main widget procedures                                                       #
################################################################################

#===============================================================================

proc Get_Target_Platforms {} {

    global SUPPORTED_PLATFORMS  MAKE_OPTIONS ERROR_CODES

    set platforms {}
    
    foreach key [ array names MAKE_OPTIONS platform,* ] {
        if { $MAKE_OPTIONS($key) } {
            regsub {^platform,} $key "" platform
            if { [ lsearch -exact $SUPPORTED_PLATFORMS $platform ] < 0 } {
                return -code $ERROR_CODES(error) "Internal bug: unexpected platform <$platform>"
            }
            lappend platforms $platform
        }
    }

    return $platforms
}

#===============================================================================

proc Create_Maker_Widget { } {

    global GUI_CFG SUPPORTED_PLATFORMS SUPPORTED_KITS  MAKE_OPTIONS

    set w .
    wm withdraw  $w
    wm resizable $w 1 1
    wm title $w "Kit Maker"
    wm iconname $w "Kit Maker"
    wm protocol $w WM_DELETE_WINDOW "Exit_Kit_Maker $w"

    set topframe [ frame $w.top ]
    set logframe [ frame $w.log ]
    set ctrframe [ frame $w.ctr ]

    pack $ctrframe -side bottom -expand 0 -fill x -pady 5 -padx 2
    pack $topframe -expand 0 -fill x -anchor w
    pack $logframe -expand 1 -fill both

    # Controls:

    frame $ctrframe.fr1
    frame $ctrframe.fr2
    frame $ctrframe.fr3
    pack $ctrframe.fr3 -side right -expand 1 -fill x
    pack $ctrframe.fr1 $ctrframe.fr2 -side left -expand 1 -fill x

    button $ctrframe.fr1.save -width 8 -text "Save Log" -command "Save_Log"
    set GUI_CFG(controls,start) [ button $ctrframe.fr2.start \
                                      -width 8 \
                                      -text "Make Kit" \
                                      -command Make_Kits_Wrapper ]
    button $ctrframe.fr3.close -width 8 -text "Close" -command "Exit_Kit_Maker $w"
    pack $ctrframe.fr1.save $ctrframe.fr2.start $ctrframe.fr3.close

    # Log:
    set tlogframe [ TitleFrame $logframe.titlefr -text "Log:" ]
    pack $tlogframe -expand 1 -fill both -padx 2 -pady 2
    set logframe [ $tlogframe getframe ]

    set win [ ScrolledWindow $logframe.sw ]
    pack $win -expand 1 -fill both

    set GUI_CFG(log_widget) [ text $win.txt \
                                  -fg black \
                                  -bg white \
                                  -selectforeground black \
                                  -selectbackground lightgrey \
                                  -wrap none \
                                  -width 60 \
                                  -height 20 \
                                  -state disabled ]
    $win setwidget $GUI_CFG(log_widget)


    set cndframe [ frame $topframe.cndframe -relief groove -bd 2 ]
    pack $cndframe -pady 5 -expand 0 -fill x -padx 2 -pady 5

    # Kits To Create:

    set trgframe  [ frame $cndframe.target ]
    pack $trgframe -pady 5 -expand 0 -fill x -padx 2 -pady 2

    set GUI_CFG(selected_target) [ lindex $SUPPORTED_KITS 0 ]
    label $trgframe.label -text "Kits To Create:"
    ComboBox $trgframe.combobox \
        -state normal \
        -entrybg white \
        -fg black \
        -width 8 \
        -height 16 \
        -takefocus 0 \
        -editable 0 \
        -hottrack 1 \
        -values $SUPPORTED_KITS \
        -textvariable GUI_CFG(selected_target)

    pack $trgframe.label -side left -padx 5 -pady 5 -expand 0
    pack $trgframe.combobox -side left -padx 5 -pady 5 -expand 1 -fill x

    # Platforms:

    set pltfframe [ frame $cndframe.platform ]
    pack $pltfframe -fill x -expand 0 -padx 2 -pady 2

    label $pltfframe.platf -text "Platforms:"
    pack $pltfframe.platf -side left -padx 5 -pady 5

    set tools_frame [ frame $cndframe.tools ]
    pack $tools_frame -fill x -expand 0 -padx 2 -pady 2

    set GUI_CFG(embed_tools) [ checkbutton $tools_frame.embed_tools \
                                   -text "Embed diff" \
                                   -offvalue 0 \
                                   -onvalue 1 \
                                   -variable MAKE_OPTIONS(embed_tools) ]
    pack $GUI_CFG(embed_tools) -side left -padx 5 -pady 5

    set MAKE_OPTIONS(embed_tools) 1

    foreach platform $SUPPORTED_PLATFORMS {
        set GUI_CFG(platform_checkbutton,$platform) [ checkbutton $pltfframe.[ string tolower $platform ] \
                                                          -text $platform \
                                                          -offvalue 0 \
                                                          -onvalue 1 \
                                                          -variable MAKE_OPTIONS(platform,$platform) ]
        pack $GUI_CFG(platform_checkbutton,$platform) -side left -padx 5 -pady 5

        set MAKE_OPTIONS(platform,$platform) 1
    }

    BWidget::place $w 600 500 center
    wm deiconify $w
    Log_Handler -puts "Starkit directory: <$MAKE_OPTIONS(starkit_dir)>"
}

#===============================================================================

proc Update_Target_Kit_Type_Option { { kit "" } } {

    global MAKE_OPTIONS STARKIT_TO_KIT_TYPE_MATRIX GUI_CFG

    if [ info exist GUI_CFG(selected_target) ] {
        set option $GUI_CFG(selected_target)
    } else {
        set option $kit
    }
    set MAKE_OPTIONS(kit_type) $STARKIT_TO_KIT_TYPE_MATRIX($option)
} 

#===============================================================================

proc Update_Target_Platforms_Console_Run_Option { kit_name } {

    global SUPPORTED_PLATFORMS STARKIT_TO_TARGET_PLATFORMS_MATRIX MAKE_OPTIONS

    foreach platform $SUPPORTED_PLATFORMS {
        if { [ lsearch $STARKIT_TO_TARGET_PLATFORMS_MATRIX($kit_name) $platform ] >= 0 } {
            set MAKE_OPTIONS(platform,$platform) 1
        } else {
            set MAKE_OPTIONS(platform,$platform) 0
        }
    }
}

#===============================================================================

proc Update_Embed_Tools_Option { embed_option } {

    global MAKE_OPTIONS

    if { $embed_option == 1 } {
        set MAKE_OPTIONS(embed_tools) 1
    } else {
        set MAKE_OPTIONS(embed_tools) 0
    }
}

#===============================================================================

proc Set_Controls_State { state } {

    global GUI_CFG

    foreach control [ array names GUI_CFG controls,* ] {
        $GUI_CFG($control) configure -state $state
    }
}

#===============================================================================

proc Load_Packages { mode } {

    global MAKE_OPTIONS ERROR_CODES

    set package_list [ list \
                           CmnTools \
                           StarkitGenerator \
                          ]

    switch -- $mode {
        --normal {
            lappend package_list BWidget
        }
        --nox {
        }
        default {
            return -code $ERROR_CODES(error) "Unknown mode <$mode>"
        }
    }

    foreach pack $package_list {
        package require $pack
    }
}

#===============================================================================

proc Form_Table_For_Puts { data { title 0 } { bottom 0 } } {

    #
    # This proc is actually slightly modified version - 
    # added title and bottom functionality - 
    # of the original proc fmtable, which was taken from
    # http://en.wikibooks.org/wiki/Tcl_Programming/Introduction
    #
    # data here has the following format:
    #     list of lists:
    #     { { Col1Str1 Col2Str1 } { Col1Str2 Col2Str2 } { Col1Str3 Col2Str3 } }
    #
    # Example1:
    #     to show the following "table"
    # +----+--------------+
    # | Id | Name         |
    # +----+--------------+
    # | 0  | unregistered |
    # | 1  | test1        |
    # | 2  | test_win     |
    # +----+--------------+
    # | q  | Quit         |
    # +----+--------------+
    #
    # data: '{ Id Name } {0 unregistered} {1 test1} {2 test_win} { q Quit }'
    # title: 1 - defines that 1 string from above belongs to table title
    # bottom: 1 - defines that 1 string from the bottom belongs to table bottom
    #
    # Example2:
    # puts [ Form_Table_For_Puts {
    #  {1 short "long field content"}
    #  {2 "another long one" short}
    #  {3 "" hello}
    # } ]
    # 
    # +---+------------------+--------------------+
    # | 1 | short            | long field content |
    # | 2 | another long one | short              |
    # | 3 |                  | hello              |
    # +---+------------------+--------------------+
    #

    set res ""

    # Detect column sizes
    set maxs {}
    foreach item [ lindex $data 0 ] {
        lappend maxs [ string length $item ]
    }
    foreach row [ lrange $data 1 end ] {
        set i 0
        foreach item $row max $maxs {
            if { [ string length $item ] > $max } {
                lset maxs $i [ string length $item ]
            }
            incr i
        }
    }

    # Separator
    set head +
    foreach max $maxs { append head "-[ string repeat - $max ]-+" }
    append res $head\n

    # Title
    if { $title } {
        foreach row [ lrange $data 0 [ expr {$title-1} ] ] {
            append res |
            foreach item $row max $maxs { append res [ format " %-${max}s |" $item ] }
            append res \n
        }

        # Separator
        set head +
        foreach max $maxs { append head "-[ string repeat - $max ]-+" }
        append res $head\n
    }

    # Table
    foreach row [ lrange $data $title end-$bottom ] {
        append res |
        foreach item $row max $maxs { append res [ format " %-${max}s |" $item ] }
        append res \n
    }
    append res $head\n

    # Bottom
    if { $bottom } {
        foreach row [ lrange $data end-[ expr { $bottom - 1 } ] end ] {
            append res |
            foreach item $row max $maxs { append res [ format " %-${max}s |" $item ] }
            append res \n
        }
        append res $head\n
    }

    return $res
}

#===============================================================================

proc Get_Answer { message answers } {

    global ERROR_CODES

    if ![ llength $answers ] {
        return -code $ERROR_CODES(error) "Internal error in [ lindex [ info level 0 ] 0 ]"
    }

    set answers_variants "'[ join $answers {' '} ]'"

    while { 1 } {
        puts $message
        puts "Possible answers are: $answers_variants"

        set answer [ gets stdin ]

        if { [ lsearch $answers $answer ] >=0 } break

        puts "\nWrong answer! Should be one of $answers_variants\n"
    }

    return $answer
}

#===============================================================================

proc Puts_Starkits_To_Create_And_Return_Answers {} {

    global SUPPORTED_KITS

    set table {}

    lappend table "Id Starkits"

    set i 1
    foreach element $SUPPORTED_KITS {
        lappend table "$i {$element}"
        lappend answers $i
        incr i
    }
    lappend table { q Quit }
    lappend answers q

    puts [ Form_Table_For_Puts $table 1 1 ]

    return $answers
}

#===============================================================================

proc Puts_Embed_Tools_And_Return_Answers {} {

    set table {}

    lappend table "Id Embed_Tools"

    lappend table "1  Yes"
    lappend answers "1"
    lappend table "2  No"
    lappend answers "2"

    lappend table { q Quit }
    lappend answers q

    puts [ Form_Table_For_Puts $table 1 1 ]

    return $answers
}

#===============================================================================

proc Parse_Args {} {

    global argv MAKE_OPTIONS SUPPORTED_KITS

    set help_msg  "\n\t--list-branches\tor --lbra\
                   \n\t--last-version\tor --lver\
                   \n\t--create-kits\tor --cre"

    switch -regexp -- $argv {
        "^--create-kits$|^--cre$" {
            set answers [ Puts_Starkits_To_Create_And_Return_Answers ]

            set starkit_id [ Get_Answer "Enter the number of the starkits to create, or q for Quit" $answers ]

            if { $starkit_id == "q" } {
                return
            }

            set answers [ Puts_Embed_Tools_And_Return_Answers ]
            set embed_tools [ Get_Answer "Embed tools inide startkit, or q for Quit" $answers ]

            if { $embed_tools == "q" } {
                return
            }

            set starkit_name [ lindex $SUPPORTED_KITS [ expr $starkit_id - 1 ] ]

            Update_Target_Kit_Type_Option $starkit_name
            Update_Target_Platforms_Console_Run_Option $starkit_name
            Update_Embed_Tools_Option $embed_tools

            Make_Kits_Wrapper $starkit_name
        }
        "^--help$" {
            puts "Supported arguments:$help_msg"
        }
        default {
            puts "Unsupported arguments <$argv>\
                  \nSupported ones:$help_msg"
        }
    }

    Exit_Kit_Maker
}

#===============================================================================

proc Run_Maker { } {

    global env argc auto_path tcl_platform tclversion
    global MAKE_OPTIONS GUI_CFG
    global SUPPORTED_KITS SUPPORTED_PLATFORMS 
    global STARKIT_TO_KIT_TYPE_MATRIX STARKIT_TO_TARGET_PLATFORMS_MATRIX
    global ERROR_CODES

    set ERROR_CODES(error)    1
    set ERROR_CODES(uerror)   5

    # Calculate paths:
    set MAKE_OPTIONS(starkit_dir) [ file normalize [ file dirname [ info script ] ] ]
    set MAKE_OPTIONS(script_home) [ file dirname $MAKE_OPTIONS(starkit_dir) ]
    set MAKE_OPTIONS(output_dir) [ file join $MAKE_OPTIONS(starkit_dir) generated ]

    lappend auto_path $MAKE_OPTIONS(script_home)
    lappend auto_path $MAKE_OPTIONS(script_home)/BWidget.1.8.0
    lappend auto_path $MAKE_OPTIONS(script_home)/starkits

    if { $argc == 0 } {
        Load_Packages --normal
    } else {
        Load_Packages --nox
    }
    
    # Define basic globals:
    set SUPPORTED_KITS yadt
    set SUPPORTED_PLATFORMS [ list Linux windows Darwin-Aqua Darwin-X11 ]

    array set STARKIT_TO_KIT_TYPE_MATRIX \
        [ list \
              yadt                -exe ]

    array set STARKIT_TO_TARGET_PLATFORMS_MATRIX \
        [ list \
              yadt                [ list Linux windows Darwin-Aqua Darwin-X11 ] ]

    # define stakits type (-kit -sh or -exe):
    set MAKE_OPTIONS(kit_type) "-exe"

    set interpreter [ info nameofexecutable ]
    if ![ regexp "tclkit" [ file tail $interpreter ] ] {
        return -code $ERROR_CODES(error) "Unexpected Tcl-interpreter <$interpreter>\nIt must be a tclkit-executable."
    }

    if { $argc == 0 } {
        Create_Maker_Widget
    } else {
        Parse_Args
    }
}

#===============================================================================

# catch {console show}

Run_Maker

