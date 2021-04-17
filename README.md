## A simple Flutter app to let you take pictures and label them

Very first mobile application I ever wrote. Turned out to be slightly bigger than 'Hello World' app. There is no magic, no machine learning. Simple app which

1. Lets you take pictures with phone's camera
2. Lets you create, edit labels (uses Sqlite)
3. Lets you label the pictures with appropriate label
4. Lets you export all pictures
5. Supports English and German
6. Shows some logs and stats

### Sample Data

When you run the app for the very first time it populates some sample data comprising of 6 images and 2 class labels.

### Localization

It supports English and German. For all other device locales it falls back to "en_US". It honors device's locale when it starts up. You can change the locale through the app. Reflecting change in device's locale while the app is running is ignored. I have used a package called 'devicelocale' to get device locale even before MaterialApp and so 'context' is available. During project build, this package does throw a warning <b>DevicelocalePlugin.java uses or overrides a deprecated API.</b>

### Screenshots

Here are a few screenshots

| Startup Screen | Take a picture screen |
| :-: | :-: |
| ![alt text](https://github.com/yogimogi/yoimagelabeler/raw/master/docs/image1.jpg) | ![alt text](https://github.com/yogimogi/yoimagelabeler/raw/master/docs/image2.jpg) |

| Label picture screen (add mode) | Label picture screen (edit mode) |
| :-: | :-: |
| ![alt text](https://github.com/yogimogi/yoimagelabeler/raw/master/docs/image3.jpg) | ![alt text](https://github.com/yogimogi/yoimagelabeler/raw/master/docs/image4.jpg) |

| Menu | Manage labels screen |
| :-: | :-: |
| ![alt text](https://github.com/yogimogi/yoimagelabeler/raw/master/docs/image5.jpg) | ![alt text](https://github.com/yogimogi/yoimagelabeler/raw/master/docs/image6.jpg) |

| Stats screen | Change Locale Dialog launched from language icon on startup screen |
| :-: | :-: |
| ![alt text](https://github.com/yogimogi/yoimagelabeler/raw/master/docs/image7.jpg) | ![alt text](https://github.com/yogimogi/yoimagelabeler/raw/master/docs/image8.jpg) |

### Few other notes

1. Have been tried only with Android devices
2. All the data stored by the app is inside the directory '/storage/emulated/0/Android/data/com.yogimogi.yo_image_labeler/files'. This path is returned by the API getExternalStorageDirectory().
