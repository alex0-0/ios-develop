#ifndef _LibScanPassport
#define _LibScanPassport
#ifdef __cplusplus
extern "C" {
#endif
    
    char* LibScanPassport_scanByte(int8_t* arr,int hw,int hh,int x,int y,int w,int h);
    
    uint8_t *tmpGrayImage();
    
    uint8_t *tmpBlackImage();
    
    
#ifdef __cplusplus
}
#endif
#endif
