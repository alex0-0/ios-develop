#include <stdlib.h>
#include <time.h>
#include "LibScanPassport.h"
#include <sys/time.h>
#import "ScannerController.h"

#include <stdio.h>
#include <dlfcn.h>
#include <math.h>


#ifdef __cplusplus
extern "C" {
#endif
    
#ifdef __cplusplus
}
#endif
extern int onetable[256];
extern char templateImage[36][200][25];
extern int charcount[36];

typedef unsigned char  uc;

typedef struct _Variance{
    int va;
    int height;
    float ang;
    int oldva;
} Varivance;

int times = 0;

static int cmpVariance(const void* a,const void* b){
    return (( Varivance *)b)->va-((Varivance *)a)->va;
}

int cmpheight(const void* a,const void* b){
    return ((Varivance*)a)->height-((Varivance*)b)->height;
}

//二值化 黑色为1， 白色为0      //TODO: Otsu's method may be a better method to get black image
static void blackImage(int oldwidth,int oldheight,uc grayimage[135][700],uc blackimage[135][88]){
    //    int threshold = otsu(oldwidth,oldheight,grayimage);
    uc thre[7] = {0};
    uc means1 = 0;
    uc means2 = 0;
    int sub1 = 0;
    int sub2 = 0;
    int sub1count = 0;
    int sub2count = 0;
    for(int i = 0;i<7;i++){
        uc finalthre = 0;
        uc inithreshold = 40;
        while(finalthre!=inithreshold){
            finalthre = inithreshold;
            sub1 = sub1count = sub2 = sub2count = 0;
            for(int j = 0;j<13100;j++){
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
        blackimage[i][87] = tmpbyte<<4;
    }
}

static int getVariance(int oldwidth,int oldheight,uc blackimage[135][88],float ang,int height){
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

static int getMeans(int* a,int count){
    int total = 0;
    for(int i = 0;i<count;i++){
        total += a[i];
    }
    return (int)roundf((float)total/count);
}

static bool checkInt(int oldwidth,int oldheight,uc blackimage[135][88],int* a,float ang){
    float d1, d2, d3;
    d1 = a[1] - a[0];
    d2 = a[2] - a[1];
    d3 = a[3] - a[2];
    if (d1 / d3 > 1.4 || d1 / d3 < 0.7) {
        return false;
    }
    if (d2 / ((d1 + d3) / 2) < 1 || d2 / ((d1 + d3) / 2) > 1.8) {
        return false;
    }
    float width = d2 * 0.5;// willard 检测中间 白条 宽度 为0.5
    float diff = width/5;
    for (float j = -width / 2; j < width / 2; j += diff) {
        if(getVariance(oldwidth,oldheight,blackimage,ang, roundf(((float)(a[2]+a[1]))/2+j))>15){
            return false;
        }
    }
    width = d1 / 3;
    for (int j = 1; j < 3; j++) {
        //        int var = variance(blackImage, peak.get(i) + j * width, angle);
        if (getVariance(oldwidth,oldheight,blackimage,ang, roundf(a[0]+j*width)) < 80) {
            return false;
        }
    }
    width = d3 / 3;
    for (int j = 1; j < 3; j++) {
        //        int var = variance(blackImage, peak.get(i + 2) + j * width, angle);
        if (getVariance(oldwidth,oldheight,blackimage,ang, roundf(a[2]+j*width)) < 80) {
            return false;
        }
    }
    return true;
}

static bool getHeightEdge(int oldwidth,int oldheight,uc blackimage[135][88],float* angle,int* heightEdge){
    Varivance varivances[5][135];//todo 倾斜角度优化
    struct VarivanceNode {
        struct VarivanceNode *next ;
        struct VarivanceNode *before ;
        float ang;
        int va;
    };
    struct VarivanceNode *head = NULL;
    struct VarivanceNode *tail = NULL;
    int maxva = 0,minva = 0xfffff;
    int count = 0;
    struct VarivanceNode nodes[700];
    int nodescount = 0;
    //计算所有角度的方差值
    for(int i =-2;i<=2;i++){
        for (int j = 0; j<oldheight; j++) {
            float ii = (float)i/100;
            int varivance = getVariance(oldwidth,oldheight,blackimage,ii, j);
            if(j<=5){
                Varivance v = {0,0,0,varivance};
                varivances[i+2][j] = v;
            }else{
                Varivance v = {abs(varivance-varivances[i+2][j-6].oldva),j-3,ii,varivance};
                varivances[i+2][j] =v;
                if(v.va>minva||count <10){
                    //                    struct VarivanceNode * node = (struct VarivanceNode *)malloc(sizeof(VarivanceNode));
                    struct VarivanceNode* node = &(nodes[nodescount++]);
                    node->ang = ii;
                    node->va = v.va;
                    node->next = NULL;
                    node->before = NULL;
                    //                    struct VarivanceNode node = {NULL,NULL,ii,v.va};
                    if(count<10){
                        if(count == 0){
                            maxva =minva= v.va;
                            head = node;
                            tail = node;
                        }else{
                            if(maxva<=v.va){
                                maxva = v.va;
                                node->next = head;
                                head->before = node;
                                head = node;
                            }else if (minva> v.va) {
                                minva = v.va;
                                node->before = tail;
                                tail->next = node;
                                tail = node;
                            }else{
                                for(node->next = head;node->va<node->next->va;node->next = node->next->next) {}
                                node->before = node->next->before;
                                node->before->next = node;
                                node->next->before = node;
                            }
                        }
                        count++;
                    }else{
                        node->next = head;
                        for(;node->va<node->next->va;node->next = node->next->next) {}
                        if(node->next != head){
                            node->before = node->next->before;
                            node->before->next = node;
                        }else{
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
    float countva = 0;//看方差最大值，如果低于80，直接跳过  todo
    count = 0;
    for(;;){
        count++;
        countva+=head->ang;
        if(head->next!=NULL) {
            head = head->next;
        } else {
            //            head == NULL; //alex changed
            head = NULL;
            break;
        }
    }
    int ang = (int)roundf(countva*=10)+2;
    *angle = (float)(ang-2)/100;
    Varivance *v =  varivances[ang];
    qsort(v, oldheight, sizeof(Varivance), cmpVariance);
    qsort(v, 24, sizeof(Varivance), cmpheight);
    
    int heights[24];
    count = 0;
    int peaks[24]={0};
    int peaknum = 0;
    for(int i = 0;i<24;i++){
        int h = v[i].height;
        if (count == 0) {
            heights[count++] = h;
        } else if (heights[count - 1] + 3 < h) {//todo
            peaks[peaknum++] = getMeans(heights, count);
            count = 1;
            heights[0] = h;
        } else {
            heights[count++] = h;
        }
    }
    if(count >1){
        peaks[peaknum++] = getMeans(heights, count);
    }
    //筛选peak
    for(int i = 0;i<peaknum-3;i++){
        if(checkInt(oldwidth,oldheight,blackimage,&(peaks[i]),*angle)){
            heightEdge[0] = peaks[i];
            heightEdge[1] = peaks[i+1];
            heightEdge[2] = peaks[i+2];
            heightEdge[3] = peaks[i+3];
            return true;
        }
    }
    return false;
}

static uc getpixelbyblackimage(uc blackimage[135][88],int x,int y){
    return (blackimage[y][x/8]>>(7-x%8))&1;
}

static bool generateLetterX(int up,int down,uc blackimage[135][88],float angle,int width,int height,int result[130],int* spaces){
    //    LOGE("%d",blackimage[83][13]);
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
            uc rgb = getpixelbyblackimage(blackimage, (i + (j * angle)), startY - j);
            if(rgb != 0){
                isWhite += 1;
                if (isWhite >= 2) {//willard
                    break;
                }
            }
        }
        if (isWhite > 1) {
            if (lastWhite != -1) {
                if (i - lastWhite == 1) {// 忽略字符中间的断裂
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
                // todo 优化i的值
                if(count!=0&&x12[count-1][0]+x12[count-1][1]>=i-2){
                    lastWhite = x12[count-1][0];
                    //                    lastWhite = fourInts.get(fourInts.size() - 1).a;
                    count--;
                }
            }
        }
    }
    if (lastWhite != -1) {
        x12[count][0] = lastWhite;
        x12[count++][1] = width+1-lastWhite;
        //        fourInts.add(new FourInt().setA(lastWhite).setB(blackImage.getWidth() + 1 - lastWhite));
    }
//    for(int i = 0;i<count;i++){
        //            cout<<(int)(x12[i][0])<<"__"<<(int)(x12[i][1])<<endl;
        //            LOGE("%d_%d",x12[i][0],x12[i][1]);
//    }
    //        LOGE("*******");
    if (count < 30) {
        //            cout<<"空格数小于30"<<endl;
        return false;
    }
    int resultcount  = 0;
    // result.add(fourInts.get(0).a == 0 ? fourInts.get(0).b - 1 + fourInts.get(0).a : -1);
    if(x12[0][0] == 0){
        result[resultcount++] = x12[0][1]-1;
        //        result.add(fourInts.get(0).b - 1 + fourInts.get(0).a);
    } else {
        result[resultcount++] = 0;
        result[resultcount++] = x12[0][0];
        if(result[1]-result[0]<4||result[1]-result[0]>(float)width/43){
            resultcount = 0;
        }
        result[resultcount++] = x12[0][1]+x12[0][0]-1;
    }
    int maxWidth =  width/ 43;
    for (int i = 1; i < count; i++) {
        //        if (fourInts.get(i).b > maxWidth) {
        if(x12[i][1]>maxWidth){
            if (resultcount > 60) {
                //                result.add(fourInts.get(i).a);
                result[resultcount++] = x12[i][0];
                break;
            }
            resultcount = 0;
            //            if (fourInts.size() - i + 1 < 30) {
            if(count-i+1<30){
                //                System.out.println("空格数小于43" + "........" + i);
                //                    cout<<"空格数小于30"<<endl;
                return false;
            }
            //            result.add(fourInts.get(i).a + fourInts.get(i).b - 1);
            result[resultcount++] = x12[i][0]+x12[i][1]-1;
        } else {
            //            if (fourInts.get(i).a - result.get(result.size() - 1) > (double) blackImage.getWidth() / 43d) {
            if(x12[i][0]-result[resultcount-1]>(float)width/43){
                //                System.out.println(fourInts.get(i).a - result.get(result.size() - 1));
                //                System.out.println((double) blackImage.getWidth() / 43d * 0.8);
                //                System.out.println("字符过长.........失败");
                return false;
            }
            result[resultcount++] = x12[i][0];
            if(i!=count-1){
                result[resultcount++] = x12[i][0]+x12[i][1]-1;
            }
        }
    }
//    for(int i = 0;i<resultcount;i++){
        //            cout<<result[i]<<endl;
        //            LOGE("%d",result[i]);
//    }
    if(resultcount < 88){
        //            printf("字符数不对 count = %d\n",resultcount);
        //            printf("白格数过少,最少88个, count = %d\n",resultcount);
        return false;
    }
    *spaces = resultcount;
    return true;
}

static int checkWhite(uc blackImage[135][88],int x1,int x2,int y){
    int count = 0;
    for (int i = 0; i < x2 - x1 + 1; i++) {
        // System.out.println(image.getWidth() + "****" + image.getHeight());
        // System.out.println((x1 + i) + "****" + y);
        //        if ((image.getPixel(x1 + i, y) & 0xff) < 127) {
        if(getpixelbyblackimage(blackImage, x1+i, y) != 0){
            count++;
            if (count > 3) {
                return count;
            }
        }
    }
    return count;
}

static void expandFourInt(int letteredge[4],uc blackImage[135][88],int width,int height){
    int flag = -1;
    while (flag != 0) {// flag = -1 向上扩张
        if (flag < 0) {
            //            if (checkWhite(blackImage, fourInt.a, fourInt.c, fourInt.b - 1) >= 2) {
            if (checkWhite(blackImage, letteredge[0], letteredge[2], letteredge[1] - 1) >= 2) {
                //                fourInt.b += flag;
                letteredge[1]+=flag;
                if (letteredge[1]== 0) {
                    flag = 0;
                }
            } else {
                flag = 1;
            }
        } else {// 向下扩张
            //            if (checkWhite(blackImage, fourInt.a, fourInt.c, fourInt.b) < 2) {
            if (checkWhite(blackImage, letteredge[0], letteredge[2], letteredge[1]) < 2) {
                //                fourInt.b += flag;
                letteredge[1] += flag;
                //                if (fourInt.b == blackImage.getHeight() - 1 || fourInt.b == fourInt.d - 3) {
                if (letteredge[1] == height - 1 || letteredge[1] == letteredge[3] - 3) {
                    flag = 0;
                }
            } else {
                flag = 0;
            }
        }
    }
    flag = 1;
    while (flag != 0) {// flag = 1 向下扩张
        if (flag > 0) {
            //            if (checkWhite(blackImage, fourInt.a, fourInt.c, fourInt.d + 1) >= 2) {
            if (checkWhite(blackImage, letteredge[0], letteredge[2], letteredge[3] + 1) >= 2) {
                //                fourInt.d += flag;
                letteredge[3]+= flag;
                //                if (fourInt.d == blackImage.getHeight() - 1) {
                if (letteredge[3] == height - 1) {
                    flag = 0;
                }
            } else {
                flag = -1;
            }
        } else {// 向下扩张
            //            if (checkWhite(blackImage, fourInt.a, fourInt.c, fourInt.d) < 2) {
            if (checkWhite(blackImage, letteredge[0], letteredge[2], letteredge[3]) < 2) {
                //                fourInt.d += flag;
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

static bool getlettersxy(int letters[88][4],int upLetterX[130],int downLetterX[130],int heightedge[4],uc blackImage[135][88],float angle,int width,int height,int upspaces,int downspaces){
    int count = 0;
    int leftX = -1;
    int diff;
    for (int i = 0; i < upspaces; i++) {
        if (leftX == -1) {
            leftX = upLetterX[i];
            continue;
        }
        //        FourInt fourInt = new FourInt().setA(leftX + 1).setB(heightEdge.a).setC(upLetterX.get(i) - 1).setD(heightEdge.b);
        diff = angle*(leftX+1);
        int letteredge[4] = {leftX+1,heightedge[0]+diff,upLetterX[i]-1,heightedge[1]+diff};
        expandFourInt(letteredge, blackImage,width,height);
        //        if (fourInt.d - fourInt.b + 1 > (heightEdge.b - heightEdge.a + 1) * 0.7 && fourInt.d - fourInt.b + 1 < (heightEdge.b - heightEdge.a + 1) * 1.25) {
        if(letteredge[3]-letteredge[1]+1>(heightedge[1]-heightedge[0]+1)*0.6&&letteredge[3]-letteredge[1]+1<(heightedge[1]-heightedge[0]+1)*1.35){//todo willard
            //            letters.add(fourInt);
            letters[count][0] = letteredge[0];
            letters[count][1] = letteredge[1];
            letters[count][2] = letteredge[2];
            letters[count++][3] = letteredge[3];
        }
        leftX = -1;
    }
    if(count != 44) return false;
    leftX = -1;
    for (int i = 0; i < downspaces; i++) {
        if (leftX == -1) {
            leftX = downLetterX[i];
            continue;
        }
        //        FourInt fourInt = new FourInt().setA(leftX + 1).setB(heightEdge.c).setC(downLetterX.get(i) - 1).setD(heightEdge.d);
        diff = angle*(leftX+1);
        int letteredge[4] = {leftX+1,heightedge[2]+diff,downLetterX[i]-1,heightedge[3]+diff};
        expandFourInt(letteredge, blackImage,width,height);
        //        if (fourInt.d - fourInt.b + 1 > (heightEdge.d - heightEdge.c + 1) * 0.8 && fourInt.d - fourInt.b + 1 < (heightEdge.d - heightEdge.c + 1) * 1.15) {
        if(letteredge[3]-letteredge[1]+1>(heightedge[3]-heightedge[2]+1)*0.6&&letteredge[3]-letteredge[1]+1<(heightedge[3]-heightedge[2]+1)*1.35){//todo willard
            //            letters.add(fourInt);
            letters[count][0] = letteredge[0];
            letters[count][1] = letteredge[1];
            letters[count][2] = letteredge[2];
            letters[count++][3] = letteredge[3];
        }
        leftX = -1;
    }
    if(count != 88) return false;
    return true;
}

static char getcharbyint(int maxI){
    if (maxI < 10) {
        char a = 48+maxI;
        return a;
    } else if (maxI == 31) {
        return '<';
    }
    return (char) (55 + maxI);
}

static bool debugable = false;

static void ocr(uc letterimage[88][25],char* result,int* iaa){
    int min = 0xfffff;
    int answer = 0;
    for(int m = 0;m<88;m++){
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
        result[m] = getcharbyint(answer);
        if(debugable) iaa[m] = answer;
    }
}

static void dividechar(uc blackimage[135][88],int lettersxy[88][4],uc letterimage[88][25]){
    int width,height;
    for(int i = 0;i<88;i++){
        width = lettersxy[i][2]-lettersxy[i][0]+1;
        height = lettersxy[i][3]-lettersxy[i][1]+1;
        uc image[131][700] = {0};
        for(int j = 0;j<height;j++){
            for(int k = 0;k<width;k++){
                //                image[j][k] = getpixelbyblackimage(blackimage, k, j);
                char a =getpixelbyblackimage(blackimage, k+lettersxy[i][0], j+lettersxy[i][1]);
                //                *(image+j*width+k) = a;
                image[j][k] = a;
            }
        }
        float pixelwidth = (float)width/13;
        float pixelheight = (float)height/15;
        int flag = 0;
        int count = 0;
//        uc newblackimage[15][13] = {0};
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
                        //                        color+=d*dd*(*(image+m*width+n));
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
//                    newblackimage[j][k] = 1;
                }else{
                    letterimage[i][flag] = (letterimage[i][flag]<<1)+0;
                    count++;
                    if(count == 8){
                        flag++;
                        count = 0;
                    }
//                    newblackimage[j][k] = 0;
                }
            }
        }
    }
}

static void generateGrayImage(int8_t* arr,uc grayimage[135][700],int hw,int hh,int x,int y,int w,int h){
    float pixelwidth = (float)w/700;
    float pixelheight = (float)h/131;
    for(int j = 0;j<131;j++){
        for(int k = 0;k<700;k++){
            float startx = x+k*pixelwidth;
            float starty = y+j*pixelheight;
            float endx = startx+pixelwidth;
            float endy = starty+pixelheight;
            float color = 0;
            for(int m = (int) starty;m<=(int)endy;m++){
                if(m == y+h){
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
                    if(n == x+w){
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
                    color+=d*dd*((int)(*(arr+m*hw+n))&0xff);
                }
            }
            //            if(color/((endy-starty)*(endx-startx))>=0.5){
            grayimage[j][k] = roundf(color/((endy-starty)*(endx-startx)));
        }
    }
    //    int32_t* tmpArray;
    //    tmpArray = (int32_t*)malloc(131 * 700 * sizeof(int32_t));
    //    for(int i = 0;i<131;i++){
    //        for (int j = 0; j < 700; j++) {
    //            tmpArray[i * 700 + j] =grayimage[i][j];
    //        }
    //    }
    //    saveBitmap(tmpArray);
    ////    free(graytmp);
}

char* LibScanPassport_scanByte(int8_t *arr,int hw,int hh,int x,int y,int w,int h){
    int level = 0;
    uc letterimage[88][25]={0};//88 leters 13width 15 height;
    char *resultstring;
    uc grayimage[135][700]={0};
    uc blackimage[135][88]={0};//135*700/8
    int width = 700;
    int height = 131;
    float angle = 0;
    int heightEdge[4]={0};
    generateGrayImage(arr,grayimage,hw,hh,x,y,w,h);
    blackImage(width,height,grayimage,blackimage);
    char result[89] = {0};
    int upletterX[130] = {0};
    int downletterX[130] = {0};
    int lettersxy[88][4] = {0};
    int upwhitespaces = 0;
    int downwhitespaces = 0;
    if(!getHeightEdge(width,height,blackimage,&angle,(int*) heightEdge)){
        goto A;
    }
    level++;
    if(generateLetterX(heightEdge[0],heightEdge[1],blackimage,angle,width,height,upletterX,&upwhitespaces)&&generateLetterX(heightEdge[2],heightEdge[3],blackimage,angle,width,height,downletterX,&downwhitespaces)){
        level++;
        if(getlettersxy(lettersxy,upletterX,downletterX,heightEdge,blackimage,angle,width,height,upwhitespaces,downwhitespaces)){
            level++;
            dividechar(blackimage,lettersxy,letterimage);
            ocr(letterimage, result,NULL);
        }
    }
A:  if(result[0] == 0){
    char le = '0'+level;
    result[0] = le;
    result[1] = 0;
}
else {
    int *letterPos;
    letterPos = (int *)malloc(88 * 4 * sizeof(int));
    for (int i = 0; i < 88; i++) {
        for (int j = 0; j < 4; j++) {
            letterPos[4 * i + j] = lettersxy[i][j];
        }
    }
    saveLetterPos(letterPos);
}
    
    resultstring = &result[0];
    return resultstring;
}

char* LibScanPassport_test(int8_t *arr, int hw, int hh, int x, int y, int w, int h){
    if(!debugable) return NULL;
    uc letterimage[88][25]={0};//88 leeters 13width 15 height;
    uc grayimage[135][700]={0};
    uc blackimage[135][88]={0};//135*700/8
    char *resultstring;
    int width = 700;
    int height = 131;
    float angle = 0;
    int heightEdge[4]={0};
    generateGrayImage(arr,grayimage,hw,hh,x,y,w,h);
    timeval start,end,blacktime,heightedgetime,dividetime;
    gettimeofday(&start, NULL);
    blackImage(width,height,grayimage,blackimage);
    gettimeofday(&blacktime,NULL);
    char result[89] = {0};
    int upletterX[130] = {0};
    int downletterX[130] = {0};
    int lettersxy[88][4] = {0};
    int upwhitespaces = 0;
    int downwhitespaces = 0;
    if(!getHeightEdge(width,height,blackimage,&angle,(int*) heightEdge)){
        gettimeofday(&heightedgetime,NULL);
        printf("寻找上下边框失败");
        goto A;
    }
    printf("%d %d %d %d",heightEdge[0],heightEdge[1],heightEdge[2],heightEdge[3]);
    if(generateLetterX(heightEdge[0],heightEdge[1],blackimage,angle,width,height,upletterX,&upwhitespaces)&&generateLetterX(heightEdge[2],heightEdge[3],blackimage,angle,width,height,downletterX,&downwhitespaces)){
        if(getlettersxy(lettersxy,upletterX,downletterX,heightEdge,blackimage,angle,width,height,upwhitespaces,downwhitespaces)){
            dividechar(blackimage,lettersxy,letterimage);
            gettimeofday(&dividetime,NULL);
            int iaa[88] = {0};
            ocr(letterimage, result,iaa);
            if(debugable){
                int32_t* jjarray;
                jjarray = (int32_t*)malloc(2288 * sizeof(int32_t));
                int bbb[2288];
                for(int i = 0;i<2200;i++){
                    bbb[i] = (int) letterimage[i/25][i%25]&0xff;
                }
                for(int i = 2200;i<2288;i++) bbb[i] = iaa[i-2200];
                memcpy(jjarray, bbb, 2288 * sizeof(int32_t));
                //                saveSmallBitmap(jjarray);
                free(jjarray);
            }
            printf("%s",result);
            printf("第%d 次 识别",times);
        }
    }
A:  if(result[0] == 0){
    strcat(result,"8");
}
else {
    int *letterPos;
    letterPos = (int *)malloc(88 * 4 * sizeof(int));
    for (int i = 0; i < 88; i++) {
        for (int j = 0; j < 4; j++) {
            letterPos[4 * i + j] = lettersxy[i][j];
        }
    }
    saveLetterPos(letterPos);
}
    gettimeofday(&end, NULL);
    printf("%ld",start.tv_sec);
    printf("%ld",end.tv_sec);
    printf("共花费%d 毫秒,二值化耗时 %d 毫秒，寻找两行字耗时%d毫秒，分割字符耗时%d毫秒，ocr耗时%d毫秒",(end.tv_usec-start.tv_usec)/1000,(blacktime.tv_usec-start.tv_usec)/1000,(heightedgetime.tv_usec-blacktime.tv_usec)/1000,(dividetime.tv_usec-heightedgetime.tv_usec)/1000,(end.tv_usec-dividetime.tv_usec)/1000);
    times++;
    
    resultstring = &result[0];
    return resultstring;
}

