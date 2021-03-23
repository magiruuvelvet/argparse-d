# argparse

**Simple stupid command line parser for D**

This library is partially inspired by and older version of [argparse](https://github.com/jamolnng/argparse)
which I use in my C++ command line applications. The parser only supports boolean and string options,
while boolean options are always true when present. The public API is similar to the C++ library, but
exceptions were replaced with status codes, so you can use it in exception-free code easily.

This library is entirely exception-free. All possible exceptions which can be thrown are handled
internally and are translated to status codes. All of the public exposed functions are marked as `nothrow`
and all of them are either `@safe` or `@trusted`.

## Features

 - boolean options
 - string options
 - i18n-friendly
 - very customizable and unobtrusive
 - doesn't inject any options by default (everything provided by the developer)
 - termination (disabled by default, default once activated: `--`)
 - lose values (there are no positional arguments)

## Usage

### from CMake

Use [shared-cmake-modules](https://github.com/magiruuvelvet/shared-cmake-modules) for
you project and add this library as git submodule somewhere in your repository.

Add this somewhere `CreateTargetFromPath(argparse "path/to/argpase/src" STATIC "libargparse" D 2)`.

Use the target `target_link_libraries(yourtarget PRIVATE libs::argparse)`.

### from dub

This library isn't hosted on `code.dlang.org`, but there is a `dub.json` available.
I'm not sure though if dub can add dependencies from local paths.

## Example

`./app --value abc`

```d
import argparse;

void main(string[] args)
{
    ArgumentParser parser = args;
    parser.addArgument("h", "help", "Show this help and exit", Argument.Boolean);
    parser.addArgument("", "version", "Show version information and exit", Argument.Boolean);
    parser.addArgument("v", "value", "Provide a value");
    const ArgumentParserResult res = parser.parse();

    // ArgumentParserResult can be one of Success, InsufficientArguments, MissingArgument and Unknown

    bool hasValue = parser.exists("value"); // was --value provided on the command line?
    string value = parser.get("value"); // get value of --value, contains "abc"
}
```

## API

 - `bool ArgumentParser::addArgument(string shortName, string longName, string description, ...)`:\
   Registers a new argument in the parser to process. An argument can consist of either a
   short name, long name or both. Duplicate names are not allowed. The order or registration
   is preserved when generating help output using `ArgumentParser::help()`. The return value
   can be used to check whenever the argument was added or not, returns false only on duplicates.
   Overlapping of short and long options is correctly handled.

 - `bool ArgumentParser::addHelpOption(string description)`:\
   Convenience function to add a help option. Only the description must be provided.
   The parser doesn't include a help option by default and must be explicitly provided
   by the developer. The library has a built-in help printer though when desired.
   One can always write their own help printer. The rationale behind this design decision
   is i18n (Internationalization) and fine gained customization of all command line arguments.
   I don't want to inject something English hardcoded by default like `std.getopt` does.

 - `string ArgumentParser::help()`:\
   Generates a pretty formatted help output. This string contains only the options
   with their description and nothing else. Additional output when printing help
   is up to the developer. The indentation and spacing can be customized.

 - `void ArgumentParser::setTerminator(string)`:\
   Sets the parsing terminator at were to stop parsing arguments. By default no termination
   is performed. Calling this function without arguments makes `--` the terminator.
   Passing an empty string disables the terminator again.

 - `Result ArgumentParser::parse()`:\
   Does the parsing, once arguments were registered. The status is returned as enum.
   This function does nothing when there are no registered arguments or when `parse()`
   was already called (protected against multiple invocations).

 - `string[] ArgumentParser::missingArguments()`:\
   Contains a list of all registered arguments which were missing during the parsing when they
   were marked as required.

 - `string[] ArgumentParser::loseArguments()`:\
   Contains a list of all unused and lose arguments which weren't matched during parsing.

 - `string[] ArgumentParser::remainingArguments()`:\
   Contains a list of all arguments after the terminator, excluding the terminator itself.

 - `bool ArgumentParser::exists(string)`:\
   Check if the argument with the name is present on the command line. Only registered arguments are checked.

 - `T ArgumentParser::get!T(string)`:\
   Receive the value from the argument, defaults to string if template argument is omitted.
   On casting errors a default initialized value of the data type is returned.

**Format of command line arguments:** `-s value --long-option value value2 --boolean -a value -b`

 - `-s`(String) has value `"value"`
 - `--long-option`(String) has value `"value"`
 - `--boolean`(Boolean) is present and true
 - `-a`(String) has value `"value"`
 - `-b`(String) has value `""` (empty string options are allowed)
 - unused and lose values are stored in an array (`"value2"`)

## Why?

I wrote this because I dislike the built-in `std.getopt` from Phobos. It may do a lot of magic,
but magic is not always desirable and `getopt` also has weird defaults like case insensitive matching
enabled by default, or dying on unknown arguments, or manipulating the `args` array instead
of leaving it in tact. There is also no clean way to check for the presence of an argument.

This command line parser is supposed to be simple and **stupid**. You need to handle most
of the things yourself as developer. It just implements a convenient way to receive arguments
in a safe manner so you don't need to worry about index out of bounds, etc.

Supported are:

 - boolean switches which are always true once present, there is **no** `-b=false` syntax, and
 - string switches which can take a value or not, if value is omitted an empty string is assumed.

## Credits

argparse has a renamed copy of [dokutoku/wcwidth-compat](https://github.com/dokutoku/wcwidth-compat)
embedded for usage with the built-in help printer. The renaming was done to avoid eventual conflicts
when your project already contains a version of wcwidth to avoid naming conflicts. All `extern (C)`
attributes were removed too, to really avoid naming conflicts and linker errors all the way down.
