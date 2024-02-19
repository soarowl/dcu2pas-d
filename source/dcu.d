import std.array, std.bitmanip, std.file, std.path, std.stdio, std.string;
import dcuserial;

enum Compiler : ubyte
{
    Delphi6 = 14,
    Delphi7 = 15,
    Delphi8 = 16,
    Delphi2005 = 17,
    Delphi2006 = 18,
    Delphi2007 = 19,
    Delphi2009 = 20,
    Delphi2010 = 21,
    DelphiXE = 22,
    DelphiXE2 = 23,
    DelphiXE3 = 24,
    DelphiXE4 = 25,
    DelphiXE5 = 26,
    DelphiXE6 = 27,
    DelphiXE7 = 28,
    DelphiXE8 = 29,
    Delphi10 = 30,
    Delphi10Berlin = 31,
    Delphi10Tokyo = 32,
    Delphi10Rio = 33,
    Delphi10Sydney = 34,
    Delphi11 = 35,
    Delphi12 = 36
}

enum string[ubyte] Compilers = [
    Compiler.Delphi6: "Borland Delphi 6", Compiler.Delphi7: "Borland Delphi 7",
    Compiler.Delphi8: "Borland Delphi 8 for .NET",
    Compiler.Delphi2005: "Borland Delphi 200",
    Compiler.Delphi2006: "Borland Developer Studio 2006",
    Compiler.Delphi2007: "CodeGear Delphi 2007 for .NET",
    Compiler.Delphi2009: "CodeGear C++ Builder 2009",
    Compiler.Delphi2010: "Embarcadero RAD Studio 2010",
    Compiler.DelphiXE: "Embarcadero RAD Studio XE",
    Compiler.DelphiXE2: "Embarcadero RAD Studio XE2",
    Compiler.DelphiXE3: "Embarcadero RAD Studio XE3",
    Compiler.DelphiXE4: "DEmbarcadero RAD Studio XE4",
    Compiler.DelphiXE5: "Embarcadero RAD Studio XE5",
    Compiler.DelphiXE6: "Embarcadero RAD Studio XE6",
    Compiler.DelphiXE7: "Embarcadero RAD Studio XE7",
    Compiler.DelphiXE8: "Embarcadero RAD Studio XE8",
    Compiler.Delphi10: "Embarcadero RAD Studio 10 Seattle",
    Compiler.Delphi10Berlin: "Embarcadero RAD Studio 10.1 Berlin",
    Compiler.Delphi10Tokyo: "Embarcadero RAD Studio 10.2 Tokyo",
    Compiler.Delphi10Rio: "Embarcadero RAD Studio 10.3 Rio",
    Compiler.Delphi10Sydney: "Embarcadero RAD Studio 10.4 Sydney",
    Compiler.Delphi11: "Embarcadero RAD Studio 11.0 Alexandria",
    Compiler.Delphi12: "Embarcadero RAD Studio 12.0 Athens"
];

string getCompilerString(ubyte compiler)
{
    if (compiler in Compilers)
    {
        return Compilers[compiler];
    }
    else
    {
        return "Unknown compiler";
    }
}

enum Platform : ubyte
{
    Win32_00 = 0,
    Win32_03 = 3,
    OSX32_04 = 4,
    iOSSimulator32_14 = 0x14,
    Win64_23 = 0x23,
    Android32_67 = 0x67,
    iOSDevice32_76 = 0x76,
    Android32_77 = 0x77,
    Android64_87 = 0x87,
    iOSDevice64_94 = 0x94
}

enum string[ubyte] Platforms = [
    Platform.Win32_00: "Win32", Platform.Win32_03: "Win32",
    Platform.OSX32_04: "OSX32", Platform.iOSSimulator32_14: "iOS Simulator32",
    Platform.Win64_23: "Win64", Platform.Android32_67: "Android32",
    Platform.iOSDevice32_76: "iOS Device32", Platform.Android32_77: "Android32",
    Platform.Android64_87: "Android64", Platform.iOSDevice64_94: "iOS Device64"
];

string getPlatformString(ubyte platform)
{
    if (platform in Platforms)
    {
        return Platforms[platform];
    }
    else
    {
        return "Unknown platform";
    }
}

// At present serail/deserial dont work.
struct FileDate_internal
{
    mixin(bitfields!(uint, "second", 5, uint, "minute", 6, uint, "hour", 5,
            uint, "day", 5, uint, "month", 4, uint, "year", 7));
}

struct FileDate
{
    ushort time;
    ushort date;

    string toString()
    {
        auto pfd = cast(FileDate_internal*)&this;
        return format("%04d-%02d-%02d %02d:%02d:%02d", pfd.year + 1980,
                pfd.month, pfd.day, pfd.hour, pfd.minute, pfd.second << 2);
    }

    this(uint year, uint month, uint day, uint hour, uint minute, uint second)
    {
        auto pfd = cast(FileDate_internal*)&this;
        pfd.year = year - 1980;
        pfd.month = month;
        pfd.day = day;
        pfd.hour = hour;
        pfd.minute = minute;
        pfd.second = second >> 1;
    }
}

unittest
{
    FileDate fd = FileDate(2024, 2, 19, 11, 44, 0);
    assert(fd.toString() == "2024-02-19 11:44:00");
}

align(1)
{
    struct DcuHeader
    {
        ubyte majar;
        ubyte platform;
        ubyte minor;
        ubyte compiler;
        uint size;
        FileDate compiledAt;
        uint crc;

        void updateBufferProperties(Buffer buffer)
        {
            buffer.platform = this.platform;
            buffer.compiler = this.compiler;
        }

        string toString()
        {
            auto w = appender!string;
            w ~= format("// majar: $%02X\n", majar);
            w ~= format("// platform: %s\n", getPlatformString(platform));
            w ~= format("// minor: $%02X\n", minor);
            w ~= format("// compiler: %s\n", getCompilerString(compiler));
            w ~= format("// size: %d\n", size);
            w ~= format("// compiled: %s\n", compiledAt.toString());
            w ~= format("// crc: $%08X\n\n", crc);
            return w[];
        }
    }

    struct Dcu
    {
        @Exclude string filename;
        @Exclude string unitname;

        DcuHeader header;
        ubyte unknown1;
        // ubyte finish = 0x61;

        void decompile(string filename)
        {
            auto content = std.file.read(filename);
            auto buffer = new Buffer(content);
            this = deserialize!(Dcu)(buffer);
            setFileName(filename);
            std.file.write(filename ~ ".pas", this.toString());
            if (buffer.rindex < buffer.windex)
            {
                writefln("  End at: $%X with: $%X", buffer.rindex, buffer.peek!ubyte());
            }
        }

        void setFileName(string filename)
        {
            if (this.filename.length == 0)
            {
                this.filename = filename;
            }
            if (this.unitname.length == 0)
            {
                auto ext = extension(filename);
                auto name = baseName(filename, ext);
                this.unitname = name;
            }
        }

        string toString()
        {
            auto w = appender!string;
            w ~= header.toString();
            w ~= format("unit %s;\n\ninterface\n\n", unitname);
            w ~= "";
            w ~= "implematation\n\n";
            w ~= "end.\n";
            return w[];
        }
    }
}
