#!/usr/bin/python3
import os.path
import sys

import pytest

if __name__ == "__main__":
    sys.path.insert(0, os.path.dirname(__file__))
    pytest.main(["tests", *sys.argv])
