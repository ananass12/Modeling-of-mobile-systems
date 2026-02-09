#include <stdio.h>
#include <string.h>

int main(){
    int n = 10;

    char str[n];
    printf("Введите строку: ");
    fgets(str, sizeof(str), stdin);

    int a;
    int len = strlen(str);

    if (len > 0 && str[len-1]=='\n'){
        str[len - 1] = '\0';
        len--;
    }

    for (int j = 0; str[j] != '\0'; j++){
        int bin = dec2bin(str[j]);
        int dec = bin2dec(bin);
        printf("%c", dec);
    }
    printf("\n");

    return 0;
}