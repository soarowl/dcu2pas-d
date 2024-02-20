import std.array, std.bitmanip, std.datetime, std.file, std.path, std.stdio, std.string;
import dcuserial;

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

align(1)
{
    struct DcuHeader
    {
        ubyte majar;
        ubyte platform;
        ubyte minor;
        ubyte compiler;
        uint size;
        DosFileTime compiledAt;
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
            w ~= format("// compiled: %s\n", DosFileTimeToSysTime(compiledAt).toISOExtString());
            w ~= format("// crc: $%08X\n", crc);
            return w[];
        }
    }

    struct DcuAddtional
    {
        @Condition("__buffer.compiler >= Compiler.Delphi7")
        ubyte tag = 2;
        @Condition("__buffer.compiler >= Compiler.Delphi2006")
        @Length!ubyte string name;
        @Condition("__buffer.compiler >= Compiler.Delphi2009")
        {
            @Var int unknown1;
            @Var uint unknown2;
        }

        string toString()
        {
            return format("$%02X %s %d %d", tag, name, unknown1, unknown2);
        }
    }
}

class Dcu
{
    string filename;
    string unitname;

    Buffer encodeBuffer;
    Buffer decodeBuffer;
    DcuHeader header;
    ubyte unknown1;
    DcuAddtional addtional;
    // ubyte finish = 0x61;

    void encode()
    {
        encodeBuffer = new Buffer(decodeBuffer.capacity);
        header.updateBufferProperties(encodeBuffer);
        auto contentBuffer = new Buffer(decodeBuffer.capacity);
        header.updateBufferProperties(contentBuffer);

        contentBuffer.write(unknown1);
        // contentBuffer.write!DcuAddtional(addtional);
        addtional.serialize(contentBuffer);
        // contentBuffer.write(finish);

        auto encodeHeader = header;
        auto encoded = contentBuffer.data!ubyte();
        encodeHeader.size = cast(uint) encoded.length;
        encodeHeader.compiledAt = SysTimeToDosFileTime(Clock.currTime());
        encodeBuffer.write!DcuHeader(encodeHeader);
        encodeBuffer.write(encoded);
    }

    void decode()
    {
        header = decodeBuffer.read!DcuHeader();
        unknown1 = decodeBuffer.read!ubyte();
        // addtional = decodeBuffer.read!DcuAddtional();
        addtional = deserialize!DcuAddtional(decodeBuffer);
        // finish = decodeBuffer.read!ubyte();
    }

    void decompile(string filename)
    {
        auto content = std.file.read(filename);
        decodeBuffer = new Buffer(content);
        setFileName(filename);
        decode();
        std.file.write(filename ~ ".pas", this.toString());
        if (decodeBuffer.rindex < decodeBuffer.windex)
        {
            writefln("  End at: $%X with: $%X", decodeBuffer.rindex, decodeBuffer.peek!ubyte());
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

    override string toString()
    {
        auto w = appender!string;
        w ~= header.toString();
        w ~= format("// Additional: %s\n", addtional);
        w ~= format("\nunit %s;\n\ninterface\n\n", unitname);
        w ~= "";
        w ~= "implematation\n\n";
        w ~= "end.\n";
        return w[];
    }
}
