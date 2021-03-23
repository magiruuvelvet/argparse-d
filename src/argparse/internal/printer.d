module argparse.internal.printer;

import argparse.argparse;
import argparse.argument;
import argparse.internal.wcwidth;

import fmt = std.format : format;

nothrow @safe:
private:

ulong wcwidth_string(in string str) @safe
{
    ulong length = 0;

    try {
        foreach (dchar ch; str)
        {
            try {
                length += wcwidth(cast(uint) ch);
            } catch (Exception) {}
        }
    } catch (Exception) {}

    return length;
}

pragma(inline) string safe_format(Args...)(Args args) @safe
{
    try
    {
        return fmt.format(args);
    }
    catch (Exception)
    {
        return "";
    }
}

string make_spaces(in ubyte length) @safe
{
    string spaces;
    for (auto i = 0; i < length; ++i)
    {
        spaces ~= " ";
    }
    return spaces;
}


public:

const(string) format(
    scope const ref Argument[] arguments,
    in bool visualizeStringOptions, in string stringOptionSuffix,
    in ubyte indentation, in ubyte spacing,
    in const(string) shortOptionPrefix, in const(string) longOptionPrefix) @safe
{
    string help_text;
    ulong longest_option = 0;

    struct FormattedArgument
    {
        const string left;
        const string right;
    }

    FormattedArgument[] formatted_arguments;
    try
    {
        foreach (ref const arg; arguments)
        {
            const(string) build_left_part(ref ulong length)
            {
                string part;
                if (arg.hasShortName())
                {
                    part ~= shortOptionPrefix ~ arg.shortName;
                    if (arg.hasLongName())
                    {
                        part ~= ", ";
                    }
                }
                if (arg.hasLongName())
                {
                    part ~= longOptionPrefix ~ arg.longName;
                }
                if (visualizeStringOptions && arg.type == Argument.String)
                {
                    part ~= stringOptionSuffix;
                }
                length = wcwidth_string(part);
                return part;
            }

            ulong length = 0;
            formatted_arguments ~= [FormattedArgument(build_left_part(length), arg.description)];

            if (length > longest_option)
            {
                longest_option = length;
            }
        }
    }
    catch (Exception)
    {
        return "";
    }

    foreach (ref const arg; formatted_arguments)
    {
        string fill;
        for (auto i = 0; i < longest_option - wcwidth_string(arg.left); ++i)
        {
            fill ~= " ";
        }
        help_text ~= safe_format("%s%s %s%s%s\n", make_spaces(indentation), arg.left, fill, make_spaces(spacing), arg.right);
    }

    return help_text;
}
