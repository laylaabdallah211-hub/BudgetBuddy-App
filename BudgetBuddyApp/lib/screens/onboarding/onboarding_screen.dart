import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_auth_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  final List<Map<String, String>> slides = [
    {
      'title': 'Welcome to Budget Buddy',
      'description': 'Manage your finances easily and smartly.',
    },
    {
      'title': 'Track Income & Expenses',
      'description': 'See exactly where your money goes.',
    },
    {
      'title': 'Achieve Savings Goals',
      'description': 'Stay on top of your financial goals.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<UserAuthProvider>(context, listen: false);

    return Scaffold(
      body: Column(
        children: [
          // SLIDES
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: slides.length,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              itemBuilder: (_, index) {
                final slide = slides[index];
                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        slide['title']!,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        slide['description']!,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // DOTS
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              slides.length,
                  (index) => Container(
                margin: const EdgeInsets.all(4),
                width: _currentPage == index ? 20 : 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _currentPage == index ? Colors.blue : Colors.grey,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // NEXT / GET STARTED BUTTON
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                  if (_currentPage == slides.length - 1) {
                    // LAST SLIDE → MARK AS COMPLETED
                    setState(() => _isLoading = true);

                    await auth.updateUserData({
                      "onboardingComplete": true,
                    });

                    setState(() => _isLoading = false);
                    // NAVIGATION happens automatically in AppWrapper
                  } else {
                    // GO TO NEXT SLIDE
                    _pageController.nextPage(
                      duration:
                      const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                child: _isLoading
                    ? const CircularProgressIndicator(
                  color: Colors.white,
                )
                    : Text(
                  _currentPage == slides.length - 1
                      ? "Get Started"
                      : "Next",
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
