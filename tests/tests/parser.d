module tests.parser;

import dunit;

import argparse;

@Tag("ParserTest")
class ParserTest
{
    mixin UnitTest;

    static string[] args1 = ["app", "--help"];
    static string[] args2 = ["app", "--version"];

    void registerDefaultArguments(ref ArgumentParser parser)
    {
        parser.addHelpOption("Print this help and quit");
        parser.addArgument("v", "version", "Show application version", Argument.Boolean);
    }

    @Test
    @Tag("ParserTest.simple1")
    void simple1()
    {
        ArgumentParser parser = args1;
        this.registerDefaultArguments(parser);
        const auto res = parser.parse();

        assertEquals(res, ArgumentParserResult.Success);
        assertTrue(parser.exists("help"));
        assertFalse(parser.exists("version"));
    }

    @Test
    @Tag("ParserTest.simple2")
    void simple2()
    {
        ArgumentParser parser = args2;
        this.registerDefaultArguments(parser);
        const auto res = parser.parse();

        assertEquals(res, ArgumentParserResult.Success);
        assertFalse(parser.exists("help"));
        assertTrue(parser.exists("version"));

        assertEquals(parser.loseArguments(), []);
    }

    @Test
    @Tag("ParserTest.requiredArgument")
    void requiredArgument()
    {
        ArgumentParser parser = args1;
        this.registerDefaultArguments(parser);
        assertTrue(parser.addArgument("", "required", "", Argument.String, true));
        const auto res = parser.parse();

        assertEquals(res, ArgumentParserResult.MissingArgument);
        assertFalse(parser.exists("required"));
        assertEquals(parser.missingArguments(), ["required"]);

        assertEquals(parser.loseArguments(), []);
    }

    @Test
    @Tag("ParserTest.booleanSwitch")
    void booleanSwitch()
    {
        ArgumentParser parser = ["app", "--enabled", "value", "--unused", "abc"];
        assertTrue(parser.addArgument("e", "enabled", "", Argument.Boolean));
        const auto res = parser.parse();

        assertEquals(res, ArgumentParserResult.Success);
        assertTrue(parser.exists("e"));
        assertTrue(parser.exists("enabled"));
        assertEquals(parser.get("enabled"), "true"); // boolean switches don't have values

        assertEquals(parser.loseArguments(), ["value", "abc"]);
    }

    @Test
    @Tag("ParserTest.valueSwitch")
    void valueSwitch()
    {
        ArgumentParser parser = ["app", "--enabled", "--value", "abc"];
        assertTrue(parser.addArgument("e", "enabled", "", Argument.Boolean));
        assertTrue(parser.addArgument("", "value", ""));
        const auto res = parser.parse();

        assertEquals(res, ArgumentParserResult.Success);
        assertTrue(parser.exists("e"));
        assertTrue(parser.exists("enabled"));
        assertEquals(parser.get("enabled"), "true");

        assertEquals(parser.get("value"), "abc");
        assertEquals(parser.get("nonexistend"), "");

        assertEquals(parser.loseArguments(), []);
    }

    @Test
    @Tag("ParserTest.multipleValues")
    void multipleValues()
    {
        ArgumentParser parser = ["app", "--value", "abc", "def", "--value2", "xyz"];
        this.registerDefaultArguments(parser);
        assertTrue(parser.addArgument("", "value", ""));
        assertTrue(parser.addArgument("", "value2", ""));
        assertFalse(parser.addArgument("", "value", ""));
        const auto res = parser.parse();

        assertEquals(res, ArgumentParserResult.Success);
        assertFalse(parser.exists("help"));
        assertEquals(parser.get("value"), "abc");
        assertEquals(parser.get("value2"), "xyz");

        assertEquals(parser.loseArguments(), ["def"]);
    }

    @Test
    @Tag("ParserTest.castingTestSuccess")
    void castingTestSuccess()
    {
        ArgumentParser parser = ["app", "--value", "10"];
        parser.addArgument("", "value", "");
        const auto res = parser.parse();

        assertEquals(res, ArgumentParserResult.Success);
        assertTrue(parser.exists("value"));

        bool ok;
        auto value = parser.get!int("value", &ok);
        assertTrue(ok);
        assertEquals(value, 10);

        value = parser.get!int("value");
        assertEquals(value, 10);

        assertEquals(parser.loseArguments(), []);
    }

    @Test
    @Tag("ParserTest.castingTestFailure")
    void castingTestFailure()
    {
        ArgumentParser parser = ["app", "--value", "3.1415"];
        parser.addArgument("", "value", "");
        const auto res = parser.parse();

        assertEquals(res, ArgumentParserResult.Success);
        assertTrue(parser.exists("value"));

        bool ok;
        auto value = parser.get!int("value", &ok);
        assertFalse(ok);
        assertEquals(value, 0);

        value = parser.get!int("value");
        assertEquals(value, 0);

        auto value2 = parser.get!float("value", &ok);
        assertTrue(ok);
        assertGreaterThan(value2, 3.1); // don't do exact comparisson due to floating point madness

        assertEquals(parser.loseArguments(), []);
    }

    @Test
    @Tag("ParserTest.unicode")
    void unicode()
    {
        ArgumentParser parser = ["app", "--コマンド", "表示", "--version"];
        this.registerDefaultArguments(parser);
        parser.addArgument("コ", "コマンド", "");
        const auto res = parser.parse();

        assertEquals(res, ArgumentParserResult.Success);
        assertFalse(parser.exists("help"));
        assertTrue(parser.exists("version"));
        assertTrue(parser.exists("コ"));
        assertTrue(parser.exists("コマンド"));
        assertEquals(parser.get("コマンド"), "表示");
        assertEquals(parser.get("コ"), "表示");

        assertEquals(parser.loseArguments(), []);
    }

    @Test
    @Tag("ParserTest.loseArguments")
    void loseArguments()
    {
        ArgumentParser parser = ["app", "--value", "abc", "def", "--value2", "xyz", "lose1", "lose2", "--unused", "lose3"];
        this.registerDefaultArguments(parser);
        assertTrue(parser.addArgument("", "value", ""));
        assertTrue(parser.addArgument("", "value2", ""));
        assertFalse(parser.addArgument("", "value", ""));
        const auto res = parser.parse();

        assertEquals(res, ArgumentParserResult.Success);
        assertFalse(parser.exists("help"));
        assertEquals(parser.get("value"), "abc");
        assertEquals(parser.get("value2"), "xyz");
        assertFalse(parser.exists("unused"));

        assertEquals(parser.loseArguments(), ["def", "lose1", "lose2", "lose3"]);
    }

    @Test
    @Tag("ParserTest.termination")
    void termination()
    {
        ArgumentParser parser = ["app", "--value", "abc", "--", "def", "--value2", "xyz", "lose1", "lose2", "--unused", "lose3"];
        this.registerDefaultArguments(parser);
        assertTrue(parser.addArgument("", "value", ""));
        assertTrue(parser.addArgument("", "value2", ""));
        assertFalse(parser.addArgument("", "value", ""));
        parser.setTerminator();
        const auto res = parser.parse();

        assertEquals(res, ArgumentParserResult.Success);
        assertFalse(parser.exists("help"));
        assertEquals(parser.get("value"), "abc");
        assertEquals(parser.get("value2"), "");
        assertFalse(parser.exists("unused"));

        assertEquals(parser.loseArguments(), []);
        assertEquals(parser.remainingArguments(), ["def", "--value2", "xyz", "lose1", "lose2", "--unused", "lose3"]);
    }

    @Test
    @Tag("ParserTest.termination2")
    void termination2()
    {
        ArgumentParser parser = ["app", "--value", "abc", "--"];
        this.registerDefaultArguments(parser);
        parser.setTerminator();
        const auto res = parser.parse();

        assertEquals(res, ArgumentParserResult.Success);

        assertEquals(parser.loseArguments(), ["abc"]);
        assertEquals(parser.remainingArguments(), []);
    }
}
