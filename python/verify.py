import os
import glob
import pathlib
import re
import pandas as pd

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
    df = pd.read_csv(output)
    df = df[df["valid"] == "'1'"]
    df = df[df["rdwen"] == "'1'"]

    golden_df = pd.read_csv(golden)

    print(output)
    print(df["pc"])
    print(golden_df["pc"])

    # For all valid writes, I want to see:
    # 1. The PC is the same
    # 2. The RD is the same
    # 3. The RES is the same