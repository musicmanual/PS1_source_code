
#include <stdint.h>
#include <stddef.h>

/*
 * PSX_HelloWorld.c
 *
 * C conversion of:
 * https://github.com/musicmanual/PS1_source_code/blob/main/PSX_HelloWorld.asm
 *
 * Hardware:
 *   GPU GP0: 0x1F801810
 *   GPU GP1: 0x1F801814
 *
 * Font96.fnt must be embedded as Font96[].
 */

#define GPU_GP0 (*(volatile uint32_t *)0x1F801810)
#define GPU_GP1 (*(volatile uint32_t *)0x1F801814)

#define USER_RAM 0x00020000

#define CURSOR_X 0x100
#define CURSOR_Y 0x101

#define SCREEN_WIDTH  320
#define SCREEN_HEIGHT 240

/* Supply the original ResALL/Font96.fnt as an embedded array. */
extern const unsigned char Font96[];

/* Cursor variables in the original assembly's RAM layout. */
static volatile unsigned char * const user_ram =
    (volatile unsigned char *)USER_RAM;


/* Write a command to the GPU's GP0 port. */
static inline void gpu_command(uint32_t command)
{
    GPU_GP0 = command;
}

/* Write a command to the GPU's GP1 control port. */
static inline void gpu_control(uint32_t command)
{
    GPU_GP1 = command;
}


/* ---------------------------------------------------------
   Initialize the display.
   Equivalent to the setup at the beginning of the assembly.
   --------------------------------------------------------- */
static void InitScreen(void)
{
    gpu_control(0x00000000);  /* Reset GPU */
    gpu_control(0x03000000);  /* Display enable */
    gpu_control(0x08000001);  /* 320x240, 16-bit display mode */
    gpu_control(0x06C60260);  /* Horizontal display range */
    gpu_control(0x07042018);  /* Vertical display range */

    gpu_command(0xE1000400);  /* Drawing mode */
    gpu_command(0xE3000000);  /* Drawing area top-left */
    gpu_command(0xE403BD3F);  /* Drawing area bottom-right */
    gpu_command(0xE5000000);  /* Drawing offset */
}


/* ---------------------------------------------------------
   Clear the screen.
   Equivalent to the assembly's Cls function.
   --------------------------------------------------------- */
static void Cls(void)
{
    gpu_command(0x027F0000);  /* Fill rectangle, original color */
    gpu_command(0x00000000);  /* Top-left coordinate (0, 0) */
    gpu_command(0x0EF0013F);  /* Width 320, height 240 */

    user_ram[CURSOR_X] = 0;
    user_ram[CURSOR_Y] = 0;
}


/* ---------------------------------------------------------
   Print one character using the original 8x8 font.

   Each font character occupies 8 bytes.
   Each source pixel is encoded using 2 bits.
   The output is uploaded to VRAM through GP0.
   --------------------------------------------------------- */
static void PrintChar(unsigned char ch)
{
    if (ch < 32)
        return;

    const unsigned char *font =
        &Font96[(unsigned int)(ch - 32) * 8];

    unsigned int x = user_ram[CURSOR_X] * 8;
    unsigned int y = user_ram[CURSOR_Y] * 8;

    /* Upload an 8x8 image to VRAM. */
    gpu_command(0xA0000000);
    gpu_command(((y & 0xFFFF) << 16) | (x & 0xFFFF));
    gpu_command(0x00080008);

    for (unsigned int row = 0; row < 8; row++)
    {
        unsigned char bits = font[row];

        for (unsigned int pair = 0; pair < 4; pair++)
        {
            /*
             * Preserve the original assembly's pixel colors:
             *   OFF = 0x3C00
             *   ON  = 0x03FF
             *
             * PS1 GP0 image uploads pack two 16-bit pixels
             * into each 32-bit data word.
             */
            unsigned int pixel1 =
                (bits & 0x80) ? 0x03FF : 0x3C00;

            unsigned int pixel2 =
                (bits & 0x40) ? 0x03FF : 0x3C00;

            gpu_command((pixel2 << 16) | pixel1);

            bits <<= 2;
        }
    }

    user_ram[CURSOR_X]++;
}


/* ---------------------------------------------------------
   Print a null-terminated C string.
   Equivalent to PrintString in the assembly.
   --------------------------------------------------------- */
static void PrintString(const char *text)
{
    while (*text != '\0')
    {
        PrintChar((unsigned char)*text);
        text++;
    }
}


/* ---------------------------------------------------------
   Move the text cursor to the beginning of the next line.
   Equivalent to NewLine in the assembly.
   --------------------------------------------------------- */
static void NewLine(void)
{
    user_ram[CURSOR_Y]++;
    user_ram[CURSOR_X] = 0;
}


/* ---------------------------------------------------------
   Program entry point.
   Requires a PS1-compatible startup and linker configuration.
   --------------------------------------------------------- */
int main(void)
{
    InitScreen();

    Cls();

    PrintString("Hello World!");

    NewLine();

    PrintString("Hello World!");

    /* Equivalent to InfLoop in the assembly. */
    for (;;)
    {
        __asm__ volatile ("nop");
    }

    return 0;
}
