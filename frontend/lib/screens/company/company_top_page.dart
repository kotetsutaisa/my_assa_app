import 'package:flutter/material.dart';

class CompanyTopPage extends StatelessWidget {
  const CompanyTopPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context), // ← 前の画面に戻る
        ),
        title: Text(
          'Fj',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Text(
              '会社グループに参加する方はこちら',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          SizedBox(height: 30),

          Center(
            child: SizedBox(
              width: 280,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/company/add');
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Color.fromRGBO(39, 39, 39, 1),
                  shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                  ),
                ),
                child: Text(
                  '会社グループに参加する',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 150),

          Center(
            child: Text(
              '新規会社グループを作成する方はこちら',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          SizedBox(height: 30),

          Center(
            child: SizedBox(
              width: 280,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/company/create');
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Color.fromRGBO(39, 39, 39, 1),
                  shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                  ),
                ),
                child: Text(
                  '会社グループを作成する',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
