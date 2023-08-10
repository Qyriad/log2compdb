import json
import os.path
from pathlib import Path

import log2compdb
from log2compdb import CompileCommand, Compiler

CWD = Path(os.path.dirname(__file__))

def test_blackmagic():

    entries = []
    reference_entries = []

    with open(CWD / "blackmagic_build.log", "r") as build_log:
        compiler = Compiler.from_argspec("/usr/bin/arm-none-eabi-gcc")
        entries = log2compdb.get_entries(build_log, compiler)

    with open(CWD / "blackmagic.json", "r") as reference_json:
        reference_entries = json.load(reference_json)

    assert entries == reference_entries
