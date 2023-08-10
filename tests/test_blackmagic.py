import dataclasses
import json
import os.path
from pathlib import Path

import log2compdb
from log2compdb import CompileCommand, Compiler

CWD = Path(os.path.dirname(__file__))

def test_blackmagic():

    entries: list[CompileCommand] = []
    actual_json: list[dict]
    expected_json = []

    with open(CWD / "blackmagic_build.log", "r") as build_log:
        compiler = Compiler.from_argspec("/usr/bin/arm-none-eabi-gcc")
        entries = log2compdb.get_entries(build_log, compiler)
        actual_json = list(map(dataclasses.asdict, entries))

    with open(CWD / "blackmagic.json", "r") as reference_json:
        expected_json = json.load(reference_json)

    try:
        assert actual_json == expected_json
    except AssertionError:
        expected_name = f"{__name__}_expected.json"
        actual_name = f"{__name__}_actual.json"
        print(f"Test failed. Writting differing files to {expected_name} and {actual_name}")
        with open(CWD / expected_name, "w") as expected:
            json.dump(expected_json, expected, indent=4)

        with open(CWD / actual_name, "w") as actual:
            json.dump(actual_json, actual, indent=4)

        raise
