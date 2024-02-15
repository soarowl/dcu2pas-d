import argparse;
import glob : glob;

@(Command("dcu2pas").Description("Decompile dcu(Delphi Compiled Unit) to pas.")
        .Epilog(() => "Best wishes for your happiness and success"))
struct Config
{
    @(PositionalArgument(0).Description(() => "File to decompile"))
    string[] file;
}

mixin CLI!Config.main!((args) {
    import std.stdio : writeln;

    foreach (file; args.file)
    {
        foreach (entry; glob(file))
        {
            writeln(entry);
        }
    }
    return 0;
});
