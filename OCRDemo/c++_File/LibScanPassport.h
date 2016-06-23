#ifndef _LibScanPassport
#define _LibScanPassport
#ifdef __cplusplus
extern "C" {
#endif
    
    char* LibScanPassport_scanByte(int8_t* arr,int hw,int hh,int x,int y,int w,int h);
    char* LibScanPassport_test(int8_t *arr, int hw, int hh, int x, int y, int w, int h);
    extern void saveSmallBitmap(int* arr);
    extern void saveBitmap(int* arr);
    extern void saveLetterPos(int *pos);
    
#ifdef __cplusplus
}
#endif
#endif
