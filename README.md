# log2compdb

This is a simple script to parse out compiler invocations from a build log and generate a `compile_commands.json`
compilation database. This might be useful on macOS or in any other case where [Bear](https://github.com/rizsotto/Bear)
doesn't work correctly. Theoretically any build log that contains full compiler invocations (e.g. `gcc -c -o foo.o
-DENABLE_SOME_FEATURE -I./include foo.c`) should work, but I've only tested pretty limited cases.

## Usage

`log2compdb` takes three arguments:

- The build log file, with `-i`/`--in`
- The path to the desired output file, with `-o`/`--out` (defaults to `compile_commands.json` in the current directory)
- The compiler used in that build log, with `-c`/`--compiler` — an absolute path works best, but isn't required
    - If your build log has multiple compilers (for example if your build includes host and cross compilation
        objects), then `-c` can be specified multiple times.

## Example

Let's take the [firmware repository](https://github.com/blackmagic-debug/blackmagic) for the Black Magic Probe
project for an example. Many build systems don't output the compiler invocations by default, requiring a variable
like `BUILD_VERBOSE=1` or `V=1`. In Blackmagic's case, it looks like this:

```bash
$ make V=1 > build.log
```

It can be important that you don't pass a `-j` argument (other than `-j1`), as `log2compdb` uses directory change
log entries as well, which will be out of order if you build in parallel.

Non-parallel builds can take a while, so you might want to include the build output in your terminal as well with
something like:

```bash
$ make V=1 | tee /dev/stdin > build.log
```

After that, you can run `log2compdb`, telling it the path to the build log, and the compiler used in the build.
In the case of the Black Magic Probe firmware, that's going to be `arm-none-eabi-gcc`, which on my system is in
`/opt/homebrew/bin`, so for me generating the `compile_commands.json` looks like this:

```bash
$ log2compdb -i build.log -o compile_commands.json -c /opt/homebrew/bin/arm-none-eabi-gcc
```

Alternatively, you can also tell `log2comp2db` to read from standard in, and skip the extra file:

```bash
$ make V=1 | tee /dev/stdin | log2compdb -o compile_commands.json -c /opt/homebrew/bin/arm-none-eabi/gcc
```

## Installation

`log2compdb` is packaged on [PyPI](https://pypi.org/project/log2compdb/), and can be installed with Python
packaging tools, such as pip:

```bash
$ pip install log2compdb
```
