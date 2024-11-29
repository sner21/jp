class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('日语学习')),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        children: [
          MenuCard(
            title: '单词学习',
            icon: Icons.book,
            onTap: () => Navigator.pushNamed(context, '/vocabulary'),
          ),
          MenuCard(
            title: '听力练习',
            icon: Icons.headphones,
            onTap: () => Navigator.pushNamed(context, '/listening'),
          ),
          MenuCard(
            title: '复习计划',
            icon: Icons.calendar_today,
            onTap: () => Navigator.pushNamed(context, '/review'),
          ),
          MenuCard(
            title: '学习统计',
            icon: Icons.bar_chart,
            onTap: () => Navigator.pushNamed(context, '/statistics'),
          ),
        ],
      ),
    );
  }
} 