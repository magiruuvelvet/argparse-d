module tests.printer;

import dunit;

import argparse;

@Tag("PrinterTest")
class PrinterTest
{
    mixin UnitTest;

    @Test
    @Tag("PrinterTest.printerDefault")
    void printerDefault()
    {
        ArgumentParser parser = ["app"];
        parser.addHelpOption("Print this help and exit");
        parser.addArgument("", "version", "Show application version and exit", Argument.Boolean);
        parser.addArgument("v", "verbose", "Enable verbose output", Argument.Boolean);
        parser.addArgument("s", "", "Just a short option");

        const auto fmt = parser.help();
        const expected =
            "    -h, --help              Print this help and exit\n" ~
            "    --version               Show application version and exit\n" ~
            "    -v, --verbose           Enable verbose output\n" ~
            "    -s                      Just a short option\n";

        assertEquals(fmt, expected);
    }

    @Test
    @Tag("PrinterTest.printerCustom")
    void printerCustom()
    {
        ArgumentParser parser = ["app"];
        parser.addHelpOption("Print this help and exit");
        parser.addArgument("", "version", "Show application version and exit", Argument.Boolean);
        parser.addArgument("v", "verbose", "Enable verbose output", Argument.Boolean);
        parser.addArgument("s", "", "Just a short option");

        const auto fmt = parser.help(0, 0);
        const expected =
            "-h, --help    Print this help and exit\n" ~
            "--version     Show application version and exit\n" ~
            "-v, --verbose Enable verbose output\n" ~
            "-s            Just a short option\n";

        assertEquals(fmt, expected);
    }

    @Test
    @Tag("PrinterTest.printerCustomVisualized")
    void printerCustomVisualized()
    {
        ArgumentParser parser = ["app"];
        parser.addHelpOption("Print this help and exit");
        parser.addArgument("", "version", "Show application version and exit", Argument.Boolean);
        parser.addArgument("v", "verbose", "Enable verbose output", Argument.Boolean);
        parser.addArgument("s", "", "Just a short option");

        const auto fmt = parser.help(true);
        const expected =
            "    -h, --help              Print this help and exit\n" ~
            "    --version               Show application version and exit\n" ~
            "    -v, --verbose           Enable verbose output\n" ~
            "    -s [value]              Just a short option\n";

        assertEquals(fmt, expected);
    }

    @Test
    @Tag("ParserTest.unicode")
    void unicode()
    {
        ArgumentParser parser = ["app"];
        parser.addHelpOption("このヘルプを表示");
        parser.addArgument("コ", "コマンド", "コマンド");

        const auto fmt = parser.help();
        const expected =
            "    -h, --help                このヘルプを表示\n" ~
            "    -コ, --コマンド           コマンド\n";

        assertEquals(fmt, expected);
    }
}
