import 'package:flutter/material.dart';

final ThemeData appTheme = ThemeData(

    useMaterial3: false,

    // メインカラー
    primaryColor: Color.fromRGBO(20, 20, 20, 1),

    // バックグラウンドカラー
    scaffoldBackgroundColor: Colors.white,

    colorScheme: ColorScheme.light(
      // メインカラー
      primary: Color.fromRGBO(20, 20, 20, 1),
      // サブカラー
      secondary: Color.fromRGBO(74, 74, 74, 1),
      // サブ背景
      surface: Color.fromRGBO(235, 235, 235, 1),
      // ボーダーカラー
      outline: Color.fromRGBO(237, 237, 237, 1),
    ),

    //　フォントの指定
    fontFamily: 'NotoSansJP',

    // 文字の大きさを指定
    textTheme: TextTheme(
        // 標準サイズ
        bodyLarge: TextStyle(
            fontSize: 16,
            color:Color.fromRGBO(20, 20, 20, 1),
        ),

        // ヘッダーの文字サイズ
        headlineLarge: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color.fromRGBO(20, 20, 20, 1),
        ),

        // タイトルの文字サイズ
        titleLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color.fromRGBO(20, 20, 20, 1),
        ),

        // 少し小さめの本文
        bodyMedium: TextStyle(
            fontSize: 12,
            color: Color.fromRGBO(20, 20, 20, 1),
        ),

        // 小さい文字
        bodySmall: TextStyle(
            fontSize: 10,
            color: Color.fromRGBO(20, 20, 20, 1),
        ),

    ),

    // AppBar のスタイル
    appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color.fromRGBO(39, 39, 39, 1),
        elevation: 0, // 影を消す
        centerTitle: true, // タイトル中央
    ),

    // インプットのスタイル(まだ未定義)
    inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
                color: Color.fromRGBO(224, 224, 224, 1),
                width: 2.0,
            )
        ),

        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
                color: Color.fromRGBO(20, 20, 20, 1), // フォーカス時の色！
                width: 2.0,
            ),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: TextStyle(
            fontSize: 14,
            color: Color.fromRGBO(100, 100, 100, 1),
        ),
    ),


    elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        textStyle: TextStyle(fontWeight: FontWeight.bold),
        ),
    ),

  // ボトムタブバー
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Color.fromRGBO(255, 255, 255, 1),
    selectedItemColor: Color.fromRGBO(20, 20, 20, 1), // 選択中のラベル色
    unselectedItemColor: Color.fromRGBO(20, 20, 20, 1), // 未選択ラベル色
    selectedLabelStyle: TextStyle(fontSize: 8),
    unselectedLabelStyle: TextStyle(fontSize: 8),
    showSelectedLabels: true,
    showUnselectedLabels: true,
  ),
);
