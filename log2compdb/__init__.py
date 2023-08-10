import argparse
import json
import os
import shlex
import re
from typing import Optional
from pathlib import Path
import dataclasses
from dataclasses import dataclass

DIRCHANGE_PATTERN = re.compile(r"(?P<action>\w+) directory '(?P<path>.+)'")
INFILE_PATTERN = re.compile(r"(?P<path>.+\.(c|cpp|cxx|cc|h|hpp|hxx))", re.IGNORECASE)

@dataclass
class CompileCommand:
    file: str
    output: str
    directory: str
    arguments: list

    @classmethod
    def from_cmdline(cls,
        cc_cmd: Path,
        cmd_args: list[str],
        directory: (str | Path | None) = None
    ) -> Optional["CompileCommand"]:
        """ cmd_args should already be split with shlex.split or similar. """

        # If the user-supplied compiler isn't in this supposed argument list,
        # then this isn't any kind of compiler invocation we can detect.
        # Skip.
        if cc_cmd.name not in cmd_args[0]:
            return None

        cmd_args = cmd_args[:]
        cmd_args[0] = str(cc_cmd)

        if directory is None:
            directory = Path.cwd()
        else:
            directory = Path(directory)

        # Heuristic: look for a `-o <name>` and then look for a file matching that pattern.
        if output_index := cmd_args.index("-o"):

            output_path = directory / Path(cmd_args[output_index + 1])
            input_file_index = next(
                index for index, item in enumerate(cmd_args) if Path(item).stem == output_path.stem
            )
            if not input_file_index:
                print(f"No argument in cmdline matches stem of {output_path}. Skipping.")
                return None

            input_path = directory / cmd_args[input_file_index]
        else:
            # If that fails, though, then let's fall back to a regex.
            match = None
            for item in cmd_args:
                match = INFILE_PATTERN.search(item)
                if match:
                    break

            # If we couldn't find a single file with an expected extension though, bail.
            if not match:
                return None

            input_path = Path(match.groupdict()["path"])
            output_path = None


        return cls(
            file=str(input_path),
            arguments=cmd_args,
            directory=str(directory),
            output=str(output_path),
        )


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("-i", "--in", dest="logfile", type=argparse.FileType("r"), default="-",
        help="The build log file to parse.",
    )
    parser.add_argument("-o", "--out", dest="outfile", type=argparse.FileType("w"), required=True,
        help="The compile_commands.json file to write",
    )
    parser.add_argument("-c", "--compiler", dest="compiler",
        help="The compiler used in this build log. An absoute path is best but isn't requird.",
    )

    args = parser.parse_args()
    logfile = args.logfile
    cc_cmd = args.compiler
    cc_path = Path(cc_cmd)
    if cc_path.is_absolute():
        cc_cmd = cc_path.name

    dirstack = [os.getcwd()]
    entries = []

    for line in logfile:

        # Skip empty lines.
        if not line:
            continue

        if dirchange_match := DIRCHANGE_PATTERN.search(line):
            groups = dirchange_match.groupdict()
            action = groups["action"]
            path = groups["path"]
            if action == "Leaving":
                dirstack.pop()
            elif action == "Entering":
                dirstack.append(path)
            else:
                print(f"Unknown GNU Make directory operation {action}. Skipping.")
                continue

        cmd_args = shlex.split(line)

        # Skip lines that don't have a meaningful command.
        if not cmd_args:
            continue

        if cc_cmd in cmd_args[0]:
            entry = CompileCommand.from_cmdline(cc_path, cmd_args, dirstack[-1])
            entries.append(entry)

    if not entries:
        print("Didn't detect any compiler invocations! Refusing to overwrite with empty JSON.")

    json_entries = list(map(dataclasses.asdict, entries))

    with open("compile_commands.json", "w") as outfile:
        json.dump(json_entries, outfile, indent=4)

if __name__ == "__main__":
    main()
