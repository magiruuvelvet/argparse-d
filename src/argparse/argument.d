module argparse.argument;

struct Argument
{
nothrow @safe:
public:
    enum Type
    {
        String,  /// when present, next argument must be a value for the `Argument`
        Boolean, /// when present, next argument must be an `Argument`
    }

    alias String = Type.String;
    alias Boolean = Type.Boolean;

    this(in string shortName, in string longName, in string description,
         in Type type = Type.String, in bool required = false)
    {
        this._shortName = shortName;
        this._longName = longName;
        this._description = description;
        this._type = type;
        this._required = required;

        if (this._type == Boolean)
        {
            this._value = "false";
        }
    }

    this(in string shortName, in string longName, in string description, in string defaultValue,
         in Type type = Type.String, in bool required = false)
    {
        this(shortName, longName, description, type, required);
        this._defaultValue = defaultValue;
    }

    // read-only properties
    pragma(inline)
    {
        @property string shortName() const
        {
            return this._shortName;
        }

        @property string longName() const
        {
            return this._longName;
        }

        @property string description() const
        {
            return this._description;
        }

        @property Type type() const
        {
            return this._type;
        }

        @property bool required() const
        {
            return this._required;
        }

        @property string defaultValue() const
        {
            return this._defaultValue;
        }
    }

    // simple methods
    pragma(inline)
    {
        /// at least one variant must be set
        bool isValid() const
        {
            return this.shortName.length > 0 || this.longName.length > 0;
        }

        /// is a long name present
        bool hasShortName() const
        {
            return this.shortName.length > 0;
        }

        /// is a short name present
        bool hasLongName() const
        {
            return this.longName.length > 0;
        }

        /// does the argument has a default value
        bool hasDefaultValue() const
        {
            return this._defaultValue !is null;
        }

        /// is a value set for the argument
        bool hasValue() const
        {
            return this._value !is null;
        }

        /// returns the name of the option, longName is preferred, falls back to shortName
        @property string name() const
        {
            if (this.hasLongName())
            {
                return this.longName;
            }
            else if (this.hasShortName())
            {
                return this.shortName;
            }
            else
            {
                return "";
            }
        }

        /// attempt to convert the value to the given type
        auto get(T)(bool *ok = null) const
        {
            import std.conv : to;

            try
            {
                if (ok) *ok = true;
                if (!this.hasValue() && this.hasDefaultValue())
                {
                    return to!T(this._defaultValue);
                }
                else
                {
                    return to!T(this._value);
                }
            }
            catch (Exception)
            {
                if (ok) *ok = false;
                return T.init;
            }
        }
    }

    mixin template make_property_method(T, string name, string attribute = "this._" ~ name)
    {
        pragma(inline)
        {
            mixin("@property T " ~ name ~ "() { return " ~ attribute ~ "; }");
            mixin("@property const(T) " ~ name ~ "() const { return " ~ attribute ~ "; }");
            mixin("@property void " ~ name ~ "(in T val) { " ~ attribute ~ " = val; }");
        }
    }

    mixin make_property_method!(string, "value");
    mixin make_property_method!(bool,   "present");

private:
    @disable this();

    string _shortName;        /// short variant
    string _longName;         /// long variant
    string _description;      /// description
    Type _type = Type.String; /// value switch or boolean switch
    bool _required = false;   /// is the argument required

    string _value = null;     /// value once parsed or null if not present
    bool _present = false;    /// was the argument present during parsing

    string _defaultValue = null; /// default value when `_value` is null

package:
    /// reset argument to an unparsed state, called before registering in the parser
    void reset()
    {
        this._value = null;
        this._present = false;

        if (this._type == Boolean)
        {
            this._value = "false";
        }
    }
}
