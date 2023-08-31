import argparse
from collections.abc import MutableSequence
import dataclasses
from dataclasses import dataclass
import io
import json
import os
from pathlib import Path
import shlex
import typing
from typing import Optional, Sequence
import re

__version__ = "0.2.5"

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

        input_path = None

        # Heuristic: look for a `-o <name>` and then look for a file matching that pattern.
        if output_index := cmd_args.index("-o"):

            output_path = directory / Path(cmd_args[output_index + 1])

            # Prefer input files that match the expected pattern, but fall back to whatever has that stem.
            stem_matches = [item for item in cmd_args if Path(item).stem == output_path.stem]
            for item in stem_matches:
                if input_file_match := INFILE_PATTERN.search(item):
                    input_path = input_file_match.group("path")
                    break

                # If none of the files with a matching stem matched the regex, then we'll just guess
                # and grab the first file with a matching stem.
                input_path = next(iter(item), None)

            if not input_path:
                print(f"No argument in cmdline matches stem of {output_path}. Skipping.")
                return None

            input_path = directory / Path(input_path)
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

            input_path = Path(match.group("path"))
            output_path = None


        return cls(
            file=str(input_path),
            arguments=cmd_args,
            directory=str(directory),
            output=str(output_path),
        )

@dataclass
class Compiler:
    name: str
    path: Path

    @classmethod
    def from_argspec(cls, compiler_arg) -> "Compiler":
        """ `compiler_arg` is a value of --compiler verbatim. """

        path = Path(compiler_arg)
        if path.is_absolute():
            name = path.name
        else:
            name = compiler_arg

        return cls(name=name, path=path)


def get_entries(logfile: io.TextIOBase, compilers: Sequence[Compiler] | Compiler) -> list[CompileCommand]:
    """
    logfile: a file-like object for the build log, containing compiler invocations
    compilers: a list of `Compiler` objects representing the compilers to look for in the build log.
    """

    if isinstance(compilers, Compiler):
        # If `compilers` was specified as a single, non-sequence object, squish that into a single-element list.
        compilers = typing.cast(list[Compiler], [compilers])

    entries = []
    dirstack = [os.getcwd()]

    for line in logfile:

        # Skip empty lines.
        if not line:
            continue

        if dirchange_match := DIRCHANGE_PATTERN.search(line):
            action = dirchange_match.group("action")
            path = dirchange_match.group("path")
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

        for compiler in compilers:
            # Look for a compiler invocation anywhere in the command args,
            # but consider that the start of the arguments for further parsing.
            # A lot of build systems like to use a wrapper command in their compiler invocation.
            try:
                compiler_invocation_start = cmd_args.index(compiler.name)
                entry = CompileCommand.from_cmdline(compiler.path, cmd_args[compiler_invocation_start:], dirstack[-1])
                entries.append(entry)
            except ValueError:
                # As usual, ignore lines we don't understand.
                pass

    return entries


def main():
    parser = argparse.ArgumentParser("log2compdb")
    parser.add_argument("-i", "--in", dest="logfile", type=argparse.FileType("r"), default="-",
        help="The build log file to parse.",
    )
    parser.add_argument("-o", "--out", dest="outfile", type=argparse.FileType("w"), default="compile_commands.json",
        help="The compile_commands.json file to write",
    )
    parser.add_argument("-c", "--compiler", dest="compilers", action="append", required=True,
        help="The compiler used in this build log. An absolute path is best but isn't required. "
        "Can be specified multiple times if your build log uses multiple compilers",
    )
    parser.add_argument("--version", action="version", version=f"%(prog)s {__version__}")

    args = parser.parse_args()
    compilers = [Compiler.from_argspec(compiler) for compiler in args.compilers]

    entries = get_entries(args.logfile, compilers)

    if not entries:
        print("Didn't detect any compiler invocations! Refusing to overwrite with empty JSON.")

    json_entries = list(map(dataclasses.asdict, entries))

    json.dump(json_entries, args.outfile, indent=4)

if __name__ == "__main__":
    main()
