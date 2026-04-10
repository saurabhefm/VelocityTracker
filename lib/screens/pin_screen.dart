import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../main.dart';

enum PinMode { create, confirm, authenticate }

class PinScreen extends StatefulWidget {
  const PinScreen({super.key});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  String _currentPin = '';
  String? _unconfirmedPin;
  late PinMode _mode;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _mode = AuthService.hasPin ? PinMode.authenticate : PinMode.create;
  }

  void _onDigitPress(String digit) {
    if (_hasError) {
      setState(() {
        _hasError = false;
        _currentPin = '';
      });
    }

    if (_currentPin.length < 4) {
      setState(() {
        _currentPin += digit;
      });

      if (_currentPin.length == 4) {
        _processPin();
      }
    }
  }

  void _onDeletePress() {
    if (_hasError) {
      setState(() {
        _hasError = false;
        _currentPin = '';
      });
      return;
    }
    if (_currentPin.isNotEmpty) {
      setState(() {
        _currentPin = _currentPin.substring(0, _currentPin.length - 1);
      });
    }
  }

  Future<void> _processPin() async {
    final enteredPin = _currentPin;
    
    // Give a slight delay to show the 4th dot filled
    await Future.delayed(const Duration(milliseconds: 200));

    if (!mounted) return;

    if (_mode == PinMode.create) {
      setState(() {
        _unconfirmedPin = enteredPin;
        _mode = PinMode.confirm;
        _currentPin = '';
      });
    } else if (_mode == PinMode.confirm) {
      if (enteredPin == _unconfirmedPin) {
        await AuthService.savePin(enteredPin);
        _navigateToApp();
      } else {
        setState(() {
          _hasError = true;
        });
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;
        setState(() {
          _hasError = false;
          _currentPin = '';
          _unconfirmedPin = null;
          _mode = PinMode.create; // Start over
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PINs did not match. Start over.')),
        );
      }
    } else if (_mode == PinMode.authenticate) {
      final isValid = await AuthService.verifyPin(enteredPin);
      if (isValid) {
        _navigateToApp();
      } else {
        setState(() {
          _hasError = true;
        });
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          setState(() {
            _hasError = false;
            _currentPin = '';
          });
        }
      }
    }
  }

  void _navigateToApp() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
    );
  }

  String get _title {
    if (_mode == PinMode.create) return 'Create your PIN';
    if (_mode == PinMode.confirm) return 'Confirm your PIN';
    return 'Enter PIN';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const Icon(
                Icons.lock_outline,
                size: 64,
                color: Color(0xFF38BDF8),
              ),
              const SizedBox(height: 24),
              Text(
                _title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _hasError ? 'Incorrect PIN' : 'Enter 4 digits',
                style: TextStyle(
                  fontSize: 16,
                  color: _hasError ? Colors.redAccent : Colors.grey,
                ),
              ),
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final isFilled = index < _currentPin.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled 
                        ? (_hasError ? Colors.redAccent : const Color(0xFF38BDF8))
                        : Colors.transparent,
                      border: Border.all(
                        color: _hasError ? Colors.redAccent : const Color(0xFF38BDF8),
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),
              const Spacer(),
              _buildKeypad(),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildKeypadButton('1'),
              _buildKeypadButton('2'),
              _buildKeypadButton('3'),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildKeypadButton('4'),
              _buildKeypadButton('5'),
              _buildKeypadButton('6'),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildKeypadButton('7'),
              _buildKeypadButton('8'),
              _buildKeypadButton('9'),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 80, height: 80), // Empty space
              _buildKeypadButton('0'),
              _buildBackspaceButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadButton(String digit) {
    return InkWell(
      onTap: () => _onDigitPress(digit),
      customBorder: const CircleBorder(),
      child: Container(
        width: 80,
        height: 80,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF1E293B),
        ),
        child: Text(
          digit,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceButton() {
    return InkWell(
      onTap: _onDeletePress,
      customBorder: const CircleBorder(),
      child: Container(
        width: 80,
        height: 80,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.backspace_outlined,
          size: 32,
        ),
      ),
    );
  }
}
