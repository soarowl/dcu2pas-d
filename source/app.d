import darg, dcu;

struct Options
{
    @Option("help", "h")
    @Help("Prints this help.")
    OptionFlag help;

    @Argument("file", Multiplicity.zeroOrMore)
    @Help("Files to decompiled")
    string[] files;
}

// Generate the usage and help string at compile time.
immutable usage = usageString!Options("dcu2pas");
immutable help = helpString!Options;

int main(string[] args)
{
    import glob : glob;
    import std.stdio;

    Options options;

    try
    {
        options = parseArgs!Options(args[1 .. $]);
    }
    catch (ArgParseError e)
    {
        writeln(e.msg);
        writeln(usage);
        return 1;
    }
    catch (ArgParseHelp e)
    {
        // Help was requested
        writeln(usage);
        write(help);
        return 0;
    }

    foreach (file; options.files)
    {
        foreach (entry; glob(file))
        {
            writefln("%s decompiling....", entry);
            Dcu dcu = new Dcu();
            dcu.decompile(entry);
        }
    }
    writeln("Done.");

    return 0;
}
