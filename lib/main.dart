import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  final _picker = ImagePicker();

  String? _opencvVersion;
  Uint8List? _srcImageBytes;
  Uint8List? _dstImageBytes;


  initData() async{
    /// 读取图片，转换成 Uint8List
    final bytes = await rootBundle.load('assets/imgs/1.jpg');
    _srcImageBytes = bytes.buffer.asUint8List();
    _opencvVersion = await version();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    initData();
  }



  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("opencv ${_opencvVersion}"),
      ),
      body: SingleChildScrollView(

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              child: Row(
                children: [
                  ElevatedButton(onPressed: () async {
                    final tmp  = await threshold(_srcImageBytes!);
                    if(tmp !=null){
                      _dstImageBytes = tmp;
                    }
                    setState(() {

                    });
                  }, child: Text("二值化")),
                  ElevatedButton(onPressed: () async {
                    final tmp  = await gray(_srcImageBytes!);
                    if(tmp !=null){
                      _dstImageBytes = tmp;
                    }
                    setState(() {

                    });
                  }, child: Text("灰度化")),
                  ElevatedButton(onPressed: () async {
                    final tmp  = await blur(_srcImageBytes!);
                    if(tmp !=null){
                      _dstImageBytes = tmp;
                    }
                    setState(() {

                    });
                  }, child: Text("高斯模糊")),
                ],
              ),
            ),


            Container(
              //height: 250,
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        await _pickImageFromGallery();
                      },
                      child:  Container(
                        height: 200,
                        child:
                        _srcImageBytes!=null? Image.memory(_srcImageBytes!):Container(),
                      )
                    ),

                    SizedBox(width: 20,),

                    (_dstImageBytes != null) ?
                    Container(
                        height: 200,
                        child:
                        Image.memory(_dstImageBytes!)
                    )
                    :Container(),


                  ],
                )
            ),


          ],
        ),
      ),
    );
  }


  ///
  /// 从相册选择图片
  ///
  Future<void> _pickImageFromGallery() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      //setState(() => this._imageFile = File(pickedFile.path));
      File _file = File(pickedFile.path);
      //_srcImg = Image.file(_file!);
      //_dstImg = Image.file(_file!);
      _srcImageBytes = _file.readAsBytesSync();

      setState(() {});
    }
  }


}


///version
Future<String?> version() async{

  // 查找 C++ 中的 opencv_blur() 函数
  final DynamicLibrary _opencvLib =
  Platform.isAndroid ? DynamicLibrary.open("libnative-lib.so") : DynamicLibrary.process();
  final Pointer<Int8> Function() opencv_version =
  _opencvLib
      .lookup<
      NativeFunction<
          Pointer<Int8> Function()>>("opencv_version")
      .asFunction();

  Pointer<Int8> _version = opencv_version();
  final ret =  _version.cast<Utf8>().toDartString();
  print("open ver:$ret");

  return ret;
}


/// 高斯模糊
Future<Uint8List?> blur(Uint8List list) async {
  /// 深拷贝图片
  Pointer<Uint8> bytes = malloc.allocate<Uint8>(list.length);
  for (int i = 0; i < list.length; i++) {
    bytes.elementAt(i).value = list[i];
  }
  // 为图片长度分配内存
  final imgLengthBytes = malloc.allocate<Int32>(1)..value = list.length;

  // 查找 C++ 中的 opencv_blur() 函数
  final DynamicLibrary _opencvLib =
  Platform.isAndroid ? DynamicLibrary.open("libnative-lib.so") : DynamicLibrary.process();
  final Pointer<Uint8> Function(
      Pointer<Uint8> bytes, Pointer<Int32> imgLengthBytes, int kernelSize) blur =
  _opencvLib
      .lookup<
      NativeFunction<
          Pointer<Uint8> Function(Pointer<Uint8> bytes, Pointer<Int32> imgLengthBytes,
              Int32 kernelSize)>>("opencv_blur")
      .asFunction();

  /// 调用高斯模糊
  final newBytes = blur(bytes, imgLengthBytes, 251);
  if (newBytes == nullptr) {
    print('高斯模糊失败');
    return null;
  }

  var newList = newBytes.asTypedList(imgLengthBytes.value);

  /// 释放指针
  malloc.free(bytes);
  malloc.free(imgLengthBytes);
  return newList;
}






/// 灰度值
Future<Uint8List?> gray(Uint8List list) async {
  /// 深拷贝图片
  Pointer<Uint8> bytes = malloc.allocate<Uint8>(list.length);
  for (int i = 0; i < list.length; i++) {
    bytes.elementAt(i).value = list[i];
  }
  // 为图片长度分配内存
  final imgLengthBytes = malloc.allocate<Int32>(1)..value = list.length;

  // 查找 C++ 中的 opencv_blur() 函数
  final DynamicLibrary _opencvLib =
  Platform.isAndroid ? DynamicLibrary.open("libnative-lib.so") : DynamicLibrary.process();
  final Pointer<Uint8> Function(
      Pointer<Uint8> bytes, Pointer<Int32> imgLengthBytes, int kernelSize) opencv_gray =
  _opencvLib
      .lookup<
      NativeFunction<
          Pointer<Uint8> Function(Pointer<Uint8> bytes, Pointer<Int32> imgLengthBytes,
              Int32 kernelSize)>>("opencv_gray")
      .asFunction();

  /// 调用灰度值
  final newBytes = opencv_gray(bytes, imgLengthBytes, 251);
  if (newBytes == nullptr) {
    print('灰度值失败');
    return null;
  }

  var newList = newBytes.asTypedList(imgLengthBytes.value);

  /// 释放指针
  malloc.free(bytes);
  malloc.free(imgLengthBytes);
  return newList;
}


/// 二值化
Future<Uint8List?> threshold(Uint8List list) async {
  /// 深拷贝图片
  Pointer<Uint8> bytes = malloc.allocate<Uint8>(list.length);
  for (int i = 0; i < list.length; i++) {
    bytes.elementAt(i).value = list[i];
  }
  // 为图片长度分配内存
  final imgLengthBytes = malloc.allocate<Int32>(1)..value = list.length;

  // 查找 C++ 中的 opencv_blur() 函数
  final DynamicLibrary _opencvLib =
  Platform.isAndroid ? DynamicLibrary.open("libnative-lib.so") : DynamicLibrary.process();
  final Pointer<Uint8> Function(
      Pointer<Uint8> bytes, Pointer<Int32> imgLengthBytes, int kernelSize) opencv_threshold =
  _opencvLib
      .lookup<
      NativeFunction<
          Pointer<Uint8> Function(Pointer<Uint8> bytes, Pointer<Int32> imgLengthBytes,
              Int32 kernelSize)>>("opencv_threshold")
      .asFunction();

  /// 调用二值化
  final newBytes = opencv_threshold(bytes, imgLengthBytes, 251);
  if (newBytes == nullptr) {
    print('二值化失败');
    return null;
  }

  var newList = newBytes.asTypedList(imgLengthBytes.value);
  print("zzz");

  /// 释放指针
  malloc.free(bytes);
  malloc.free(imgLengthBytes);
  return newList;
}