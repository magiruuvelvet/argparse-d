module argparse.argparse;

import argparse.argument;

/++
 + Simple stupid command line parser for D.
 +
 + An unobtrusive and i18n-friendly command line parser
 +
 +/
struct ArgumentParser
{
nothrow @safe:
public:
    /++
     + Parsing result status codes.
     +/
    enum Result : ushort
    {
        Success = 0,
        InsufficientArguments,      // too less arguments given
        MissingArgument,            // a required argument not provided

        Unknown = ushort.max,
    }

    /++
     + Returns a list of missing arguments once they were `parsed()`.
     +/
    const(string[]) missingArguments() const @safe
    {
        if (!this.parsed)
        {
            return [];
        }

        return this._missingArguments;
    }

    /++
     + Create an instance of the ArgumentParser and pass it the given
     + arguments as argument. The constructor only prepares some internals.
     + To do the actual parsing, call the `parse()` method.
     +/
    this(in string[] args, in string shortOptionPrefix = "-", in string longOptionPrefix = "--") @safe
    {
        // duplicate all arguments so they are self contained within the parser
        this.args = args.dup;

        // option prefixes
        this.shortOptionPrefix = shortOptionPrefix;
        this.longOptionPrefix = longOptionPrefix;
    }

    /++
     + Adds a new argument to the argument parser.
     +/
    bool addArgument(in Argument argument) @safe
    {
        if (this.parsed) return false;
        return this.addArgumentInternal(argument);
    }

    /++
     + Adds a new argument to the argument parser.
     + Forwards all arguments to the `Argument` struct.
     +/
    bool addArgument(Args...)(in Args args) @safe
    {
        if (this.parsed) return false;
        return this.addArgument(Argument(args));
    }

    /++
     + Convenience function to add a help option.
     + Only the description must be provided.
     +/
    bool addHelpOption(in string description) @safe
    {
        if (this.parsed) return false;
        return this.addArgument(Argument("h", "help", description, Argument.Boolean, false));
    }

    /++
     + Do the command line parsing. The status is returned
     + as an enum to check what happened.
     +
     + There is no exception based error handling available.
     +/
    Result parse() @safe
    {
        // avoid multiple parsing steps
        if (this.parsed)
        {
            return this.parsingResult;
        }

        // do the actual parsing
        import parser = argparse.internal.parser;
        const Result result = parser.parse(
            this,
            this.args,
            this.arguments,
            this.shortOptionPrefix,
            this.longOptionPrefix);
        this.parsed = true;
        this.parsingResult = result;
        return result;
    }

    /++
     + Formats a string for printing all registered command line arguments
     + and their description in a pretty way.
     +/
    const(string) help(in ubyte indentation = 4, in ubyte spacing = 10) const @safe
    {
        return this.help(false, "", indentation, spacing);
    }

    /++
     + Formats a string for printing all registered command line arguments
     + and their description in a pretty way.
     +
     + This overload supports visualizing string options with a custom
     + value suffix (defaults to `" [value]"`).
     +/
    const(string) help(
        in bool visualizeStringOptions, in string stringOptionSuffix = " [value]",
        in ubyte indentation = 4, in ubyte spacing = 10) const @safe
    {
        // don't do anything if there are no registered arguments
        if (this.arguments.length == 0)
        {
            return "";
        }

        import printer = argparse.internal.printer;
        return printer.format(
            this.arguments,
            visualizeStringOptions,
            stringOptionSuffix,
            indentation,
            spacing,
            this.shortOptionPrefix,
            this.longOptionPrefix);
    }

    /++
     + Is the given argument present on the command line?
     +/
    bool exists(in string name) const @safe
    {
        if (this.parsingResult != Result.Success)
        {
            return false;
        }

        try
        {
            foreach (ref const arg; this.arguments)
            {
                if (arg.present && (arg.name == name || arg.shortName == name || arg.longName == name))
                {
                    return true;
                }
            }
        }
        catch (Exception)
        {
            return false;
        }

        return false;
    }

    /++
     + Returns the parsed value of the given argument.
     +
     + If the argument was not found a default initialized value
     + will be returned.
     +
     + If a casting error ocurred a default initialized value
     + will be returned.
     +
     + If you need to check for the existence of a command line argument,
     + use the `exists()` method instead.
     +
     + For boolean switches always use the `exists()` method, rather than
     + casting a string representation of the boolean into an actual boolean.
     +
     + Params:
     +   name   = name of the option, long name preferred and falls back to short name
     +   ok     = optional boolean pointer to check for casting errors if needed
     +/
    auto get(T = string)(in string name, bool *ok = null) const @safe
    {
        if (this.parsingResult != Result.Success)
        {
            if (ok) *ok = false;
            return T.init;
        }

        static if (is(T == bool))
        {
            if (ok) *ok = true;
            return this.exists(name);
        }
        else
        {
            try
            {
                foreach (ref const arg; this.arguments)
                {
                    if (arg.present && (arg.name == name || arg.shortName == name || arg.longName == name))
                    {
                        if (ok) *ok = true;
                        return arg.get!T(ok);
                    }
                }
            }
            catch (Exception)
            {
                if (ok) *ok = false;
                return T.init;
            }

            if (ok) *ok = false;
            return T.init;
        }
    }

private:
    @disable this();      // disallow default construction
    @disable this(this);  // disallow copy

    bool parsed = false;
    Result parsingResult = Result.Unknown;

    /// copy of command line arguments
    string[] args = null;

    /// internal arguments array
    Argument[] arguments;

    string[] argumentsLongRegistry = [];
    string[] argumentsShortRegistry = [];

    string shortOptionPrefix = "-";
    string longOptionPrefix = "--";

package:
    string[] _missingArguments = [];

private:
    bool addArgumentInternal(Argument argument) @safe
    {
        // reset state before adding
        argument.reset();

        // refuse to add invalid argument
        if (!argument.isValid())
        {
            return false;
        }

        // check if already added
        import std.algorithm.searching : canFind;
        if (argument.longName.length != 0 && this.argumentsLongRegistry.canFind(argument.longName))
        {
            return false;
        }
        if (argument.shortName.length != 0 && this.argumentsShortRegistry.canFind(argument.shortName))
        {
            return false;
        }

        // add copy to internal array
        this.argumentsLongRegistry ~= argument.longName.length != 0 ? [argument.longName] : [];
        this.argumentsShortRegistry ~= argument.shortName.length != 0 ? [argument.shortName] : [];
        this.arguments ~= argument;
        return true;
    }
}

alias ArgumentParserResult = ArgumentParser.Result;
