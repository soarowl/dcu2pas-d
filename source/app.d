import argparse;

@(Command("dcu2pas").Description("Decompile dcu(Delphi Compiled Unit) to pas.")
        .Epilog(() => "Best wishes for your happiness and success"))
struct Config
{
    @(PositionalArgument(0).Description(() => "File to decompile"))
    string[] file;
}

mixin CLI!Config.main!((args) {
    // do whatever you need
    import std.stdio : writeln;

    args.writeln;
    return 0;
});
