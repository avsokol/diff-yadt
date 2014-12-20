global tcl_version
package ifneeded cmdline 1.2 [list source [file join $dir cmdline/cmdline.tcl]]
package ifneeded struct 1.2.1 [list source [file join $dir struct/struct.tcl]]
package ifneeded struct::list 1.8 [list source [file join $dir struct/list.tcl]]

package ifneeded tcllib 1.18 {
	catch {package require cmdline 1.2}
	catch {package require struct 1.2.1}
	tclLog "Don't do \"package require tcllib\", ask for individual modules."
}
