
typedef unsigned char  uc;

typedef struct _Variance{
    int va;
    int height;
    float ang;
    int oldva;
} Varivance;
#include <stdlib.h>
#include <sys/time.h>
#include <stdio.h>
#include <time.h>
#include <dlfcn.h>
#include <math.h>
#import "LibScanIDCard.h"
#import "string.h"

#ifdef __cplusplus
extern "C" {
#endif
#ifdef __cplusplus
}
#endif
extern int onetable[256];
extern char templateImage[36][200][25];
extern int charcount[36];
/*
 extern int byteOneCount[256];
 extern char templateImage[36][200][25];
 extern int charTemplateCount[36];
 */
static void free2DArray(void** array, int length){
    for (int i = 0; i < length; i++) {
        free(array[i]);
    }
    free(array);
}

static int cmpVarianceIDCard(const void* a,const void* b){
    return (( Varivance *)b)->va-((Varivance *)a)->va;
}
int cmpheightIDCard(const void* a,const void* b){
    return ((Varivance*)a)->height-((Varivance*)b)->height;
}
static void blackImageIDCard(int oldwidth,int oldheight,uc **grayimage,int gWidth,int gHeight,uc **blackimage){
    uc thre[4] = {0};
    uc means1 = 0;
    uc means2 = 0;
    int sub1 = 0;
    int sub2 = 0;
    int sub1count = 0;
    int sub2count = 0;
    for(int i = 0;i<(int)(gWidth/100);i++){
        uc finalthre = 0;
        uc inithreshold = 40;
        while(finalthre!=inithreshold){
            finalthre = inithreshold;
            sub1 = sub1count = sub2 = sub2count = 0;
            for(int j = 0;j<(gHeight*100);j++){
                uc pixtmp = grayimage[j/100][i*100+j%100];
                if(pixtmp<=inithreshold){
                    sub1+=pixtmp;
                    sub1count++;
                }else{
                    sub2+=pixtmp;
                    sub2count++;
                }
            }
            means1 = sub1count==0? inithreshold:sub1/sub1count;
            means2 = sub2count==0? inithreshold:sub2/sub2count;
            inithreshold = (means1+means2)/2;
            if(((float)sub2count/sub1count)<8&&inithreshold>finalthre){
                break;
            }
        }
        thre[i] = finalthre;
    }
    for(int i =0;i<oldheight;i++){
        uc tmp = 0;
        uc tmpbyte = 0;
        for(int j = 0;j<oldwidth;j++){
            if(grayimage[i][j]<thre[j/100]){
                tmpbyte = (tmpbyte<<1)+1;
            }else{
                tmpbyte=tmpbyte<<1;
            }

            tmp++;
            if(tmp == 8){
                blackimage[i][j/8] = tmpbyte;
                tmp = 0;
                tmpbyte = 0;
            }
        }

        blackimage[i][gWidth/8] = tmpbyte<<4;
    }
}
static int getVarianceIDCard(int oldwidth,int oldheight,uc **blackimage,float ang,int height){
    int result = 0;
    for(int i = 0;i<oldwidth;i+=8){
        int h = (int)round(i*ang)+height;
        if(h<0||h>=oldheight) break;
        int wid = i/8;
        uc tmp = ((blackimage[h][wid]>>1)^(blackimage[h][wid])&0x7f);
        result += onetable[tmp];
        if((blackimage[h][wid]&1) != ((blackimage[h][wid+1]&0x80)>>7)){
            result++;
        }
    }
    return result;
}
static int getMeansIDCard(int* a,int count){
    int total = 0;
    for(int i = 0;i<count;i++){
        total += a[i];
    }
    return (int)roundf((float)total/count);
}
//ps: specified for id card
static bool checkIntIDCard(int oldwidth,int oldheight,uc **blackimage,int* a,float ang){
    float d1;//, d2, d3;
    d1 = a[1] - a[0];
    float width = d1 / 3;
    for (int j = 1; j < 3; j++) {
//        int temp=getVarianceIDCard(oldwidth,oldheight,blackimage,ang, roundf(a[0]+j*width));
        if (getVarianceIDCard(oldwidth,oldheight,blackimage,ang, roundf(a[0]+j*width)) < 20) {
            return false;
        }
    }
    return true;
}
static bool getHeightEdgeIDCard(int oldwidth,int oldheight,uc **blackimage,int bWidth,int bHeight,float* angle,int* heightEdge){//100*51
    if(oldwidth<=0)
        return false;
    if(oldheight<=0)
        return false;
    Varivance varivances[5][bHeight];
    struct VarivanceNode {
        struct VarivanceNode *next;
        struct VarivanceNode *before;
        float ang;
        int va;
    };
    struct VarivanceNode *head = NULL;
    struct VarivanceNode *tail = NULL;
    int maxva = 0, minva = 0xfffff;
    int count = 0;
    struct VarivanceNode nodes[5*bHeight];
    int nodescount = 0;
    for (int i = -2; i <= 2; i++) {
        for (int j = 0; j < oldheight; j++) {
            float ii = (float) i / 100;
            int varivance = getVarianceIDCard(oldwidth, oldheight, blackimage, ii, j);
            if (j <= 5) {
                Varivance v = {0, 0, 0, varivance};
                varivances[i + 2][j] = v;
            } else {
                Varivance v = {abs(varivance - varivances[i + 2][j - 6].oldva), j - 3, ii,
                    varivance};
                varivances[i + 2][j] = v;
                if (v.va > minva || count < 10) {
                    struct VarivanceNode *node = &(nodes[nodescount++]);
                    node->ang = ii;
                    node->va = v.va;
                    node->next = NULL;
                    node->before = NULL;
                    if (count < 10) {
                        if (count == 0) {
                            maxva = minva = v.va;
                            head = node;
                            tail = node;
                        } else {
                            if (maxva <= v.va) {
                                maxva = v.va;
                                node->next = head;
                                head->before = node;
                                head = node;
                            } else if (minva > v.va) {
                                minva = v.va;
                                node->before = tail;
                                tail->next = node;
                                tail = node;
                            }else {
                                for (node->next = head; node->va <
                                     node->next->va; node->next = node->next->next) { }
                                node->before = node->next->before;
                                node->before->next = node;
                                node->next->before = node;
                            }
                        }
                        count++;
                    } else {
                        node->next = head;
                        for (; node->va < node->next->va; node->next = node->next->next) { }
                        if (node->next != head) {
                            node->before = node->next->before;
                            node->before->next = node;
                        } else {
                            head = node;
                        }
                        node->next->before = node;
                        tail = tail->before;
                        minva = tail->va;
                        tail->next = NULL;
                    }
                }
            }
        }
    }
    float countva = 0;
    count = 0;
    for (; ;) {
        count++;
        if (head != NULL&&head->ang==head->ang) {
            countva += head->ang;
            if (head->next != NULL) {
                head = head->next;
            } else {
                head = NULL;
                break;
            }
        }
    }
    int ang = (int) roundf(countva *= 10) + 2;
    *angle = (float) (ang - 2) / 100;
    Varivance *v = varivances[ang];
    qsort(v, oldheight, sizeof(Varivance), cmpVarianceIDCard);
    qsort(v, 24, sizeof(Varivance), cmpheightIDCard);
    int heights[24];
    count = 0;
    int peaks[24] = {0};
    int peaknum = 0;
    for (int i = 0; i < 24; i++) {
        int h = v[i].height;
        if (count == 0) {
            heights[count++] = h;
        } else if (heights[count - 1] + 3 < h) {
            peaks[peaknum++] = getMeansIDCard(heights, count);
            count = 1;
            heights[0] = h;
        } else {
            heights[count++] = h;
        }
    }
    if (count > 1) {
        peaks[peaknum++] = getMeansIDCard(heights, count);
    }
    for (int i = 0; i < peaknum - 1; i++) {
        if (checkIntIDCard(oldwidth, oldheight, blackimage, &(peaks[0]), *angle)) {
            heightEdge[0] = peaks[0];
            heightEdge[1] = peaks[1];
            return true;
        }
    }
    return false;
}
static uc getpixelbyblackimageIDCard(uc **blackimage,int x,int y){
    if (x < 0 || y < 0) {
        return 0;
    }
    return (blackimage[y][x/8]>>(7-x%8))&1;
}
//ps: different
static bool generateLetterXIDCard(int up,int down,uc **blackimage,float angle,int width,int height,int result[130],int* spaces){
    int x12[120][2] = {0};
    uc count = 0;
    uc d = (down-up)/3;
    up = up-d<0?0:up-d;
    down = down+d>height?height:down+d;
    int lastWhite = -1;
    for(int i =0;i<width;i++){
        int isWhite = 0;
        int startY = (int)(down+angle*i);
        startY = startY>=height?height-1:startY;
        for (int j = 0; j < down - up; j++) {
            if (i + (j * angle) < 0 || i + (j * angle) >= width) {
                continue;
            }
            uc rgb = getpixelbyblackimageIDCard(blackimage, (i + (j * angle)), startY - j);
            if(rgb != 0){
                isWhite += 1;
                if (isWhite >= 2) {
                    break;
                }
            }
        }
        if (isWhite > 1) {
            if (lastWhite != -1) {
                if (i - lastWhite == 1) {
                    lastWhite = -1;
                    continue;
                }
                x12[count][0] = lastWhite;
                x12[count++][1] = i-lastWhite;
                lastWhite = -1;
            }
        } else {
            if (lastWhite == -1) {
                lastWhite = i;
                if(count!=0&&x12[count-1][0]+x12[count-1][1]>=i-2){
                    lastWhite = x12[count-1][0];
                    count--;
                }
            }
        }
    }
    if (lastWhite != -1) {
        x12[count][0] = lastWhite;
        x12[count++][1] = width+1-lastWhite;
    }
    if (count < 17) {
        return false;
    }
    int resultcount  = 0;
    if(x12[0][0] == 0){
        result[resultcount++] = x12[0][1]-1;
    } else {
        result[resultcount++] = 0;
        result[resultcount++] = x12[0][0];
        result[resultcount++] = x12[0][1]+x12[0][0]-1;
    }
    int maxWidth =  width/ 17;
    for (int i = 1; i < count; i++) {
       if(x12[i][1]>maxWidth){
            if (resultcount > 19) {
                result[resultcount++] = x12[i][0];
                break;
            }
            resultcount = 0;
            result[resultcount++] = x12[i][0]+x12[i][1]-1;
        } else {
            if(x12[i][0]-result[resultcount-1]>(float)width/17){
                return false;
           }
            result[resultcount++] = x12[i][0];
            if(i!=count-1){
                result[resultcount++] = x12[i][0]+x12[i][1]-1;
            }
       }
    }
    if(resultcount < 18){
        return false;
    }
    *spaces = resultcount;
    return true;
}

static int checkWhiteIDCard(uc **blackImage,int x1,int x2,int y){
    int count = 0;
    for (int i = 0; i < x2 - x1 + 1; i++) {
        if(getpixelbyblackimageIDCard(blackImage, x1+i, y) != 0){
            count++;
            if (count > 3) {
                return count;
            }
        }
    }
    return count;
}
static void expandFourIntIDCard(int letteredge[4],uc **blackImage,int width,int height){
    int flag = -1;
    while (flag != 0) {
        if (flag < 0) {
            if (checkWhiteIDCard(blackImage, letteredge[0], letteredge[2], letteredge[1] - 1) >= 2) {
                letteredge[1]+=flag;
                if (letteredge[1]== 0) {
                    flag = 0;
                }
            } else {
                flag = 1;
            }
        } else {
            if (checkWhiteIDCard(blackImage, letteredge[0], letteredge[2], letteredge[1]) < 2) {
                letteredge[1] += flag;
                if (letteredge[1] == height - 1 || letteredge[1] == letteredge[3] - 3) {
                    flag = 0;
                }
            } else {
                flag = 0;
            }
        }
    }
    flag = 1;
    while (flag != 0) {
        if (flag > 0) {
            if (checkWhiteIDCard(blackImage, letteredge[0], letteredge[2], letteredge[3] + 1) >= 2) {
                letteredge[3]+= flag;
                if (letteredge[3] == height - 1) {
                    flag = 0;
                }
            } else {
                flag = -1;
            }
        } else {
            if (checkWhiteIDCard(blackImage, letteredge[0], letteredge[2], letteredge[3]) < 2) {
                letteredge[3] += flag;
                if (letteredge[3] == 0 || letteredge[3] == letteredge[1] + 2) {
                    flag = 0;
                }
            } else {
                flag = 0;
            }
        }
    }
}
//PS: different
static bool getlettersxyIDCard(int **letters,int upletterX[130],int heightedge[2],uc **blackImage,float angle,int width,int height,int upspaces){
    int count = 0;
    int leftX = -1;
    int diff;
        for (int i = 0; i < upspaces; i++) {
            if (count >= 18) {
                return false;
            }
        if (leftX == -1) {
            leftX = upletterX[i];
            continue;
        }
        diff = angle*(leftX+1);
        int letteredge[4] = {leftX+1,heightedge[0]+diff,upletterX[i]-1,heightedge[1]+diff};
        expandFourIntIDCard(letteredge, blackImage,width,height);
        if(letteredge[3]-letteredge[1]+1>(heightedge[1]-heightedge[0]+1)*0.6&&letteredge[3]-letteredge[1]+1<(heightedge[1]-heightedge[0]+1)*1.35){
            letters[count][0] = letteredge[0];
            letters[count][1] = letteredge[1];
            letters[count][2] = letteredge[2];
            letters[count++][3] = letteredge[3];
        }
        leftX = -1;
    }
    return true;
}
static char getcharbyintIDCard(int maxI){
    if (maxI < 10) {
        char a = 48+maxI;
        return a;
    }
    return 'X';
}
void static ocrIDCard(uc **letterimage,int letterNum,char* result,int* iaa) {
    int min = 0xfffff; 
    int answer = 0;
    for(int m = 0;m<letterNum;m++){
        answer = 0;
        min = 0xfffff;
        for(int k = 0;k<36;k++){
            for(int l =0;l<charcount[k];l++){
                int relations = 0;
                for(int i = 0;i<25;i++){
                    uc r =letterimage[m][i]^templateImage[k][l][i];
                    relations += onetable[r];
                }
                if(relations<min){
                    min = relations;
                    answer = k;
                }
            }
        }
        result[m] = getcharbyintIDCard(answer);
    }
}
static bool CheckValue(char* result) {
    //region  check null
    for(int i=0;i<18;i++){
        if(result[i]==' '||!result[i]){
            return false;
        }
    }
    //endregion
    //region //first
    if(result[0]<'1'||result[0]>'9'){
        return false;
    }
    //endregion
    //region //y
    if(result[6]!='1'&&result[6]!='2'){
        return false;
    }
    //endregion
    //region //m
    if(result[10]!='0'&&result[10]!='1'){
        return false;
    }
    //endregion
    //region //d
    if(result[12]!='0'&&result[12]!='1'&&result[12]!='2'&&result[12]!='3'){
        return false;
    }
    //endregion
    return true;
}

static void dividecharIDCard(uc **blackimage,int **lettersxy,uc **letterimage,int letterNum,int imageWidth,int imageHeight){
    int width,height;
    for(int i = 0;i<letterNum;i++){
        width = lettersxy[i][2]-lettersxy[i][0]+1;
        height = lettersxy[i][3]-lettersxy[i][1]+1;
        uc **image;//[100][407] = {0};
        image = (uc**)malloc(sizeof(uc*)*imageHeight);
        *image = (uc*)malloc(sizeof(**image) * imageWidth * imageHeight);
        memset(*image, 0, imageHeight * imageWidth);
        for (int i = 1; i < imageHeight; i++) {
//            image[i] = (uc*)malloc(sizeof(**image)*imageWidth);
//            memset(image[i], 0, imageWidth);
            image[i] = *image + imageWidth * i;
        }
        for(int j = 0;j<height;j++){
            for(int k = 0;k<width;k++){
                char a =getpixelbyblackimageIDCard(blackimage, k+lettersxy[i][0], j+lettersxy[i][1]);
                image[j][k] = a;
            }
        }
        float pixelwidth = (float)width/13;
        float pixelheight = (float)height/15;
        int flag = 0;
        int count = 0;
        for(int j = 0;j<15;j++){
            for(int k = 0;k<13;k++){
                float startx = k*pixelwidth;
                float starty = j*pixelheight;
                float endx = startx+pixelwidth;
                float endy = starty+pixelheight;
                float color = 0;
                for(int m = (int) starty;m<=(int)endy;m++){
                    if(m == height){
                        break;
                    }
                    float d;

                    if(m == (int)starty){
                        if(m == (int)endy){
                            d = endy-starty;
                        }else{
                            d = m+1-starty;
                        }
                    }else{
                        if(m == (int)endy){
                            d = endy-m;
                        }else{
                            d = 1;
                        }
                    }

                    if(d == 0 ){
                        break;
                    }
                    for(int n = (int) startx;n<=(int)endx;n++){
                        if(n == width){
                            break;
                        }
                        float dd;
                        if(n == (int)startx){
                            if(n == (int)endx){
                                dd = endx-startx;
                            }else{
                                dd = n+1-startx;
                            }
                        }else{
                            if(n == (int)endx){
                                dd = endx-n;
                            }else{
                                dd = 1;
                            }
                        }
                        color += d*dd*image[m][n];
                    }
                }
                if(color/((endy-starty)*(endx-startx))>=0.5){
                    letterimage[i][flag] = (letterimage[i][flag]<<1)+1;
                    count++;
                    if(count == 8){
                        flag++;
                        count = 0;
                    }
                }else{
                    letterimage[i][flag] = (letterimage[i][flag]<<1)+0;
                    count++;
                    if(count == 8){
                        flag++;
                        count = 0;
                    }
            }
            }
        }
//        free2DArray((void**)image, imageHeight);
        free(*image);
        free(image);
    }
}
static void generateGrayImageIDCard(int8_t* arr,uc **grayimage,int imageWidth,int imageHeight,int hw,int hh,int x,int y,int w,int h){
    float pixelwidth =(float)w/imageWidth;
    float pixelheight =(float)h/imageHeight;
    for(int j = 0;j<imageHeight;j++){
        for(int k = 0;k<imageWidth;k++) {
            float startx = x + k * pixelwidth;
            float starty = y + j * pixelheight;
            float endx = startx + pixelwidth;
            float endy = starty + pixelheight;
            float color = 0;
            for (int m = (int) starty; m <= (int) endy; m++) {
                if (m == y + h) {
                    break;
                }
                float d;
                if (m == (int) starty) {
                    if (m == (int) endy) {
                        d = endy - starty;
                    } else {
                        d = m + 1 - starty;
                    }
                } else {
                    if (m == (int) endy) {
                        d = endy - m;
                    } else {
                        d = 1;
                    }
                }
                if (d == 0) {
                    break;
                }
                for (int n = (int) startx; n <= (int) endx; n++) {
                    if (n == x + w) {
                        break;
                    }
                    float dd;
                    if (n == (int) startx) {
                        if (n == (int) endx) {
                            dd = endx - startx;
                        } else {
                            dd = n + 1 - startx;
                        }
                    } else {
                        if (n == (int) endx) {
                            dd = endx - n;
                        } else {
                            dd = 1;
                        }
                    }
                    color += d * dd * ((int) (*(arr + m * hw + n)) & 0xff);
                }
            }
            if (color / ((endy - starty) * (endx - startx)) >= 0.5) {
            if (endy != starty && endx != startx) {
            grayimage[j][k] = roundf(color / ((endy - starty) * (endx - startx)));
        }
            }
        }
    }
}
char* LibScanIDCard_scanByteIDCard(int8_t *arr, int hw, int hh, int x, int y, int w, int h){
    uc **letterimage;//[18][25]={0};
    letterimage = (uc**)malloc(sizeof(uc*)*18);
    *letterimage = (uc*)malloc(18 * 25 * sizeof(uc));
    memset(*letterimage, 0, 18 * 25);
    for (int i = 1; i < 18; i++) {
        letterimage[i] = *letterimage + i * 25;
    }
    uc **grayimage;//[100][407]={0};
    grayimage = (uc**)malloc(sizeof(uc*)*100);
    *grayimage = (uc*)malloc(sizeof(**grayimage) * 100 * 407);
    memset(*grayimage, 0, 100 * 407);
    for (int i = 1; i < 100; i++) {
        grayimage[i] = *grayimage + i * 407;
    }
    uc **blackimage;//[100][51]={0};
    blackimage = (uc**)malloc(sizeof(uc*)*100);
    *blackimage = (uc*)malloc(sizeof(**blackimage) * 51 * 100);
    memset(*blackimage, 0, 51 * 100);
    for (int i = 1; i < 100; i++) {
        blackimage[i] = *blackimage + i * 51;
    }
    int width = 407;
    int height = 100;
    float angle = 0;
    int heightEdge[2]={0};
    generateGrayImageIDCard(arr,grayimage,407,100,hw,hh,x,y,w,h);
     blackImageIDCard(width,height,grayimage,407,100,blackimage);
    char *result = new char[19];
    memset(result, 0, 19 * sizeof(char));
    int upletterX[130] = {0};
    int upwhitespaces = 0;
    int **lettersxy;//[18][4] = {0};
    lettersxy = (int**)malloc(sizeof(int*)*18);
    *lettersxy = (int*)malloc(sizeof(**lettersxy) * 4 * 18);
    memset(*lettersxy, 0, 4 * 18);
    for (int i = 1; i < 18; i++) {
        lettersxy[i] = *lettersxy + 4 * i;
    }
    
    if(getHeightEdgeIDCard(width,height,blackimage,51,100,&angle,(int*) heightEdge)){
       if(generateLetterXIDCard(heightEdge[0],heightEdge[1],blackimage,angle,width,height,upletterX,&upwhitespaces)){
            if(getlettersxyIDCard(lettersxy,upletterX,heightEdge,blackimage,angle,width,height,upwhitespaces)){
                dividecharIDCard(blackimage,lettersxy,letterimage,18,407,100);
                ocrIDCard(letterimage,18,result,NULL);
                printf("%s",result);
                if(CheckValue(result)){
                    if(result[0] == 0){
                        result[1] = 0;
                    }
                    else {
                        int bbb[72];
                        for (int i = 0; i < 18; i++) {
                            for (int j = 0; j < 4; j++) {
                                bbb[i * 4 + j] = lettersxy[i][j];
                            }
                        }
                    }
                    free(*blackimage);
                    free(blackimage);
                    free(*grayimage);
                    free(grayimage);
                    free(*letterimage);
                    free(letterimage);
                    free(*lettersxy);
                    free(lettersxy);
                    return result;
                }
            }
        }
    }
    else {
        printf("寻找上下边框失败");
    }
    free(*blackimage);
    free(blackimage);
    free(*grayimage);
    free(grayimage);
    free(*lettersxy);
    free(lettersxy);
    free(*letterimage);
    free(letterimage);
    result[0]=0;
    return result;
}