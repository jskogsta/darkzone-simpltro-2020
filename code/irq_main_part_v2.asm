

//  +------------------------------------------------------------------------------------------------------------------------------+
//  | Play music and move scrollers etc.                                                                                           |
//  +------------------------------------------------------------------------------------------------------------------------------+
irq0: {
	irq_start(end)

	inc framecount

	// iterate through the play routine
	jsr music.play 


	irq_end(irq1, scanline_1)
end:
	rti
}

//  +------------------------------------------------------------------------------------------------------------------------------+
//  | Bitmap mode                                                                                                                  |
//  +------------------------------------------------------------------------------------------------------------------------------+
irq1: {
	irq_start(end)

  // we have to reset the XSCROLL values to 0 (bits 0-2) as we don't want the bitmap section to move
  lda $d016
  and #%11111000
  sta $d016

  SwitchVICBank(vic_bank_bitmap)
  SetScreenMemory(screen_memory_bitmap - vic_base_bitmap)
  SetBitmapAddress(bitmap_address_bitmap - vic_base_bitmap)
  SetHiresBitmapMode()
  jsr scroller_update

  irq_end(irq2, scanline_2)
end:
	rti
}

//  +------------------------------------------------------------------------------------------------------------------------------+
//  | Textmap mode                                                                                                                 |
//  +------------------------------------------------------------------------------------------------------------------------------+
irq2: {
	irq_start(end)

// 1
  nop
  nop

  SwitchVICBank(vic_bank_textmode)
  lda #%00011011      // Default is Multicolor text mode : $1B or %00011011
  sta $d011
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

  // lets set the XSCROLL to smoothly move the top scroller
  lda framecount
  and #7
  eor #7              // xor bits 0-2 and leave bit 3 zero for 38 column mode
  sta $d016
  sta x_scroll_value

  lda #%00000010      // Default: $C8, %11001000
  sta $d018

  irq_end(irq3, scanline_3)
end:
	rti
}


//  +------------------------------------------------------------------------------------------------------------------------------+
//  | Bitmap mode                                                                                                                  |
//  +------------------------------------------------------------------------------------------------------------------------------+
irq3: {
	irq_start(end)

  // we have to reset the XSCROLL values to 0 (bits 0-2) as we don't want the bitmap section to move
  lda $d016
  and #%11111000
  sta $d016

  SwitchVICBank(vic_bank_bitmap)
  SetScreenMemory(screen_memory_bitmap - vic_base_bitmap)
  SetBitmapAddress(bitmap_address_bitmap - vic_base_bitmap)
  SetHiresBitmapMode()

	irq_end(irq4, scanline_4)
end:
	rti
}


//  +------------------------------------------------------------------------------------------------------------------------------+
//  | Textmap mode                                                                                                                 |
//  +------------------------------------------------------------------------------------------------------------------------------+
irq4: {
  irq_start(end)

  nop

  SwitchVICBank(vic_bank_textmode)
  lda #%00011011      // Default is Multicolor text mode : $1B or %00011011
  sta $d011
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

  lda x_scroll_value
  sta $d016

  lda #%00000010      // Default: $C8, %11001000
  sta $d018

  irq_end(irq5, scanline_5)
end:
  rti
}


//  +------------------------------------------------------------------------------------------------------------------------------+
//  | Bitmap mode                                                                                                                  |
//  +------------------------------------------------------------------------------------------------------------------------------+
irq5: {
	irq_start(end)

  // we have to reset the XSCROLL values to 0 (bits 0-2) as we don't want the bitmap section to move
  lda $d016
  and #%11111000
  sta $d016

  SwitchVICBank(vic_bank_bitmap)
  SetScreenMemory(screen_memory_bitmap - vic_base_bitmap)
  SetBitmapAddress(bitmap_address_bitmap - vic_base_bitmap)
  SetHiresBitmapMode()

	irq_end(irq0, scanline_0)
end:
	rti
}
