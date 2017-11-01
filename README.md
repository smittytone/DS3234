# DS3234

Hardware driver for the [Maxim DS3234 real time clock](Dallas/Maxim DS3234 real time clock) as used in the [SparkFun DeadOn breakout board](https://www.sparkfun.com/products/10160). It connects to the imp via SPI.

## Release Notes

- 1.1.0
    - Add *setCurrentDateAndTime()* method (uses the imp’s own RTC as a source)
    - All *getDateAndTime()* to return date in Squirrel *date()* format
- 1.0.4
    - Minor code change: rename constants to be class-specific
- 1.0.3
    - Initial release

## Class Usage

### Constructor: HT16K33Matrix(*spiBus, csPin[, debug]*)

To instantiate a DS3234 object pass the SPI bus to which the display is connected and a chip-select pin. This class is currently intended for the imp001 and imp002 &mdash; imps with an nSS pin in their SPI buses will be supported shortly. The SPI bus should not be configured &mdash; that is handled by the *init()* method.

Optionally, you can pass `true` into the *debug* parameter. This will cause debugging information to be posted to the device log. This is disabled by default.

## Class Usage

### init()

This method sets up the imp SPI bus and initialises the DS3234. It should always be called after instantiation and before the instance is used.

### setDateAndTime(*date, month, year, wday, hour, min, sec*)

This method takes imp-standard date and time values (as per the Squirrel *date()* function) and writes them to the DS3234.

### setCurrentDateAndTime()

This method writes the current date and time, as taken from the imp’s own battery-less RTC, to the DS3234.

### getDateAndTime(*dateFormat*)

This method reads back the current date and time from the DS3234 and returns them. If the value passed into *dateFormat* is `true`, the date and time are returned as a table that matches the one returned by Squirrel’s *date()* function, otherwise the method returns an array of values in the following order: seconds, minutes, hour, day of the week, day, month, year. *dateFormat* defaults to `false` for backwards compatibility.

## License

The DS3234 library is licensed under the [MIT License](./LICENSE).
