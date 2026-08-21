import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('로그인')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 48),
            Text(
              '다시 만나 반가워요',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 32),
            const TextField(
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: '이메일'),
            ),
            const SizedBox(height: 16),
            const TextField(
              obscureText: true,
              decoration: InputDecoration(labelText: '비밀번호'),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go('/permissions'),
              child: const Text('로그인'),
            ),
            TextButton(
              onPressed: () => context.go('/permissions'),
              child: const Text('Apple / Google로 계속'),
            ),
          ],
        ),
      ),
    );
  }
}
