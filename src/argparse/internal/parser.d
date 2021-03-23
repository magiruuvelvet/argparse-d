module argparse.internal.parser;

import argparse.argparse;
import argparse.argument;

import std.string;
import std.conv : to;

nothrow:
private:

debug void safe_writefln(Args...)(Args args) @safe
{
    import std.stdio;
    try { writefln(args); } catch (Exception) {}
}

string shortOptionPrefix;
string longOptionPrefix;

enum OptionType
{
    Short,
    Long,
    Value,
    Unknown,
}

pragma(inline) @safe
{
    /// check registered arguments for required ones
    bool has_required_arguments(scope ref Argument[] registeredArguments)
    {
        try
        {
            foreach (ref const arg; registeredArguments)
            {
                if (arg.required)
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

    /// is the option a short option
    bool is_short_option(ref const(string) option)
    {
        return
            option.length >= shortOptionPrefix.length &&
            option[0..shortOptionPrefix.length] == shortOptionPrefix && !is_long_option(option);
    }

    /// is the option a long option
    bool is_long_option(ref const(string) option)
    {
        return
            option.length >= longOptionPrefix.length &&
            option[0..longOptionPrefix.length] == longOptionPrefix;
    }

    /// is the option a value
    bool is_value(ref const(string) option)
    {
        return !is_short_option(option) && !is_long_option(option);
    }

    /// get option type as enum
    const(OptionType) get_option_type(ref const(string) option)
    {
        if (is_short_option(option))
        { return OptionType.Short; }
        else if (is_long_option(option))
        { return OptionType.Long; }
        else if (is_value(option))
        { return OptionType.Value; }
        else return OptionType.Unknown;
    }

    /// get option name without prefix or value
    string get_option_name(ref const(string) option)
    {
        final switch (get_option_type(option))
        {
            case OptionType.Long:    return option[longOptionPrefix.length..$];
            case OptionType.Short:   return option[shortOptionPrefix.length..$];
            case OptionType.Value:   return option;
            case OptionType.Unknown: return option;
        }
    }
}

Argument *find_argument(scope ref Argument[] registeredArguments, ref const(string) name) @trusted
{
    try
    {
        foreach (ref argument; registeredArguments)
        {
            if (argument.name == name || argument.longName == name || argument.shortName == name)
            {
                return &argument;
            }
        }
    }
    catch (Exception)
    {
        return null;
    }

    return null;
}


public:

ArgumentParserResult parse(
    scope ref ArgumentParser parserInstance,
    scope ref const(string[]) args, scope ref Argument[] registeredArguments,
    in const(string) _shortOptionPrefix, in const(string) _longOptionPrefix,
    in const(string) terminator) @trusted
{
    alias Res = ArgumentParserResult;

    shortOptionPrefix = _shortOptionPrefix;
    longOptionPrefix = _longOptionPrefix;

    // check for required arguments
    const bool requiredArguments = has_required_arguments(registeredArguments);

    // args contain only the command and arguments are required
    if (args.length <= 1 && requiredArguments)
    {
        return Res.InsufficientArguments;
    }
    // no args given and no required arguments
    else if (args.length <= 1)
    {
        return Res.Success;
    }

    for (auto i = 1; i < args.length; ++i)
    {
        if (terminator.length > 0 && args[i] == terminator)
        {
            if ((i+1) < args.length)
            {
                parserInstance._remainingArguments = cast(string[]) args[i+1..$];
            }
            break;
        }

        /// get next option or null
        const auto next_option = delegate string(){
            if ((i+1) >= args.length)
            {
                return null;
            }
            else
            {
                return args[i+1];
            }
        };

        // debug safe_writefln("[%s] %s, %s, %s | %s", len, arg, get_option_type(arg), get_option_name(arg), next_option());

        const auto name = get_option_name(args[i]);
        const auto type = get_option_type(args[i]);

        if (type == OptionType.Long || type == OptionType.Short)
        {
            auto argument = find_argument(registeredArguments, name);

            if (argument is null)
            {
                continue;
            }

            // set argument to found
            argument.present = true;

            if (argument.type == Argument.Boolean)
            {
                argument.value = "true";
                continue;
            }
            else if (argument.type == Argument.String)
            {
                const auto next = next_option();
                if (next is null)
                {
                    argument.value = ""; // assume empty string, rather than an error
                    continue;
                }
                else
                {
                    if (is_value(next))
                    {
                        argument.value = next;
                        i++;
                        continue;
                    }
                    else
                    {
                        continue;
                    }
                }
            }
        }
        else if (type == OptionType.Value || type == OptionType.Unknown)
        {
            // found a lose argument
            parserInstance._loseArguments ~= [name];
        }
    }

    // check if required arguments are missing
    try
    {
        foreach (ref const argument; registeredArguments)
        {
            if (argument.required && !argument.present)
            {
                parserInstance._missingArguments ~= [argument.name];
            }
        }
    }
    catch (Exception)
    {
        return Res.Unknown;
    }

    if (parserInstance._missingArguments.length != 0)
    {
        return Res.MissingArgument;
    }

    return Res.Success;
}
