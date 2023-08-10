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


@dataclass
class CompileCommand:
    file: str | Path
    output: str | Path
    directory: str | Path
    arguments: list

    @classmethod
    def from_cmdline(cls,
        cc_cmd: Path,
        cmd_args: list[str],
        directory: (str | Path | None) = None
    ) -> Optional["CompileCommand"]:
        """ cmd_args should already be split with shlex.split or similar. """

        if cc_cmd.name not in cmd_args[0]:
            return None

        if directory is None:
            directory = Path.cwd()
        else:
            directory = Path(directory)

        # Heuristic: look for a `-o <name>` and then look for a file matching that pattern.
        output_index = cmd_args.index("-o")
        if not output_index:
            # If we can't get any output-setting argument at all, though, then we can't set `file`,
            # so all we can do is skip this line.
            return None

        output_path = directory / Path(cmd_args[output_index + 1])
        input_file_index = list_index_with_stem(cmd_args, output_path.stem)
        if not input_file_index:
            print(f"No argument in cmdline matches stem of {output_path}. Skipping.")
            return None

        input_file = directory / cmd_args[input_file_index]

        return cls(
            file=str(input_file),
            arguments=cmd_args,
            directory=str(directory),
            output=str(output_path),
        )


def list_index_with_stem(l: list, stem: str) -> Optional[int]:
    for index, item in enumerate(l):
        path = Path(item)
        if path.stem == stem:
            return index
        #if item.startswith(stem):
        #    return index

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("logfile", type=argparse.FileType("r"))
    parser.add_argument("cc_command")

    args = parser.parse_args()
    logfile = args.logfile
    cc_cmd = args.cc_command
    cc_path = Path(cc_cmd)
    if cc_path.is_absolute():
        cc_cmd = cc_path.name

    dirstack = [os.getcwd()]
    entries = []

    for line in logfile:

        # Skip empty lines.
        if not line:
            continue

        dirchange_match = DIRCHANGE_PATTERN.search(line)
        if dirchange_match:
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
