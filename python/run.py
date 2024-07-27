from vunit import VUnit
import pathlib

def get_vhdl_files(dir, recursive=False):
    directory = pathlib.Path(dir)
    if recursive:
        allVhdlFiles = list(directory.rglob('*.vhd'))
    else:
        allVhdlFiles = list(directory.glob('*.vhd'))
    return allVhdlFiles

# Create VUnit instance by parsing command line arguments
vu = VUnit.from_argv(['--gtkwave-fmt', 'ghw'])

# Optionally add VUnit's builtin HDL utilities for checking, logging, communication...
# See http://vunit.github.io/hdl_libraries.html.
vu.add_vhdl_builtins()
vu.add_osvvm()
# or
# vu.add_verilog_builtins()

universal = vu.add_library("universal")
files = get_vhdl_files('./libraries/universal/hdl', recursive=True)
for file in files:
    universal.add_source_file(file)

# Create library 'lib'
rktcpu = vu.add_library("rktcpu")
files = get_vhdl_files('./hdl/rtl', recursive=True)
for file in files:
    rktcpu.add_source_file(file)

tb = vu.add_library("tb")
files = get_vhdl_files('./hdl/tb', recursive=True)
for file in files:
    tb.add_source_file(file)

def encode(tb_cfg):
    return ", ".join(["%s:%s" % (key, str(tb_cfg[key])) for key in tb_cfg])

tb_cfg = dict(instructions="asm/test002.hex")
tb_ControlEngine = tb.test_bench('tb_ControlEngine')
tb_ControlEngine.add_config(name='Test002_AddImmed', generics=dict(encoded_tb_cfg=encode(tb_cfg)))

tb_cfg = dict(instructions="asm/test001.hex")
tb_RktCpuCore = tb.test_bench('tb_RktCpuCore')
tb_RktCpuCore.add_config(name='Test001_SimpleProgram', generics=dict(encoded_tb_cfg=encode(tb_cfg)))

tb_cfg = dict(instructions="asm/test002.hex")
tb_RktCpuCore = tb.test_bench('tb_RktCpuCore')
tb_RktCpuCore.add_config(name='Test002_AddImmed', generics=dict(encoded_tb_cfg=encode(tb_cfg)))

tb_cfg = dict(instructions="asm/test003.hex")
tb_RktCpuCore = tb.test_bench('tb_RktCpuCore')
tb_RktCpuCore.add_config(name='Test003_BranchAddImmed', generics=dict(encoded_tb_cfg=encode(tb_cfg)))

tb_cfg = dict(instructions="asm/test004.hex")
tb_RktCpuCore = tb.test_bench('tb_RktCpuCore')
tb_RktCpuCore.add_config(name='Test004_HazardAddImmed', generics=dict(encoded_tb_cfg=encode(tb_cfg)))

tb_cfg = dict(instructions="asm/test005.hex")
tb_RktCpuCore = tb.test_bench('tb_RktCpuCore')
tb_RktCpuCore.add_config(name='Test005_HazardAddRegAndImmed', generics=dict(encoded_tb_cfg=encode(tb_cfg)))

tb_cfg = dict(instructions="asm/test006.hex")
tb_RktCpuCore = tb.test_bench('tb_RktCpuCore')
tb_RktCpuCore.add_config(name='Test006_SqrtFunction', generics=dict(encoded_tb_cfg=encode(tb_cfg)))

tb_cfg = dict(instructions="asm/test007.hex")
tb_RktCpuCore = tb.test_bench('tb_RktCpuCore')
tb_RktCpuCore.add_config(name='Test007_WordMemoryAccesses', generics=dict(encoded_tb_cfg=encode(tb_cfg)))

# Run vunit function
vu.add_compile_option('ghdl.a_flags', ['-frelaxed'])
vu.set_sim_option('ghdl.elab_flags', ['-frelaxed'])
vu.main()