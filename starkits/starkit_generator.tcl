################################################################################
#
#  Package to help automatic starkits generation
#
#------------------------------------------------------------------------------
#
#  Packages  required: CmnTools
#
#
################################################################################

package provide StarkitGenerator 1.0

namespace eval ::StarkitGenerator {

}

variable ::StarkitGenerator::SUPPORTED_KIT_TYPES [ list -kit -sh -exe ]
variable ::StarkitGenerator::SUPPORTED_PLATFORMS [ list Linux windows SunOS Darwin ]

variable ::StarkitGenerator::TCLKIT_RUNTIME_MATRIX
array set ::StarkitGenerator::TCLKIT_RUNTIME_MATRIX {
    windows,-kit    ""
    windows,-sh     "tclkitsh.exe"
    windows,-exe    "tclkit.exe"
    Linux,-kit      ""
    Linux,-sh       "tclkit-linux"
    Linux,-exe      "tclkit-linux"
    SunOS,-kit      ""
    SunOS,-sh       "tclkit-solaris"
    SunOS,-exe      "tclkit-solaris"
    Darwin,-sh      "tclkit-darwin"
    Darwin,-exe     "tclkit-darwin"
}

variable ::StarkitGenerator::SDX

#=======================================================================

proc ::StarkitGenerator::Init { sdx_name starkit_dir output_dir vfs_top_dir target_platforms target_kit_types } {

    # starkit_dir - path to ./starkits directory;
    # output_dir  - path to generated starkits. Now: <starkit_dir>/generated
    #               Starkits for each platform will be located
    #               in <output_dir>/<target_platform> subdirectories
    # vfs_top_dir - path to <kit>.vfs directory.
    #               Now: <starkit_dir>/tmp
    # target_platforms - list of platforms for which starkits will
    #               be generated. Possible values - SUPPORTED_PLATFORMS
    # target_kit_types - a list of starkit types which will be generated.
    #               Possible values - SUPPORTED_KIT_TYPES
    #
    # Proc. Init copies sdx utility and tclkit runtimes for target platforms (if needed, 
    # depends on target_kit_types) to <vfs_top_dir> directory.

    global tcl_platform
    variable ::StarkitGenerator::SUPPORTED_PLATFORMS
    variable ::StarkitGenerator::SUPPORTED_KIT_TYPES
    variable ::StarkitGenerator::SDX
    variable ::StarkitGenerator::TCLKIT_RUNTIME_MATRIX

    file copy -force [ file join $output_dir $sdx_name ] $vfs_top_dir
    set SDX [ file join $vfs_top_dir $sdx_name ]

    if ![ llength $target_platforms ] {
        if { $tcl_platform(platform) == "unix" } {
            lappend target_platforms $tcl_platform(os)
        } else {
            lappend target_platforms $tcl_platform(platform)
        }
    }

    foreach platform $target_platforms {
        if { [ lsearch -exact $SUPPORTED_PLATFORMS $platform ] < 0 } {
            return -code error "Unsupported platform <$platform>"
        }
    }

    if ![ llength $target_kit_types ] {
        return -code error "Kit type is undefined."
    }
    foreach kit_type $target_kit_types {
        if { [ lsearch -exact $SUPPORTED_KIT_TYPES $kit_type ] < 0 } {
            return -code error "Unsupported kit type <$kit_type>"
        }
    }

    foreach target_platform $target_platforms {

        ::StarkitGenerator::MkDir [ file join $vfs_top_dir $target_platform ]

        foreach kit_type $target_kit_types {

            set runtime $TCLKIT_RUNTIME_MATRIX($target_platform,$kit_type)

            if { $runtime == "" } continue

            ::StarkitGenerator::Exec_CP \
                [ file join $starkit_dir $target_platform $runtime ] \
                [ file join $vfs_top_dir $target_platform ]
        }
    }
}

#=======================================================================

proc ::StarkitGenerator::Exec_CP { src dst } {

    global tcl_platform

    switch -- $tcl_platform(platform) {
        "unix" {
            exec cp $src $dst
        }
        "windows" {
            set cmd_exe copy
            lappend cmd_exe [ file nativename $src ] [ file nativename $dst ]
            eval exec [ file normalize $::env(ComSpec) ] /C $cmd_exe
        }
        default {
            return -code error "Unsupported platform <$tcl_platform(platform)>"
        }
    }
}

#=======================================================================

proc ::StarkitGenerator::Make_Starkit { kit_name target_platform kit_type output_dir vfs_top_dir } {

    global tcl_platform
    variable ::StarkitGenerator::SDX
    variable ::StarkitGenerator::TCLKIT_RUNTIME_MATRIX

    set vfs_dir [ file join $vfs_top_dir $kit_name.vfs ]

    if ![ file isdirectory $vfs_dir ] {
        return -code error "Path <$vfs_dir> is not a directory."
    }

    set tclkit_runtime $TCLKIT_RUNTIME_MATRIX($target_platform,$kit_type)

    set final_kit_name $kit_name.kit
    if { $tclkit_runtime != "" } {
        set final_kit_name $kit_name
        if { $target_platform == "windows" } {
            set final_kit_name $kit_name.exe
        }
    }

    set kit_path [ file join $vfs_top_dir $final_kit_name ]

    set cmd [ list $SDX wrap $kit_path -verbose -vfs $vfs_dir ]

    if { $tclkit_runtime != "" } {
        lappend cmd -runtime [ file join $vfs_top_dir $target_platform $tclkit_runtime ]
    }

    eval exec $cmd

#    set cmd [ list $SDX mkpack $kit_path $kit_path.pck ]
#    eval exec $cmd
#    file rename -force $kit_path.pck $kit_path
  
    set final_kit_dir [ file join $output_dir $target_platform ]
    ::StarkitGenerator::MkDir $final_kit_dir
    file rename -force [ file join $vfs_top_dir $final_kit_name ] [ file join $final_kit_dir $final_kit_name ]

    if { $tcl_platform(platform) != "windows" } {
        file attributes [ file join $final_kit_dir $final_kit_name ] -permissions +x
    }
}

#=======================================================================

proc ::StarkitGenerator::MkDir { dir } {

    if [ file exist $dir ] {
        if ![ file isdirectory $dir ] {
            return -code error "Cannot create <$dir> directory: it is a file."
        }
    } else {
        file mkdir $dir
    }

    return $dir
}

#=======================================================================

proc ::StarkitGenerator::Copy_Files_Between_Directories { src_dir dst_dir files_list } {

    set dst_files {}

    foreach file $files_list {
        set src_file [ file join $src_dir $file ]
        set dst_file [ file join $dst_dir $file ]
        ::StarkitGenerator::MkDir [ file dirname $dst_file ]
        file copy -force $src_file $dst_file
        lappend dst_files $dst_file
    }

    return $dst_files
}

#=======================================================================

proc ::StarkitGenerator::Delete_Files_And_Empty_Dir { files_list } {
    # FIXME: for now proc deletes only <file dirname> of files_list empty dirs
    # In general case it is better to check for emptyness
    # <file dirname> of <file dirname>

    set check_dirs {}

    foreach file $files_list {
        file delete -force $file
        set sub_dir [ file dirname $file ]
        if { [ lsearch $check_dirs $sub_dir ] < 0 } {
            lappend check_dirs $sub_dir
        }
    }

    foreach check_dir $check_dirs {
        # Caution: does not check for hidden files
        if { [ glob -nocomplain -directory $check_dir * ] == "" } {
            file delete -force $check_dir
        }
    }
}

#=======================================================================

proc ::StarkitGenerator::Log_Msg { msg } {

    variable ::StarkitGenerator::LOG_CMD

    if { $LOG_CMD == "" } return

    eval [ concat $LOG_CMD [ list $msg ] ]
}

#=======================================================================

proc ::StarkitGenerator::Generate_Kits { sdx_name kit_lst kit_type target_platforms starkit_dir output_dir args } {

    variable ::StarkitGenerator::LOG_CMD

    set LOG_CMD [ ::CmnTools::Get_Arg -logcmd args -default "" ]

    set vfs_top_dir [ ::StarkitGenerator::MkDir [ file join $starkit_dir tmp ] ]

    # Initializing generation mechanism
    ::StarkitGenerator::Init \
        $sdx_name \
        $starkit_dir \
        $output_dir \
        $vfs_top_dir \
        $target_platforms \
        $kit_type

    # Generation
    foreach kit $kit_lst {
        ::StarkitGenerator::Log_Msg "\nGenerating starkit <$kit>, type $kit_type..."
        ::StarkitGenerator::Generate_One_Kit $kit $kit_type $starkit_dir $output_dir $vfs_top_dir $target_platforms
        ::StarkitGenerator::Log_Msg "\nGenerating starkit <$kit>, type $kit_type...Done"
    }

    # Cleaning
    file delete -force $vfs_top_dir
}

#=======================================================================

proc ::StarkitGenerator::Generate_One_Kit { kit kit_types starkit_dir output_dir vfs_top_dir target_platforms } {

    file delete -force $vfs_top_dir/$kit.vfs

    ::StarkitGenerator::Log_Msg "\nCreating common directory structures and files..."

    set vfs_src_subdir lib/$kit
    set kit_dir  [ ::StarkitGenerator::MkDir [ file join $vfs_top_dir $kit.vfs $vfs_src_subdir ] ]

    # Copying main.tcl kit file
    file copy -force \
        [ file join $starkit_dir ${kit}_main.tcl ] \
        [ file join $vfs_top_dir $kit.vfs main.tcl ]

    # Copying ico kit file
    if [ file exists [ file join $starkit_dir tclkit.ico ] ] {
        file copy -force \
            [ file join $starkit_dir tclkit.ico ] \
            [ file join $vfs_top_dir $kit.vfs tclkit.ico ]
    }

    set pkg [ string totitle $kit ]
    package require Make$pkg

    set src_dir [ file dirname $starkit_dir ]

    set src_files_list [ ::Make${pkg}::Get_Common_Files_List $src_dir ]

    ::StarkitGenerator::Copy_Files_Between_Directories $src_dir $kit_dir $src_files_list

    file copy -force \
        [ file join $src_dir pkgIndex.tcl ] \
        [ file join $kit_dir pkgIndex.tcl ]

    ::StarkitGenerator::Log_Msg "Creating common directory structures and files...Done"

    # Creating StarKits
    foreach platform $target_platforms {
        ::StarkitGenerator::Log_Msg "\nCreating platform specific directory structures and files..."

        set src_files_list [ ::Make${pkg}::Get_Platform_Specific_Files_List $platform $src_dir/difftools/$platform ]

        set dst_files_list [ ::StarkitGenerator::Copy_Files_Between_Directories $src_dir/difftools/$platform $kit_dir/difftools $src_files_list ]
        
        ::StarkitGenerator::Log_Msg "Creating platform specific directory structures and files...Done"

        ::StarkitGenerator::Log_Msg "\nGenerating <$kit> for $platform..."
        foreach type $kit_types {
            ::StarkitGenerator::Make_Starkit $kit $platform $type $output_dir $vfs_top_dir
        }
        ::StarkitGenerator::Log_Msg "Generating <$kit> for $platform...Done"

        ::StarkitGenerator::Delete_Files_And_Empty_Dir $dst_files_list
    }

    package forget Make$pkg
}

#===============================================================================
