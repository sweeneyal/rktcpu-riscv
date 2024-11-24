namespace eval rktcpu_rv_tools {
    variable home [file dirname [file normalize [info script]]]

    variable version "v0.1.0"

    namespace export autoinit
    namespace export get_ip_repo
    namespace export initialize
    namespace export read_project_sources
    namespace export read_library_sources
}

# Get the repository path of the IP
proc rktcpu_rv_tools::get_ip_repo {} {
    return [file dirname $home]
}

# Initializes the project by including the universal files as a dependency,
# then reading the project sources.
proc rktcpu_rv_tools::initialize {} {
    source $home/libraries/universal/tcl/universal.tcl
    rktcpu_rv_tools::read_project_sources
}

# This is a configuration script that will read all required sources for the IP, assuming
# the IP is used as the top of the project.
proc rktcpu_rv_tools::read_project_sources {} {
    rktcpu_rv_tools::read_library_sources
}

# This is a script that will read all of this IP's internal source files.
proc rktcpu_rv_tools::read_library_sources {} {
    # Get all Peripherals files
    add_files $home/hdl/rtl/Peripherals/BramRom.vhd
    set_property library rktcpu [get_files BramRom.vhd]
    set_property file_type {VHDL 2008} [get_files BramRom.vhd]

    add_files $home/hdl/rtl/Peripherals/ByteAddrBram.vhd
    set_property library rktcpu [get_files ByteAddrBram.vhd]

    add_files $home/hdl/rtl/Peripherals/Cache.vhd
    set_property library rktcpu [get_files Cache.vhd]

    add_files $home/hdl/rtl/Peripherals/GpioRegister.vhd
    set_property library rktcpu [get_files GpioRegister.vhd]

    add_files $home/hdl/rtl/Peripherals/InstructionRom.vhd
    set_property library rktcpu [get_files InstructionRom.vhd]

    add_files $home/hdl/rtl/Peripherals/RamInterface.vhd
    set_property library rktcpu [get_files RamInterface.vhd]

    # Get all Processor/pkg files
    add_files $home/hdl/rtl/Processor/pkg/CsrDefinitions.vhd
    set_property library rktcpu [get_files CsrDefinitions.vhd]
    set_property file_type {VHDL 2008} [get_files CsrDefinitions.vhd]

    add_files $home/hdl/rtl/Processor/pkg/RiscVDefinitions.vhd
    set_property library rktcpu [get_files RiscVDefinitions.vhd]

    add_files $home/hdl/rtl/Processor/pkg/RktCpuDefinitions.vhd
    set_property library rktcpu [get_files RktCpuDefinitions.vhd]

    # Get all Processor files
    add_files $home/hdl/rtl/Processor/Adder.vhd
    set_property library rktcpu [get_files Adder.vhd]

    add_files $home/hdl/rtl/Processor/AluCore.vhd
    set_property library rktcpu [get_files AluCore.vhd]

    add_files $home/hdl/rtl/Processor/BarrelShift.vhd
    set_property library rktcpu [get_files BarrelShift.vhd]
    set_property file_type {VHDL 2008} [get_files BarrelShift.vhd]

    add_files $home/hdl/rtl/Processor/Bitwise.vhd
    set_property library rktcpu [get_files Bitwise.vhd]

    add_files $home/hdl/rtl/Processor/BramRegisterFile.vhd
    set_property library rktcpu [get_files BramRegisterFile.vhd]

    add_files $home/hdl/rtl/Processor/Bus2Axi.vhd
    set_property library rktcpu [get_files Bus2Axi.vhd]

    add_files $home/hdl/rtl/Processor/ControlEngine.vhd
    set_property library rktcpu [get_files ControlEngine.vhd]

    add_files $home/hdl/rtl/Processor/DualPortBram.vhd
    set_property library rktcpu [get_files DualPortBram.vhd]
    set_property file_type {VHDL 2008} [get_files DualPortBram.vhd]

    add_files $home/hdl/rtl/Processor/FetchEngine.vhd
    set_property library rktcpu [get_files FetchEngine.vhd]

    add_files $home/hdl/rtl/Processor/RktCpuRiscV.vhd
    set_property library rktcpu [get_files RktCpuRiscV.vhd]

    add_files $home/hdl/rtl/Processor/ZiCsr.vhd
    set_property library rktcpu [get_files ZiCsr.vhd]
}