import std.array, std.bitmanip, std.file, std.path, std.string;
import dcuserial;

struct FileDate
{
    mixin(bitfields!(uint, "second", 5, uint, "minute", 6, uint, "hour", 5,
            uint, "day", 5, uint, "month", 4, uint, "year", 7));

    string toString()
    {
        return format("%04d-%02d-%02d %02d:%02d:%02d", year + 1980, month, day,
                hour, minute, second * 2);
    }

    this(uint year, uint month, uint day, uint hour, uint minute, uint second)
    {
        this.year = year - 1980;
        this.month = month;
        this.day = day;
        this.hour = hour;
        this.minute = minute;
        this.second = second >> 1;
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
            w ~= format("// platform: $%02X\n", platform);
            w ~= format("// minor: $%02X\n", minor);
            w ~= format("// compiler: $%02X\n", compiler);
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
        ubyte finish = 0x61;

        void decompile(string filename)
        {
            auto content = std.file.read(filename);
            auto buffer = new Buffer(content);
            this = deserialize!(Dcu)(buffer);
            setFileName(filename);
            std.file.write(filename ~ ".pas", this.toString());
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