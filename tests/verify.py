import os
import sys
import glob
import pathlib
import re
import pandas as pd

path = os.path.abspath(os.path.dirname(__file__))
RKTCPU_PATH=path + "/../python"
sys.path.append(RKTCPU_PATH)

from rktcpu.model import RktCpuModel

# Get all test hex files.
tests = sorted(glob.glob("asm/test*.hex"))
for test in tests:
    # Generate the settings struct and new paths for log files
    _, tail = os.path.split(test)
    name = pathlib.Path(tail).stem
    logname = "logs/{}_golden.csv".format(name)
    settings = {
        "logpath"       : logname,
        "enablelogging" : True,
        "hexpath"       : test,
        "startingaddr"  : 0
    }

    # Create the model and run it for an arbitrary amount of time
    model = RktCpuModel(settings)
    for _ in range(2000):
        model.step()
    model.close()

outputs = sorted(["logs/" + f for f in os.listdir("logs/") if re.search(r'test\d+\.csv$', f)])
goldens = sorted(glob.glob("logs/test*_golden.csv"))
for output, golden in zip(outputs, goldens):
    # Get the log from the HDL simulation.
    df = pd.read_csv(output)
    # Filter the log for valid register writes.
    # TODO: Check for invalid register writes...
    df = df[df.valid == "'1'"]
    df = df[df.rdwen == "'1'"]
    # Reset the index but keep the past index so we can check specific rows in the CSV
    df.reset_index(inplace=True, drop=False)

    # Get the log of the golden model for comparison.
    golden_df = pd.read_csv(golden)
    # Trim the golden log to fit only the amount of time the HDL simulation was run for.
    golden_df_head = golden_df.head(df.shape[0])
    # Combine the golden log with the simulation log for easier comparison.
    df["golden_pc"] = golden_df_head.pc
    df["golden_rd"] = golden_df_head.rd
    df["golden_res"] = golden_df_head.res
    
    print(80 * "*")
    print("Test: {}".format(output))
    print(80 * "*")
    comparison = df.apply(lambda row: not all(i in row.golden_pc for i in row.pc), axis=1)
    print("> Differing PC values: {}".format(comparison.sum()))
    comparison = df.apply(lambda row: not all(i in row.golden_rd for i in row.rd), axis=1)
    print("> Differing RD values: {}".format(comparison.sum()))
    comparison = df.apply(lambda row: not all(i in row.golden_res for i in row.res), axis=1)
    print("> Differing RES values: {}".format(comparison.sum()))