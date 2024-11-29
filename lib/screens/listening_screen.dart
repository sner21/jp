class ListeningScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('听力练习')),
      body: ListView(
        children: [
          ListeningExerciseCard(
            title: '单词听写',
            description: '听音选择正确的单词',
            onTap: () => Navigator.pushNamed(context, '/listening/dictation'),
          ),
          ListeningExerciseCard(
            title: '句子听力',
            description: '听句子选择正确的含义',
            onTap: () => Navigator.pushNamed(context, '/listening/sentences'),
          ),
        ],
      ),
    );
  }
} 