#include <stdio.h>

extern "C" int MyPrintf (const char * strng, ...);

int main ()
{
    const char *format = "%d\n%b\n%c\n%s\n%%\n%x\n%c\n%o\n%o\n";
    int         par1 = -12345;
    int         par2 = 5;
    const char  par3 = 'c';
    const char *par4 = "STRING";
    int         par5 = 0xA1B2C3DE;
    const char  par6 = 'f';
    int         par7 = -1234;
    int         par8 = 05555;

    
    MyPrintf ("%d %s %x %d %% %c %b\n", -1, "love", 3802, 100, 33, 30);
    MyPrintf ("%d\n%b\n%c\n%s\n%%\n%x\n%c\n%o\n%o\n%d %s %x %d %% %c %b\n", par1, par2, par3,
                      par4, par5, par6, par7, par8,
                      -1, "love", 3802, 100, 33, 30);


    printf ("Mama, pomogi mne, I am %d lenght\n", 3);
}