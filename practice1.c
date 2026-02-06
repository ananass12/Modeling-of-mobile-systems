// кодер-декодер

#include <stdio.h>
#include <string.h>

int dec2bin(int n){
    int bin = 0, i = 1;

    while(n){
        bin += (n % 2 )*i;
        i *= 10;
        n /= 2;
    }
    return bin;
}

int bin2dec(int n){
    int dec = 0, i = 1;
    while(n){
        dec += (n % 10)*i;
        i *= 2;
        n /= 10;
    }
    return dec;
}

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

    for (int j = 0; j < len; j++){
        printf("%d ", str[j]);
    }
    printf("\n");


    for (int j = 0; j < len; j++){
        a = dec2bin(str[j]);          
        printf("%d ", a);
    }
    printf("\n");

    for (int j = 0; j < len; j++){
        a = dec2bin(str[j]);
        printf("%d", a);
    }
    printf("\n");

    for (int j = 0; str[j] != '\0'; j++){
        int bin = dec2bin(str[j]);
        int dec = bin2dec(bin);
        printf("%c", dec);
    }
    printf("\n");

    return 0;
}