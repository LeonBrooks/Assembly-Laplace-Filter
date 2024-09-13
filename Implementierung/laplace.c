#define _CRT_SECURE_NO_WARNINGS
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <malloc.h>
#include <time.h>
#include <unistd.h>

extern void laplace(unsigned char*bild,int width,int height);
extern void simd(unsigned char* bild, int width, int height);

//struct for reading/writing bmp file header
#pragma pack(push, 1)
typedef struct tagBITMAPFILEHEADER
{
	short bfType; // 0-1
	int bfSize;  // 2-5
	short bfReserved1;  // 6-7
	short bfReserved2;  // 8-9
	int bfOffBits;  // 10-13
} BITMAPFILEHEADER;
#pragma pack(pop)

//struct for reading/writing bmp info header
#pragma pack(push, 1)
typedef struct tagBITMAPINFOHEADER
{
	int biSize;  // 14-17
	int biWidth;  // 18-21
	int biHeight;  // 22-25
	short biPlanes;  // 26-27
	short biBitCount;  // 28-29
	int biCompression;  // 30-33
	int biSizeImage;  // 34-37
	int biXPelsPerMeter;  // 38-41
	int biYPelsPerMeter;  // 42-45
	int biClrUsed;  // 46-49
	int biClrImportant; // 50-53
}BITMAPINFOHEADER;
#pragma pack(pop)

//helper Method for measuring time
static inline double getTime(){
	struct timespec t;
	clock_gettime(CLOCK_MONOTONIC, &t);
	return t.tv_sec + t.tv_nsec * 1e-9;
}

//requires path to bmp as argument, optional second argument -b for benchmark mode. If used in benchmark mode third argument is required, defining the iterations to be executed. Uses simd by default;
int main(int argc, char** argv)
{
	int bench = 0;	//benchmark iterations
	FILE *bmp;	//input

	BITMAPFILEHEADER header;
	BITMAPINFOHEADER info;

	//checking for -h/--help. If given provides the help output.
	if(argc >= 2){
		if(strcmp(argv[1], "-h") == 0 || strcmp(argv[1], "--help") == 0){
			printf("---------------------------------------------- HELP ---------------------------------------------\n");
			printf("This progragm accepts an image as input applies the Laplace-Filter and stores the result in out.bmp\n");
			printf("Optionally this program can be run in benchmark mode where it accepts a positive integer of\n");
			printf("iterations it will perform with a standard assembly implementation and a simd-optimized version of\n");
			printf("the Laplace-Filter and write the results to the console.\n\n");

			printf("use Format: ./laplace path {-b iterations} \n\n");

			printf("input:\n");
			printf("path:        path to the input bmp file   eg.: lena.bmp\n");
			printf("-b:          flag for usage in benchmark mode\n");
			printf("iterations:  positive number of iterations to be used in the benchmark mode   eg.: 100\n\n");
			
			printf("output: out.bmp\n");
			printf("-------------------------------------------------------------------------------------------------\n");
			return -1;
		}
	}
	
	//opening bmp file
	if (argc < 2 || (bmp = fopen(argv[1], "rb")) == NULL) {
		printf("BMP doesn't exist. Use -h or --help for help.\n");
		return -1;
	}

	//checking command line arguments
	if(argc >= 3){
		if(strcmp(argv[2], "-b") == 0){
			if(argc >= 4)
{
				char *temp;
				bench = strtol(argv[3], &temp, 10);
				if(bench < 1){
					printf("Third argument must be a number of iterations (> 0)! Use -h or --help for help\n");
					return -1;
				}
				printf("Benchmark mode activated with %d iterations!\n", bench);	
			} else{
				printf("For benchmark mode third argument: number of iterations is required! Use -h or --help for help.\n");
				return -1;
			}
		} else{
			printf("Unknown second argument. Use -b for benchmark mode. Use -h or --help for help.\n");
			return -1;
		}
	}
	
	//extracting headers
	fread(&header, sizeof(BITMAPFILEHEADER), 1, bmp);
	fread(&info, sizeof(BITMAPINFOHEADER), 1, bmp);
	fseek(bmp, header.bfOffBits, SEEK_SET);

	//reading image data and allocating required memory
	unsigned char* pixel;
	pixel=(unsigned char*)malloc(info.biSizeImage*2);
	if(pixel == 0){
		printf("Picture to large. Malloc returned 0\n");
		fclose(bmp);
		return -1;
	}
	fread(pixel, info.biSizeImage, 1, bmp);

	unsigned char* allheaders;
	allheaders = (unsigned char*) malloc(header.bfOffBits - 1);
	fseek(bmp, 0, SEEK_SET);
	fread(allheaders, header.bfOffBits-1, 1, bmp);


	printf("width: %d;height: %d\n", info.biWidth, info.biHeight);
	printf("size: %d bytes\n", info.biSizeImage);

	//executing benchmark or simd implementation by default
	if(bench != 0){
		printf("Executing benchmark ...\n");
		double res, sres, start, end;
		
		start = getTime();
		for(int i=0; i<bench; i++){
			laplace(pixel,info.biWidth,info.biHeight);
		}
		end = getTime();
		res = end - start;


		start = getTime();
		for(int i=0; i<bench; i++){
			simd(pixel, info.biWidth, info.biHeight);
		}
		end = getTime();
		sres = end - start;

		printf("%d iterations:\n", bench);
		printf("standard assembly took: %f seconds\n", res);
		printf("simd assembly took: %f seconds\n", sres);

	} else{
		simd(pixel, info.biWidth, info.biHeight);
	}
	
	//writing result into output file
	FILE* bout;
	if ((bout = fopen("out.bmp", "w")) == NULL) {
		printf("BMP doesn't exist\n");
		return -1;
	}
	fwrite(allheaders, header.bfOffBits, 1, bout);
	fwrite((pixel + info.biSizeImage), info.biSizeImage, 1, bout);
	fclose(bmp);
	fclose(bout);
}

