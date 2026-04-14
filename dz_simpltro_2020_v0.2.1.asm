/*-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
| Name: 	Empty Project
| Context: 	<Describe any context of the project here>
| Code: 	Agnostic
| Graphics: <Who did any graphics that was used?>
| Music: 	Unknown HVSC composer (thank you! awesome tune!)
| Sprites:	Ripped from the Butt Fat 256kb Sprite Font Compo (URL: https://csdb.dk/release/?id=180797)
| Font: 	7up.64c from Koefler.de
| Based on: 2020-09-27 KickAss Empty ASM Source Project
|
| Change log:
| 2020-09-27 : empty_project.asm
| 2020-11-29 : dz_simpltro_2020_v0.2.1.asm
| - using this as the release version even though it is not really ready.. haha.. 
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-*/

// C64 Memory Maps
//
// URL: https://www.pagetable.com/c64ref/c64mem/
// URL: http://unusedino.de/ec64/technical/project64/memory_maps.html (text only!)
// URL: https://www.atarimagazines.com/compute/issue29/394_1_COMMODORE_64_MEMORY_MAP.php 
//
// C64 Programmers Reference Manual
//
// URL: http://www.zimmers.net/cbmpics/cbm/c64/c64prg.txt

//  +------------------------------------------------------------------------------------------------------------------------------------------------------+
//  | Global constants etc.                                                                                                          Global constants etc. |
//  +------------------------------------------------------------------------------------------------------------------------------------------------------+
// top text scroller 
.const charpos_temp_lo = $20
.const charpos_temp_hi = $21

//  +------------------------------------------------------------------------------------------------------------------------------------------------------+
//  | Plugins                                                                                                                                      Plugins |
//  +------------------------------------------------------------------------------------------------------------------------------------------------------+
.plugin "se.triad.kickass.CruncherPlugins"

//  +------------------------------------------------------------------------------------------------------------------------------------------------------+
//  | Exomizer Cruncher Settings                                                                                                Exomizer Cruncher Settings |
//  +------------------------------------------------------------------------------------------------------------------------------------------------------+
.const EXO_LITERAL_SEQUENCES_USED = true
.const DISABLE_EXOMIZER_CACHE = true
.const EXO_ZP_BASE = $02
.const EXO_DECRUNCH_TABLE = $0200
#import "code/exomizer_decruncher.asm"




//  +------------------------------------------------------------------------------------------------------------------------------------------------------+
//  | IRQ Setup                                                                                                                                  IRQ Setup |
//  +------------------------------------------------------------------------------------------------------------------------------------------------------+
//  | Scan line setup: 0-50 is the border. Then there's 200 lines of screen and another 50 of border.                                                      | 
//  | Scanline | Screen line | Variable Name | Description                                                                                                 |
//  +----------+-------------+---------------+-------------------------------------------------------------------------------------------------------------+
//  |        0 |         N/A | scanline_0    | Play music, move scrollers etc.                                                                             |
//  |       16 |         N/A | scanline_1    | Set bitmap mode.                                                                                            |
//  |      N/A |           7 | scanline_2    | Switch to text mode. Need for top scroller.                                                                 |
//  |      N/A |          16 | scanline_3    | Switch to bitmap mode.                                                                                      |
//  |      N/A |         183 | scanline_4    | Switch to text mode. Need for bottom scroller.                                                              |
//  |      N/A |         194 | scanline_5    | Switch to bitmap mode.                                                                                      |
//  +------------------------------------------------------------------------------------------------------------------------------------------------------+

//  +------------------------------------------------------------------------------------------------------------------------------------------------------+
//  | IRQ Setup                                                                                                                                  IRQ Setup |
//  +------------------------------------------------------------------------------------------------------------------------------------------------------+
//  | Lets define the scanlines that require irq's to be defined                                                                                           |
//  +------------------------------------------------------------------------------------------------------------------------------------------------------+
.const scanline_0 = 1
.const scanline_1 = 35
.const scanline_2 = 50+7
.const scanline_3 = 50+16
.const scanline_4 = 50+183
.const scanline_5 = 50+194-2

.print "--------------------"
.print "IRQ scan line setup:"
.print "--------------------"
.print "scanline_0 :" + scanline_0
.print "scanline_1 :" + scanline_1
.print "scanline_2 :" + scanline_2
.print "scanline_3 :" + scanline_3
.print "scanline_4 :" + scanline_4
.print "scanline_5 :" + scanline_5

//  +------------------------------------------------------------------------------------------------------------------------------------------------------+
//  | Keyboard Scanning                                                                                                                  Keyboard Scanning |
//  +------------------------------------------------------------------------------------------------------------------------------------------------------+
//  | Used in the keyboard scanning routine to check for key presses and set up for response action.                                                       |
//  +------------------------------------------------------------------------------------------------------------------------------------------------------+
.const pra = $dc00 			// CIA#1 (Port Register A)			
.const prb = $dc01 			// CIA#1 (Port Register B)			
.const ddra = $dc02 		// CIA#1 (Data Direction Register A)
.const ddrb = $dc03 		// CIA#1 (Data Direction Register B)


//  +------------------------------------------------------------------------------------------------------------------------------------------------------+
//  | Binary Files Loading                                                                                                            Binary Files Loading |
//  +------------------------------------------------------------------------------------------------------------------------------------------------------+
//  | These statements load the raw data files. Used this originally, but switched to the C64 native Koala format below as can edit picture straigh in     | 
//  | Timanthes. Loading a native C64 Koala format picture that can be edited directly with Timanthes Koala picture format of DarkZone logo - native c64   |
//  | picture converted with > retropixels < from a hires png file                                                                                         |
//  +------------------------------------------------------------------------------------------------------------------------------------------------------+
//  | How to convert from png to Koala format that can be imported into the project:                                                                       |
//  |                                                                                                                                                      |
//  | Edit the graphics in multipaint on the Mac in C64 hires mode (320x200) and save the file as a png format file. We can then use the retropixels       |
//  | to convert the file from png to kla (Koala format), which we then can directly import with the statement below. I have only thus far tried this on   |
//  | C64Hires pictures and not any multicolor formats etc.                                                                                                |
//  |                                                                                                                                                      |
//  | [07:22:22] [jskogsta@enterprise ../bitmaps]$ retropixels -m c64HiresMono background_screen_vectro.png 2020-09-28_background_screen_vectro.kla        |
//  | Using graphicMode c64HiresMono                                                                                                                       |
//  | Written 2020-09-28_background_screen_vectro.kla                                                                                                      |
//  | [07:22:57] [jskogsta@enterprise ../bitmaps]$                                                                                                         |
//  |                                                                                                                                                      |
//  +------------------------------------------------------------------------------------------------------------------------------------------------------+
.var picture1 = LoadBinary("bitmaps/2020-09-29_background_screen_simpltro_V2.kla", BF_KOALA)
//.var music = LoadSid("resources/Active_Intro_14.sid")
.var music = LoadSid("resources/PSOMA2_v2.sid")

//  +------------------------------------------------------------------------------------------------------------------------------------------------------+-------+
//  | Bitmap: VIC Bank #2 Configuration                                                                                  Bitmap: VIC Bank #2 Configuration | START |
//  +------------------------------------------------------------------------------------------------------------------------------------------------------+-------+
//
//  VIC Bank Selection.
//  +------+-------+----------+-------------------------------------+
//  | BITS |  BANK | STARTING |  VIC-II CHIP RANGE                  |
//  |      |       | LOCATION |                                     |
//  +------+-------+----------+-------------------------------------+
//  |  00  |   3   |   49152  | ($C000-$FFFF)*                      |
//  |  01  |   2   |   32768  | ($8000-$BFFF)                       | <<<<< SETS THIS BANK
//  |  10  |   1   |   16384  | ($4000-$7FFF)*                      |
//  |  11  |   0   |       0  | ($0000-$3FFF) (DEFAULT VALUE)       |
//  +------+-------+----------+-------------------------------------+
//
//  The most significant nibble of $D018 selects where the screen is
//  located in the current VIC-II bank.
//  +------------+-------------------------------------------------+
//  |            |                     LOCATION*                   |
//  |    BITS    +---------+---------------------------------------+
//  |            | DECIMAL |                  HEX                  |
//  +------------+---------+---------------------------------------+
//  |  0000XXXX  |      0  |  $0000-$03FF, 0-1023.                 |
//  |  0001XXXX  |   1024  |  $0400-$07FF, 1024-2047.   (DEFAULT)  |
//  |  0010XXXX  |   2048  |  $0800-$0BFF, 2048-3071.              |
//  |  0011XXXX  |   3072  |  $0C00-$0FFF, 3072-4095.              | << video matrix (screen memory) > screen_memory_bitmap_buffer_offset = $0c00 
//  |  0100XXXX  |   4096  |  $1000-$13FF, 4096-5119.              |
//  |  0101XXXX  |   5120  |  $1400-$17FF, 5120-6143.              |
//  |  0110XXXX  |   6144  |  $1800-$1BFF, 6144-7167.              |
//  |  0111XXXX  |   7168  |  $1C00-$1FFF, 7168-8191.              |
//  |  1000XXXX  |   8192  |  $2000-$23FF, 8192-9215.              |
//  |  1001XXXX  |   9216  |  $2400-$27FF, 9216-10239.             |
//  |  1010XXXX  |  10240  |  $2800-$2BFF, 10240-11263.            |
//  |  1011XXXX  |  11264  |  $2C00-$2FFF, 11264-12287.            |
//  |  1100XXXX  |  12288  |  $3000-$33FF, 12288-13311.            |
//  |  1101XXXX  |  13312  |  $3400-$37FF, 13312-14335.            |
//  |  1110XXXX  |  14336  |  $3800-$3BFF, 14336-15359.            |
//  |  1111XXXX  |  15360  |  $3C00-$3FFF, 15360-16383.            |
//  +------------+---------+---------------------------------------+
//
// Set location of bitmap.
//
//  Args: address: Address relative to VIC-II bank address.
//        Valid values: $0000 (bitmap at $0000-$1FFF)
//        				$2000 (bitmap at $2000-$3FFF) <<<<<< SETS THIS BITMAP MEMORY
//  +------------+-------------------------------------------------+
//  |            |                     LOCATION*                   |
//  |    BITS    +---------+---------------------------------------+
//  |            | DECIMAL |                  HEX                  |
//  +------------+---------+---------------------------------------+
//  |  0000XXXX  |      0  |  $0000-$03FF, 0-1023.                 |
//  |  0001XXXX  |   1024  |  $0400-$07FF, 1024-2047.   (DEFAULT)  |
//  |  0010XXXX  |   2048  |  $0800-$0BFF, 2048-3071.              |
//  |  0011XXXX  |   3072  |  $0C00-$0FFF, 3072-4095.              |
//  |  0100XXXX  |   4096  |  $1000-$13FF, 4096-5119.              |
//  |  0101XXXX  |   5120  |  $1400-$17FF, 5120-6143.              |
//  |  0110XXXX  |   6144  |  $1800-$1BFF, 6144-7167.              |
//  |  0111XXXX  |   7168  |  $1C00-$1FFF, 7168-8191.              |
//  |  1000XXXX  |   8192  |  $2000-$23FF, 8192-9215.              | <<<<<< SETS THIS BIMAP MEMORY 
//  |  1001XXXX  |   9216  |  $2400-$27FF, 9216-10239.             |  <<
//  |  1010XXXX  |  10240  |  $2800-$2BFF, 10240-11263.            |  <<
//  |  1011XXXX  |  11264  |  $2C00-$2FFF, 11264-12287.            |  <<
//  |  1100XXXX  |  12288  |  $3000-$33FF, 12288-13311.            |  <<
//  |  1101XXXX  |  13312  |  $3400-$37FF, 13312-14335.            |  <<
//  |  1110XXXX  |  14336  |  $3800-$3BFF, 14336-15359.            |  <<
//  |  1111XXXX  |  15360  |  $3C00-$3FFF, 15360-16383.            |  <<
//  +------------+---------+---------------------------------------+
// 
// This following map is the reference to the bank setup that has been done
// Use this as a reference in later sections when configuring screen memory
//
//  +------+-------+----------+------------------------------------+
//  | BITS |  BANK | STARTING |  VIC-II CHIP RANGE                 |
//  |      |       | LOCATION |                                    |
//  +------+-------+----------+------------------------------------+
//  |  00  |   3   |   49152  | ($C000-$FFFF)*                     |
//  |  01  |   2   |   32768  | ($8000-$BFFF)                      | <<<<< SETS THIS BANK
//  |  10  |   1   |   16384  | ($4000-$7FFF)*                     |
//  |  11  |   0   |       0  | ($0000-$3FFF) (DEFAULT VALUE)      |
//  +------+-------+----------+------------------------------------+
//
//  +------------+-------------------------------------------------+
//  |            |                     LOCATION*                   |
//  |    BITS    +---------+---------------------------------------+
//  |            | DECIMAL |                  HEX                  |
//  +------------+---------+---------------------------------------+
//  |  0000XXXX  |      0  |  $0000-$03FF, 0-1023.                 |
//  |  0001XXXX  |   1024  |  $0400-$07FF, 1024-2047.   (DEFAULT)  | (((((( SPRITE MEMORY
//  |  0010XXXX  |   2048  |  $0800-$0BFF, 2048-3071.              |
//  |  0011XXXX  |   3072  |  $0C00-$0FFF, 3072-4095.              | << video matrix (screen memory) > screen_memory_bitmap_buffer_offset = $0c00 
//  |  0100XXXX  |   4096  |  $1000-$13FF, 4096-5119.              | ROM IMAGE in BANK 0 & 2 (default)
//  |  0101XXXX  |   5120  |  $1400-$17FF, 5120-6143.              |  <<
//  |  0110XXXX  |   6144  |  $1800-$1BFF, 6144-7167.              | ROM IMAGE in BANK 0 & 2 (default)
//  |  0111XXXX  |   7168  |  $1C00-$1FFF, 7168-8191.              |  <<
//  |  1000XXXX  |   8192  |  $2000-$23FF, 8192-9215.              | <<<<<< BIMAP MEMORY 
//  |  1001XXXX  |   9216  |  $2400-$27FF, 9216-10239.             |  <<
//  |  1010XXXX  |  10240  |  $2800-$2BFF, 10240-11263.            |  <<
//  |  1011XXXX  |  11264  |  $2C00-$2FFF, 11264-12287.            |  <<
//  |  1100XXXX  |  12288  |  $3000-$33FF, 12288-13311.            |  <<
//  |  1101XXXX  |  13312  |  $3400-$37FF, 13312-14335.            |  <<
//  |  1110XXXX  |  14336  |  $3800-$3BFF, 14336-15359.            |  <<
//  |  1111XXXX  |  15360  |  $3C00-$3FFF, 15360-16383.            |  <<
//  +------------+---------+---------------------------------------+
//
//  +---+-----+------+------+------+------+----------+----------+----------+--------+------------------------+
//  | # | Adr.| Bit7 | Bit6 | Bit5 | Bit4 |   Bit3   |   Bit2   |   Bit1   |  Bit0  | Function               |
//  +---+-----+------+------+------+------+----------+----------+----------+--------+------------------------+
//  |24 |$d018| VM13 | VM12 | VM11 | VM10 |   CB13   |   CB12   |   CB11   |    -   | Memory Pointers        |
//  +---+-----+------+------+------+------+----------+----------+----------+--------+------------------------+
//  |24 |$D018|  Screen Pointer(A13-A10)  | Bitmap/Charset Pointer(A13-A11)| unused |                        |
//  +---+-----+------+------+------+------+----------+----------+----------+--------+------------------------+
//  ^URL: http://www.oxyron.de/html/registers_vic2.html
//
.var vic_bank_bitmap = 2
.var screen_memory_bitmap_buffer_offset = $0c00 
.var bitmap_address_bitmap_buffer_offset = $2000
.var sprite_font_mem_bitmap_buffer_offset = $0400
.var vic_base_bitmap = $4000 * vic_bank_bitmap
.var screen_memory_bitmap = screen_memory_bitmap_buffer_offset + vic_base_bitmap
.var bitmap_address_bitmap = bitmap_address_bitmap_buffer_offset + vic_base_bitmap
.var sprite_font_bitmap = LoadBinary("sprite_font/sprte_font_V1_sprite_pad_format.raw")
.var sprite_font_mem_bitmap = sprite_font_mem_bitmap_buffer_offset + vic_base_bitmap
// Lets put in a virtual segment in Kick so we can get the screen buffer into the Kick Assembler's memory map view
* = vic_base_bitmap "Bitmap: VIC Bank #2 Configuration" virtual
.fill 8192, 0
//  +------------------------------------------------------------------------------------------------------------------------------------------------------+-------+
//  | Bitmap: VIC Bank #2 Configuration                                                                                  Bitmap: VIC Bank #2 Configuration | STOP  |
//  +------------------------------------------------------------------------------------------------------------------------------------------------------+-------+



//  +------------------------------------------------------------------------------------------------------------------------------------------------------+-------+
//  | Textmode: VIC Bank #3 Configuration                                                                              Textmode: VIC Bank #3 Configuration | START |
//  +------------------------------------------------------------------------------------------------------------------------------------------------------+-------+
//
//  +------+-------+----------+-------------------------------------+
//  | BITS |  BANK | STARTING |  VIC-II CHIP RANGE                  |
//  |      |       | LOCATION |                                     |
//  +------+-------+----------+-------------------------------------+
//  |  00  |   3   |   49152  | ($C000-$FFFF)*                      | <<<<< SETS THIS BANK
//  |  01  |   2   |   32768  | ($8000-$BFFF)                       |
//  |  10  |   1   |   16384  | ($4000-$7FFF)*                      |
//  |  11  |   0   |       0  | ($0000-$3FFF) (DEFAULT VALUE)       |
//  +------+-------+----------+-------------------------------------+
//
//  +--+-------+----+----+----+----+----+----+----+-----+-------------------------------+
//  | #| Adr.  |Bit7|Bit6|Bit5|Bit4|Bit3|Bit2|Bit1|Bit0 | Function                      |
//  +--+-------+----+----+----+----+----+----+----+-----+-------------------------------+
//  |24| $D011 |RST8|ECM |BMM |DEN |RSEL|   Y SCROLL    | Screen Control register 1     |
//  +--+-------+----+----+----+----+----+----+----+-----+-------------------------------+
//  |  3.7.3.1 Standard text mode (ECM/BMM/MCM=0/0/0)                                   |
//  |  3.7.3.2 Multicolor text mode (ECM/BMM/MCM=0/0/1)                                 |
//  |  Note: ONLY change the bits required set mode                                     |
//  +-----------------------------------------------------------------------------------+
//  |  Bit #0: Vertical raster scroll (Y SCROLL).                                       |
//  |  Bit #1: Vertical raster scroll (Y SCROLL).                                       |
//  |  Bit #2: Vertical raster scroll (Y SCROLL).                                       |
//  |  Bit #3: Screen height; 0 = 24 rows; 1 = 25 rows (RSEL).                          |
//  |  Bit #4: 0 = Screen off, complete screen is covered by border;                    |
//  |  Bit #4: 1 = Screen on, normal screen contents are visible.                       |
//  |  Bit #5: 0 = Text mode; 1 = Bitmap mode.                                          |
//  |  Bit #6: 1 = Extended background mode on.                                         |
//  |  Bit #7: Read: Current raster line (bit #8 - RST8).                               |
//  |          Write: Raster line to generate interrupt at (bit #8).                    |
//  +-----------------------------------------------------------------------------------+
//  ^URL: http://www.zimmers.net/cbmpics/cbm/c64/vic-ii.txt
//
//  +--+-------+----+----+----+----+----+----+----+----+-------------------------------+
//  | #| Adr.  |Bit7|Bit6|Bit5|Bit4|Bit3|Bit2|Bit1|Bit0| Function                      |
//  +--+-------+----+----+----+----+----+----+----+----+-------------------------------+
//  |22| $d016 |  - |  - | RES| MCM|CSEL|    XSCROLL   | Screen Control register 2     |
//  +--+-------+----+----+----+----+----+----+----+----+-------------------------------+
//  |  Bit #0: Horizontal raster scroll (X SCROLL).                                    |
//  |  Bit #1: Horizontal raster scroll (X SCROLL).                                    |
//  |  Bit #2: Horizontal raster scroll (X SCROLL).                                    |
//  |  Bit #3: Screen width; 0 = 38 columns; 1 = 40 columns.                           |
//  |  Bit #4: 1 = Multicolor mode on.                                                 |
//  +----------------------------------------------------------------------------------+
//  ^URL: http://www.zimmers.net/cbmpics/cbm/c64/vic-ii.txt
//
//  +---------------------------------------------------------------------------+
//  |                         TEXTMAP MODE                                      |
//  +------------+--------------------------------------------------------------+
//  |            |                     LOCATION*                                |
//  |    BITS    +---------+----------------------------------------------------+
//  |            | DECIMAL |                  HEX                               |
//  +------------+---------+----------------------------------------------------+
//  |  XXXX000X  |      0  |  $0000-$07FF, 0-2047.                              | << video matrix (screen memory) > screen_memory_textmode_buffer_offset = $0000 
//  |  XXXX001X  |   2048  |  $0800-$0FFF, 2048-4095.                           | << character generator (character set) > custom_font_mem_textmode_buffer_offset = $0800
//  |  XXXX010X  |   4096  |  $1000-$17FF, 4096-6143.                           |
//  |  XXXX011X  |   6144  |  $1800-$1FFF, 6144-8191.                           |
//  |  XXXX100X  |   8192  |  $2000-$27FF, 8192-10239.                          |
//  |  XXXX101X  |  10240  |  $2800-$2FFF, 10240-12287.                         |
//  |  XXXX110X  |  12288  |  $3000-$37FF, 12288-14335.                         |
//  |  XXXX111X  |  14336  |  $3800-$3FFF, 14336-16383.                         |
//  +------------+---------+----------------------------------------------------+
//  |  The video matrix; an area of 1000 video addresses (40×25, 12 bits each)  |
//  |  that can be moved in 1KB steps within the 16KB address space of the VIC  |
//  |  with the bits VM10-VM13 of register $d018. It stores the character codes |
//  |  and their color for the text modes and some of the color information of  |
//  |  8×8 pixel blocks for the bitmap modes. The Color RAM is part of the      |
//  |  video matrix, it delivers the upper 4 bits of the 12 bit matrix. The     |
//  |  data read from the video matrix is stored in an internal buffer in the   |
//  |  VIC, the 40×12 bit video matrix/color line.                              |
//  +---------------------------------------------------------------------------+
//  |  The character generator resp. the bitmap; an area of 2048 bytes (bitmap: |
//  |  8192 bytes) that can be moved in 2KB steps (bitmap: 8KB steps) within    |
//  |  the VIC address space with the bits CB11-CB13 (bitmap: only CB13) of     |
//  |  register $d018. It stores the pixel data of the characters for the text  |
//  |  modes and the bitmap for the bitmap modes. The character generator has   |
//  |  basically nothing to do with the Char ROM. The Char ROM only contains    |
//  |  prepared bit patterns that can be used as character generator, but you   |
//  |  can also store the character generator in normal RAM to define your own  |
//  |  character images.                                                        |
//  +---------------------------------------------------------------------------+
//
//  +---+-----+------+------+------+------+----------+----------+----------+--------+------------------------+
//  | # | Adr.| Bit7 | Bit6 | Bit5 | Bit4 |   Bit3   |   Bit2   |   Bit1   |  Bit0  | Function               |
//  +---+-----+------+------+------+------+----------+----------+----------+--------+------------------------+
//  |24 |$d018| VM13 | VM12 | VM11 | VM10 |   CB13   |   CB12   |   CB11   |    -   | Memory Pointers        |
//  +---+-----+------+------+------+------+----------+----------+----------+--------+------------------------+
//  |24 |$D018|  Screen Pointer(A13-A10)  | Bitmap/Charset Pointer(A13-A11)| unused |                        |
//  +---+-----+------+------+------+------+----------+----------+----------+--------+------------------------+
//  ^URL: http://www.zimmers.net/cbmpics/cbm/c64/vic-ii.txt
//  ^URL: http://www.oxyron.de/html/registers_vic2.html
//
.var vic_bank_textmode = 3
.var screen_memory_textmode_buffer_offset = $0000 
.var custom_font_mem_textmode_buffer_offset = $0800
.var vic_base_textmode = $4000 * vic_bank_textmode
.var screen_memory_textmode = screen_memory_textmode_buffer_offset + vic_base_textmode
.var custom_font_mem_textmode = custom_font_mem_textmode_buffer_offset + vic_base_textmode
.var text_mode_screen_memory = vic_base_textmode    // text memory = $8000. Charset in $1000 which is in bank 2 mapped to character rom
// Lets put in a virtual segment in Kick so we can get the screen buffer into the Kick Assembler's memory map view
* = vic_base_textmode "Textmode: VIC Bank #3 Configuration" virtual
.fill 8192, 0
//  +------------------------------------------------------------------------------------------------------------------------------------------------------+
//  | Custom Textmode Font                                                                                                            Custom Textmode Font |
//  +------------------------------------------------------------------------------------------------------------------------------------------------------+
//  | Lets load a new font from kofler.dot.at/c64/font_01.html . This will be loaded at font_mem above. URL is: http://kofler.dot.at/c64/download/7up.zip  |
//  +------------------------------------------------------------------------------------------------------------------------------------------------------+
.var font = LoadBinary("font/7up.64c", BF_C64FILE)
//  +------------------------------------------------------------------------------------------------------------------------------------------------------+-------+
//  | Textmode: VIC Bank #3 Configuration                                                                              Textmode: VIC Bank #3 Configuration | STOP  |
//  +------------------------------------------------------------------------------------------------------------------------------------------------------+-------+



// //  +------------------------------------------------------------------------------------------------------------------------------------------------------+
// //  | IRQ Setup                                                                                                                                  IRQ Setup |
// //  +------------------------------------------------------------------------------------------------------------------------------------------------------+
// //  | Lets define the scanlines that require irq's to be defined                                                                                           |
// //  +------------------------------------------------------------------------------------------------------------------------------------------------------+
// .const scanline_1 = 0 				// lets set the hires graphics mode & move the text scroller
// .const scanline_2 = 190
// .const scanline_3 = 202
// .const scanline_4 = 50+(20*8)
// .const scanline_5 = 50+(21*8)


//  +======================================================================================================================================================+
//  | MAIN START                                                                                                                                MAIN START |
//  +======================================================================================================================================================+
BasicUpstart2(start)

* = $2110 "Main ASM program start"


start:    
	// bits 0-2 > %x10: RAM visible at $A000-$BFFF; KERNAL ROM visible at $E000-$FFFF.
	// http://www.awsm.de/mem64/?fbclid=IwAR1NmZ-i-bOoJlYiyXTxPtGVpGYF_eAXo8Ksr7xVamqgvSNsE1xtNyeskr8
	lda #%00110110
	sta $01

	// prepare for the scrollers
	lda #0
	sta charpos
	sta charpos+1
	sta framecount

	// fill text mode screen with space (' ') characters
	FillScreenMemory(text_mode_screen_memory, 32)   // fill text screen with blank character. See https://www.c64-wiki.com/wiki/File:Zeichensatz-c64-poke1.jpg

	lda #BLACK
	sta $d020
	sta $d021

	// Lets decrunch stuff
	:EXO_DECRUNCH(crunchedBitmapAndScreen)

	// init music
	lda #music.startSong-1
	jsr music.init

	FillScreenMemory(screen_memory_textmode, $00)
	
// Commented out: Requires plan to set up IRQ's correctly. Will leave that to be defined with a new project. No set way of doing this pre configured
//
	//  +------------------------------------------------------------------------------------------------------------------------------------------------+
	//  | IRQ Setup                                                                                                                            IRQ Setup |
	//  +------------------------------------------------------------------------------------------------------------------------------------------------+
	sei
	lda #$35        // Bank out kernel and basic
	sta $01
	SetupIRQ(irq0, scanline_0, false)
	lda #0
	sta framecount
	cli


loop:

	:pause #255
	:pause #255
	:pause #255
	:pause #255
	:pause #255
	:pause #255
	:pause #255
	:pause #255
	:pause #255
	:pause #255
	:pause #255
	:pause #255
	:pause #255
	:pause #255
	:pause #255
	:pause #255
	:pause #255
	:pause #255
	:pause #255
	:pause #255
	:pause #255
	:pause #255
	:pause #255
	:pause #255
	:pause #255
	:pause #255
	:pause #255
	:pause #255
	:pause #255
	:pause #255
	jsr colwash
	jsr reverse_colwash



	jmp loop

//  +======================================================================================================================================================+
//  | SUBROUTINES                                                                                                                              SUBROUTINES |
//  +======================================================================================================================================================+


//  +-[Subroutine:]-----------------------------------------------------------------------------------------+
//  |   																									|
//  | <Name of sub routine>                                                                                 |
//  |   																									|
//  +-[Description:]----------------------------------------------------------------------------------------+
//  |   																									|
//  | <Description of subroutine>                                                                           |
//  |   																									|
//  +-[Context & Setup Information]-------------------------------------------------------------------------+
//  |   																									|
//  | <Context for the sub routine>                                                                         |
//  |   																									|
//  +-------------------------------------------------------------------------------------------------------+


//  +-[Subroutine:]-----------------------------------------------------------------------------------------+
//  |   																									|
//  | Exit back to basic                                                                                    |
//  |   																									|
//  +-[Description:]----------------------------------------------------------------------------------------+
//  |   																									|
//  | This routine exits back to basic when invoked. Need to check what is required with irq setups etc.    |
//  |   																									|
//  +-------------------------------------------------------------------------------------------------------+
exit_back_to_basic: {

   	sei
	lda #$37
	sta $01
	cli

	// clear out the sid for when the volume is turned back on.
	lda #$00
	tax
a: 
	sta $d400,x
	inx
	cpx #$14
	bne a 

	rts
}

scroller_update: {
	lda framecount
	and #7
	bne noscroll

	ldx #$00
moveline:
	// lets load the character from the non visible line 
	lda (text_mode_screen_memory)+10*40+1, x

	sta (text_mode_screen_memory)+1*40, x
	sta (text_mode_screen_memory)+10*40, x
	sta (text_mode_screen_memory)+23*40, x

	inx
	cpx #39
	bne moveline

	clc
	lda charpos
	adc #<scrolltext
	//sta $20
	sta charpos_temp_lo
	lda charpos+1
	adc #>scrolltext
	//sta $21
	sta charpos_temp_hi

	ldy #0
	//lda ($20),y
	lda (charpos_temp_lo),y
	// lets pull the next character into the visible & non-visible buffers
	sta (text_mode_screen_memory)+1*40+39
	sta (text_mode_screen_memory)+10*40+39
	sta (text_mode_screen_memory)+23*40+39

	add16_imm8(charpos, 1)

	// wrap around for scroll char pos
	lda charpos+0
	cmp #<(scrolltextend-scrolltext)
	bne noscroll
	lda charpos+1
	cmp #>(scrolltextend-scrolltext)
	bne noscroll
	lda #0
	sta charpos
	sta charpos+1
noscroll:
	rts
}


//============================ 
// Color wash for the scroller
// 
// Color memory can NOT move. It is always located at locations 55296
// ($D800) through 56295 ($DBE7). E.g. we can move the screen memory through switching
// banks and what not, but the color memory does not. See links for further details. 
// URL: http://www.zimmers.net/cbmpics/cbm/c64/c64prg.txt
// URL: http://tnd64.unikat.sk (The Colour Washing routine)
//========================== 
colwash: {            
	lda colour+$00 
	sta colour+$28 
	ldx #$00 
cycle:                
	lda colour+$01,x 
	sta colour+$00,x 
	lda colour,x 
	sta $d800+1*40,x 
	inx 
	cpx #$28 
	bne cycle 
	rts
}

reverse_colwash: {
	lda colour_2+$28
	sta colour_2+$00
	ldx #$28
cycle:
	lda colour_2-$01,x
	sta colour_2+$00,x
	lda colour_2,x
	sta $d800+23*40,x 
	dex
	bne cycle
	rts
}



//  +======================================================================================================================================================+
//  | DATA                                                                                                                                            DATA |
//  +======================================================================================================================================================+
framecount: 	.byte 0

* = custom_font_mem_textmode "Text Mode Character Font"
.fill font.getSize(), font.get(i)

* = music.location "SID Music"
.fill music.size, music.getData(i)

.modify MemExomizer(false,true) {
    .pc = bitmap_address_bitmap "Bitmap"
    .fill picture1.getBitmapSize(), picture1.getBitmap(i)
    .pc = screen_memory_bitmap "Screendata"
    .fill picture1.getScreenRamSize(), picture1.getScreenRam(i)
}
.label crunchedBitmapAndScreen = *


// Scroll text 1: This is the slow one.. 
charpos:    		.byte 0, 0
scrolltext: // special characters that is supported in the character set: 	! # $ % & * ( ) + = - ; : ''
	.text "-+- darkzone -+- is back with -+- simpltro -+- which really was a test for another project... but we decided that "
	.text "we release it at "
	.text "-+- syntax party 2020 -+- even for what it is and with a little feature up there on the right hand top side! "
	.text "shoutouts to the syntax crew that went online.. kudos and respect! "
	.text "good effort flying the melbourne/australia vibe for sure! vive la aussie! (og litt heia norge! og!)... " 
    .text "some quick credits.. code: agnostic... logo: kingpin/failure... tune: ps0ma (ring of ages forever!)... "
    .text "font: 7up.64c from koefler.de. credits go where credits are due... "
    .text "                                                          "
scrolltextend:
x_scroll_value: 	.byte 0

//.align 64
//colors1:
//                .text "cmagcmag"
//colorend:

colour:      
  .byte $09,$09,$02,$02,$08 
  .byte $08,$0a,$0a,$0f,$0f 
  .byte $07,$07,$01,$01,$01 
  .byte $01,$01,$01,$01,$01 
  .byte $01,$01,$01,$01,$01 
  .byte $01,$01,$01,$07,$07 
  .byte $0f,$0f,$0a,$0a,$08 
  .byte $08,$02,$02,$09,$09 
  .byte $00,$00,$00,$00,$00

colour_2:      
  .byte $09,$09,$02,$02,$08 
  .byte $08,$0a,$0a,$0f,$0f 
  .byte $07,$07,$01,$01,$01 
  .byte $01,$01,$01,$01,$01 
  .byte $01,$01,$01,$01,$01 
  .byte $01,$01,$01,$07,$07 
  .byte $0f,$0f,$0a,$0a,$08 
  .byte $08,$02,$02,$09,$09 
  .byte $00,$00,$00,$00,$00



//  +------------------------------------------------------------------------------------------------------------------------------------------------------+
//  | Code imports - End of file                                                                                                Code imports - End of file |
//  +------------------------------------------------------------------------------------------------------------------------------------------------------+
#import "code/irq_main_part_v2.asm" 		// main part irq settings
#import "macros/macros.asm"
#import "code/keyboard_scanner.asm"



//  +------------------------------------------------------------------------------------------------------------------------------------------------------+
//  | Kick Assembler Console Outputs                                                                                        Kick Assembler Console Outputs |
//  +------------------------------------------------------------------------------------------------------------------------------------------------------+
.print ""
.print "--------------------"
.print "SID Data"
.print "--------------------"
.print "location=$"+toHexString(music.location)
.print "init=$"+toHexString(music.init)
.print "play=$"+toHexString(music.play)
.print "songs="+music.songs
.print "startSong="+music.startSong
.print "size=$"+toHexString(music.size)
.print "name="+music.name
.print "author="+music.author
.print "copyright="+music.copyright
.print ""
.print "--------------------"
.print "Additional tech data"
.print "--------------------"
.print "header="+music.header
.print "header version="+music.version
.print "flags="+toBinaryString(music.flags)
.print "speed="+toBinaryString(music.speed)
.print "startpage="+music.startpage
.print "pagelength="+music.pagelength
.print ""
.print "--------------------"
.print "Hires Bitmap Buffer:"
.print "--------------------"
.print "Hires vic_bank: $" + toHexString(vic_bank_bitmap)
.print "Hires vic_base: $" + toHexString(vic_base_bitmap)
.print "Hires screen_memory: $" + toHexString(screen_memory_bitmap) + " ($" + toHexString(screen_memory_bitmap_buffer_offset) + ")"
.print "Hires bitmap_address: $" + toHexString(bitmap_address_bitmap) + " ($" + toHexString(bitmap_address_bitmap_buffer_offset) + ")"
.print "Sprite font address: $" + toHexString(sprite_font_mem_bitmap) + " ($" + toHexString(sprite_font_mem_bitmap_buffer_offset) + ")"
.print ""
.print "--------------------"
.print "Textmode Buffer:"
.print "--------------------"
.print "Textmode vic_bank: $" + toHexString(vic_bank_textmode)
.print "Textmode vic_base: $" + toHexString(vic_base_textmode)
.print "Textmost screen_memory: $" + toHexString(screen_memory_textmode) + " ($" + toHexString(screen_memory_textmode_buffer_offset) + ")"
.print "Textmode custom font address: $" + toHexString(custom_font_mem_textmode) + " ($" + toHexString(custom_font_mem_textmode_buffer_offset) + ")"
.print ""
.print "----------------------------------"
.print "Bitmap file import - Darkzone logo"
.print "----------------------------------"
.print "Koala format="+BF_KOALA
.print ""


