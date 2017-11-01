// Class-specific constants
const DS3234_CLASS_LOW            = 0;
const DS3234_CLASS_HIGH           = 1;
const DS3234_CLASS_CTRL_REG_WRITE  = "\x8E";
const DS3234_CLASS_RAM_START_READ  = "\x00";
const DS3234_CLASS_RAM_START_WRITE = "\x80";

class DS3234RTC {

    // Squirrel class for the Dallas/Maxim DS3234 real time clock used on the
    // SparkFun DeadOn breakout board https://www.sparkfun.com/products/10160
    // Bus: SPI
    // Written by Tony Smith, copyright 2014-17

    static VERSION = "1.1.0";

    _spi = null;
    _cs = null;
    _debug = false;

    constructor(spiBus = null, csPin = null, debug = false) {
        if (spiBus == null) {
            throw "The DS3234RTC class requires a non-null imp SPI bus";
        } else {
            _spi = spiBus;
        }

        if (csPin == null) {
            throw "The DS3234RTC class requires a non-null imp GPIO pin for CS";
        } else {
            _cs = csPin;
        }

        _debug = debug;
    }

    function init() {
        // Configure the SPI bus for SPI Mode 3
        _spi.configure((CLOCK_IDLE_LOW | CLOCK_2ND_EDGE), 3000);

        // Set the Chip Select pin DS3234_CLASS_HIGH
        _cs.configure(DIGITAL_OUT);
        _cs.write(DS3234_CLASS_HIGH);

        // Pause 20ms
        imp.sleep(0.02);

        // Initialise the DS3234 with basic settings, ie. zero Control Register
        _cs.write(DS3234_CLASS_LOW);
        _spi.write(DS3234_CLASS_CTRL_REG_WRITE);
        _spi.write("\x00");
        _cs.write(DS3234_CLASS_HIGH);
    }

    function setDateAndTime(date, month, year, wday, hour, min, sec) {
        // Sets the RTC's initial values - all parameters are integers
        // Re-arrange the input data into the order expected by the RTC
        local dateData = [sec, min, hour, wday, date, month, (year - 2000)];

        for (local i = 0 ; i < 7 ; ++i) {
            // Write the data
            dateData[i] = _integerToBCD(dateData[i]);
            if (i == 2) dateData[i] = dateData[i] & 0x3F;

            // DS3234 memory is written at 0x80 and up
            // 0x80 = seconds (0-59)
            // 0x81 = minutes (0-59)
            // 0x82 = hour (0-23)
            // 0x83 = day of week (1-7)
            // 0x84 = day of month (1-31)
            // 0x85 = month (1-12)
            // 0x86 = year (00-99)

            _cs.write(DS3234_CLASS_LOW);
            local r = blob(1);
            r.writen((i + 0x80), 'b');
            _spi.write(r);
            r = blob(1);
            r.writen(dateData[i], 'b');
            _spi.write(r);
            _cs.write(DS3234_CLASS_HIGH);
        }

        if (_debug) server.log("RTC set");
    }

    function setCurrentDateAndTime() {
        // Sets the RTC's initial values to the current setting from the imp's RTC
        local now = date();
        setDateAndTime(now.day, now.month, now.year, now.wday, now.hour, now.min, now.sec);
    }

    function getDateAndTime(dateFormat = false) {
        local b = null;
        local dateData = [0, 0, 0, 0, 0, 0, 0];

        for (local i = 0 ; i < 7 ; ++i) {
            // DS3234 memory is read at 0x00 and up
            // 0x00 = seconds (0-59)
            // 0x01 = minutes (0-59)
            // 0x02 = hour (0-23)
            // 0x03 = day of week (1-7)
            // 0x04 = day of month (1-31)
            // 0x05 = month (1-12)
            // 0x06 = year (00-99)

            _cs.write(DS3234_CLASS_LOW);
            local r = blob(1);
            r.writen(i, 'b');
            _spi.write(r);
            b = _spi.readblob(1);
            dateData[i] = _BCDtoInteger(b[0]);
            _cs.write(DS3234_CLASS_HIGH);
        }

        if (_debug) {
            local s = ""
            foreach (item in dateData) {
                s = s + item.tostring() + ":";
            }

            s = s.slice(0, s.len() - 1);
            server.log("RTC read: " + s);
        }

        if (dateFormat) {
            // Convert into a table that matches Squirrel's 'date()'
            local now = {};
            now.sec <- dateData[0];
            now.min <- dateData[1];
            now.hour <- dateData[2];
            now.wday <- dateData[3];
            now.day <- dateData[4];
            now.month <- dateData[5];
            now.year <- (2000 + dateData[6]);
            return now;
        }

        // Return as an array
        return dateData;
    }

    // ********** PRIVATE FUNCTIONS - DO NOT CALL **********

    function _integerToBCD(value) {
        // DS3234 stores data in Binary Coded Decimal (BCD)
        // Writes must be converted from integer to BCD
        local a = value / 10;
        local b = value - (a * 10);
        return (a << 4) + b;
    }

    function _BCDtoInteger(value) {
        // DS3234 stores data in Binary Coded Decimal (BCD)
        // Reads must be converted to integer from BCD
        local a = (value & 0xF0) >> 4;
        local b = value & 0x0F;
        return (a * 10) + b;
    }
}
