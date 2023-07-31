#include <jni.h>
#include <string>

#include<iostream>
#include <vector>
#include<opencv2/opencv.hpp>
#include <opencv2/imgproc/types_c.h>
//#include <opencv2/highgui/highgui.hpp>
//#include <opencv2/core/core.hpp>
//#include <opencv2/imgproc/imgproc.hpp>
#include <unistd.h>
#include <android/bitmap.h>

#include <android/log.h>
#define TAG "NATIVE" // 这个是自定义的LOG的标识
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG,TAG ,__VA_ARGS__) // 定义LOGD类型
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO,TAG ,__VA_ARGS__) // 定义LOGI类型
#define LOGW(...) __android_log_print(ANDROID_LOG_WARN,TAG ,__VA_ARGS__) // 定义LOGW类型
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR,TAG ,__VA_ARGS__) // 定义LOGE类型
#define LOGF(...) __android_log_print(ANDROID_LOG_FATAL,TAG ,__VA_ARGS__) // 定义LOGF类型
//char * name = "mronion";
//LOGD("my name is %s\n", name );

using namespace cv;
using namespace std;

const bool DEBUG_NATIVE = true;


#define ATTRIBUTES extern "C" __attribute__((visibility("default"))) __attribute__((used))


// opencv version
ATTRIBUTES char * opencv_version() {
    char * ver = CV_VERSION;
    if (DEBUG_NATIVE) {
        LOGD("opencv_version()  resulting version:%s\n", ver );
        //__android_log_print(ANDROID_LOG_VERBOSE, "NATIVE", "opencv_version()  resulting version %s\n", CV_VERSION);
    }
    return ver;
}

// decode 图片
ATTRIBUTES Mat *opencv_decodeImage(
        unsigned char *img,
        int32_t *imgLengthBytes) {

    Mat *src = new Mat();
    std::vector<unsigned char> m;

    __android_log_print(ANDROID_LOG_VERBOSE, "NATIVE",
                        "opencv_decodeImage() ---  start imgLengthBytes:%d ",
                        *imgLengthBytes);

    for (int32_t a = *imgLengthBytes; a >= 0; a--) m.push_back(*(img++));

    *src = imdecode(m, cv::IMREAD_COLOR);
    if (src->data == nullptr)
        return nullptr;

    if (DEBUG_NATIVE)
        __android_log_print(ANDROID_LOG_VERBOSE, "NATIVE",
                            "opencv_decodeImage() ---  len before:%d  len after:%d  width:%d  height:%d",
                            *imgLengthBytes, src->step[0] * src->rows,
                            src->cols, src->rows);

    *imgLengthBytes = src->step[0] * src->rows;
    return src;
}


//高斯模糊
ATTRIBUTES unsigned char *opencv_blur(
        uint8_t *imgMat,
        int32_t *imgLengthBytes,
        int32_t kernelSize) {
    // 1. decode 图片
    Mat *src = opencv_decodeImage(imgMat, imgLengthBytes);
    if (src == nullptr || src->data == nullptr)
        return nullptr;
    if (DEBUG_NATIVE) {
        __android_log_print(ANDROID_LOG_VERBOSE, "NATIVE",
                            "opencv_blur() ---  width:%d   height:%d",
                            src->cols, src->rows);

        __android_log_print(ANDROID_LOG_VERBOSE, "NATIVE",
                            "opencv_blur() ---  len:%d ",
                            src->step[0] * src->rows);
    }

    // 2. 高斯模糊
    //GaussianBlur(*src, *src, Size(151, 151), 151, 0, 4);
    GaussianBlur(*src, *src, Size(kernelSize, kernelSize), 15, 0, 4);
    std::vector<uchar> buf(1); // imencode() will resize it
//    Encoding with b       mp : 20-40ms
//    Encoding with jpg : 50-70 ms
//    Encoding with png: 200-250ms
    // 3. encode 图片
    imencode(".png", *src, buf);

    if (DEBUG_NATIVE) {
        __android_log_print(ANDROID_LOG_VERBOSE, "NATIVE",
                            "opencv_blur()  resulting image  length:%d %d x %d", buf.size(),
                            src->cols, src->rows);
    }

    *imgLengthBytes = buf.size();

    // the return value may be freed by GC before dart receive it??
    // Sometimes in Dart, ImgProc.computeSync() receives all zeros while here buf.data() is filled correctly
    // Returning a new allocated memory.
    // Note: remember to free() the Pointer<> in Dart!

    // 3. 返回data
    return buf.data();
}


// 灰度值
ATTRIBUTES unsigned char *opencv_gray(
        uint8_t *imgMat,
        int32_t *imgLengthBytes,
        int32_t kernelSize) {
    // 1. decode 图片
    Mat *src = opencv_decodeImage(imgMat, imgLengthBytes);
    if (src == nullptr || src->data == nullptr)
        return nullptr;
    if (DEBUG_NATIVE) {
        __android_log_print(ANDROID_LOG_VERBOSE, "NATIVE",
                            "opencv_gray() ---  width:%d   height:%d",
                            src->cols, src->rows);

        __android_log_print(ANDROID_LOG_VERBOSE, "NATIVE",
                            "opencv_gray() ---  len:%d ",
                            src->step[0] * src->rows);
    }

    // 2. 灰度值
    cvtColor(*src, *src, CV_BGRA2GRAY);
    cvtColor(*src, *src, CV_GRAY2BGRA);

    std::vector<uchar> buf(1); // imencode() will resize it
//    Encoding with b       mp : 20-40ms
//    Encoding with jpg : 50-70 ms
//    Encoding with png: 200-250ms
    // 3. encode 图片
    imencode(".png", *src, buf);

    if (DEBUG_NATIVE) {
        __android_log_print(ANDROID_LOG_VERBOSE, "NATIVE",
                            "opencv_gray()  resulting image  length:%d %d x %d", buf.size(),
                            src->cols, src->rows);
    }

    *imgLengthBytes = buf.size();

    // the return value may be freed by GC before dart receive it??
    // Sometimes in Dart, ImgProc.computeSync() receives all zeros while here buf.data() is filled correctly
    // Returning a new allocated memory.
    // Note: remember to free() the Pointer<> in Dart!

    // 3. 返回data
    return buf.data();
}


// 二值化
ATTRIBUTES unsigned char *opencv_threshold(
        uint8_t *imgMat,
        int32_t *imgLengthBytes,
        int32_t kernelSize) {
    // 1. decode 图片
    Mat *src = opencv_decodeImage(imgMat, imgLengthBytes);
    if (src == nullptr || src->data == nullptr)
        return nullptr;
    if (DEBUG_NATIVE) {
        __android_log_print(ANDROID_LOG_VERBOSE, "NATIVE",
                            "opencv_threshold() ---  width:%d   height:%d",
                            src->cols, src->rows);

        __android_log_print(ANDROID_LOG_VERBOSE, "NATIVE",
                            "opencv_threshold() ---  len:%d ",
                            src->step[0] * src->rows);
    }

    // 2. 进行二值化处理，选择30，200.0为阈值
    //threshold(*src, *src, 30, 200.0, CV_THRESH_BINARY);
    threshold(*src, *src, 30, kernelSize, CV_THRESH_BINARY);

    std::vector<uchar> buf(1); // imencode() will resize it
//    Encoding with b       mp : 20-40ms
//    Encoding with jpg : 50-70 ms
//    Encoding with png: 200-250ms
    // 3. encode 图片
    imencode(".png", *src, buf);

    if (DEBUG_NATIVE) {
        __android_log_print(ANDROID_LOG_VERBOSE, "NATIVE",
                            "opencv_threshold()  resulting image  length:%d %d x %d", buf.size(),
                            src->cols, src->rows);
    }

    *imgLengthBytes = buf.size();

    // the return value may be freed by GC before dart receive it??
    // Sometimes in Dart, ImgProc.computeSync() receives all zeros while here buf.data() is filled correctly
    // Returning a new allocated memory.
    // Note: remember to free() the Pointer<> in Dart!

    // 3. 返回data
    return buf.data();
}

