import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../main.dart';

class AuthDialog extends StatefulWidget {
  const AuthDialog({Key? key}) : super(key: key);

  @override
  State<AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<AuthDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _signupFirstNameController = TextEditingController();
  final _signupLastNameController = TextEditingController();
  final _signupEmailController = TextEditingController();
  final _signupPhoneNumberController = TextEditingController();
  final _signupPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _signupAgeController = TextEditingController();
  final _signupSexController = TextEditingController();
  DateTime? _selectedBirthdate;
  String? _loginEmailError;
  String? _loginPasswordError;
  String? _signupErrorMessage;
  bool _showLoginPassword = false;
  bool _showSignupPassword = false;
  bool _showConfirmPassword = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _signupFirstNameController.dispose();
    _signupLastNameController.dispose();
    _signupEmailController.dispose();
    _signupPhoneNumberController.dispose();
    _signupPasswordController.dispose();
    _confirmPasswordController.dispose();
    _signupAgeController.dispose();
    _signupSexController.dispose();
    super.dispose();
  }

  int? _calculateAge(DateTime? birthdate) {
    if (birthdate == null) return null;
    final now = DateTime.now();
    int age = now.year - birthdate.year;
    if (now.month < birthdate.month ||
        (now.month == birthdate.month && now.day < birthdate.day)) {
      age--;
    }
    return age;
  }

  String? _validatePasswordStrength(String password) {
    if (password.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Password must contain at least one number';
    }
    return null;
  }

  String? _validatePhilippinePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }
    // Prepend +63 to the input since prefixText is not included in the controller's text
    final cleaned = '+63' + value.replaceAll(RegExp(r'[^0-9]'), '');
    // Check if the number matches Philippine mobile format (10 digits after +63)
    if (!RegExp(r'^\+63[1-9]\d{9}$').hasMatch(cleaned)) {
      return 'Please enter a valid Philippine mobile number (e.g., +639123456789)';
    }
    return null;
  }

  void _submitLogin() async {
    setState(() {
      _loginEmailError = null;
      _loginPasswordError = null;
    });

    if (_loginFormKey.currentState!.validate()) {
      try {
        await Provider.of<AuthService>(
          context,
          listen: false,
        ).login(_loginEmailController.text, _loginPasswordController.text);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Login successful. Welcome back!',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.indigo[500],
          ),
        );
      } catch (e) {
        if (e.toString().contains('user-not-found')) {
          setState(
            () => _loginEmailError = 'No account found for this email address',
          );
        } else if (e.toString().contains('wrong-password')) {
          setState(
            () => _loginPasswordError = 'Incorrect password for this email',
          );
        } else if (e.toString().contains('invalid-email')) {
          setState(() => _loginEmailError = 'Invalid email format');
        } else if (e.toString().contains('user-disabled')) {
          setState(() => _loginEmailError = 'This account has been disabled');
        } else if (e.toString().contains('too-many-requests')) {
          setState(
            () => _loginEmailError =
                'Too many login attempts. Please try again later',
          );
        } else if (e.toString().contains('network-request-failed')) {
          setState(
            () => _loginEmailError =
                'Network error. Please check your connection',
          );
        } else if (e.toString().contains('invalid-credential')) {
          setState(() => _loginPasswordError = 'Invalid credentials provided');
        } else {
          setState(() => _loginEmailError = 'An error occurred during login');
        }
      }
    }
  }

  void _submitSignup() async {
    setState(() {
      _signupErrorMessage = null;
    });

    if (_signupFormKey.currentState!.validate()) {
      final passwordStrengthError = _validatePasswordStrength(
        _signupPasswordController.text,
      );
      if (passwordStrengthError != null) {
        setState(() {
          _signupErrorMessage = passwordStrengthError;
        });
        return;
      }
      if (_signupPasswordController.text != _confirmPasswordController.text) {
        setState(() {
          _signupErrorMessage = 'The passwords entered do not match';
        });
        return;
      }
      final age = _calculateAge(_selectedBirthdate);
      if (age == null) {
        setState(() {
          _signupErrorMessage = 'Please select a valid birthdate';
        });
        return;
      }
      // Clean the phone number before passing to AuthService
      final cleanedPhone = _signupPhoneNumberController.text.replaceAll(
        RegExp(r'[^0-9+]'),
        '',
      );
      try {
        await Provider.of<AuthService>(context, listen: false).signup(
          _signupFirstNameController.text,
          _signupLastNameController.text,
          _signupEmailController.text,
          cleanedPhone, // Use cleaned phone number
          _signupPasswordController.text,
          age: age,
          sex: _signupSexController.text,
        );
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Account created successfully. Welcome!',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.indigo[500],
          ),
        );
      } catch (e) {
        String errorMessage = 'An error occurred during sign-up';
        if (e.toString().contains('email-already-in-use')) {
          errorMessage = 'This email address is already registered';
        } else if (e.toString().contains('invalid-email')) {
          errorMessage = 'Invalid email format';
        } else if (e.toString().contains('weak-password')) {
          errorMessage = 'The password is too weak';
        } else if (e.toString().contains('network-request-failed')) {
          errorMessage = 'Network error. Please check your connection';
        } else if (e.toString().contains('operation-not-allowed')) {
          errorMessage = 'Sign-up is currently disabled';
        } else if (e.toString().contains('too-many-requests')) {
          errorMessage = 'Too many sign-up attempts. Please try again later';
        }
        setState(() {
          _signupErrorMessage = errorMessage;
        });
      }
    }
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    bool isSending = false;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final theme = Theme.of(context);
            return AlertDialog(
              title: Text('Reset Password', style: theme.textTheme.titleLarge),
              backgroundColor: theme.scaffoldBackgroundColor,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Enter your email address to receive a password reset link.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 60,
                    child: TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceVariant.withOpacity(
                          0.5,
                        ),
                        errorText:
                            errorMessage ??
                            (emailController.text.isNotEmpty &&
                                    !RegExp(
                                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                    ).hasMatch(emailController.text)
                                ? 'Please enter a valid email address'
                                : null),
                      ),
                      onChanged: (value) => setState(() => errorMessage = null),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: theme.textButtonTheme.style,
                  child: Text('Cancel', style: GoogleFonts.poppins()),
                ),
                ElevatedButton(
                  onPressed:
                      isSending ||
                          emailController.text.isEmpty ||
                          !RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(emailController.text)
                      ? null
                      : () async {
                          setState(() => isSending = true);
                          try {
                            await Provider.of<AuthService>(
                              context,
                              listen: false,
                            ).sendPasswordResetEmail(emailController.text);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Password reset link sent successfully. Please check your inbox and spam folder.',
                                  style: GoogleFonts.poppins(),
                                ),
                                backgroundColor: Colors.indigo[500],
                              ),
                            );
                            Navigator.pop(context);
                          } catch (e) {
                            String message =
                                'An error occurred while sending the reset email';
                            if (e.toString().contains('user-not-found')) {
                              message =
                                  'No account found for this email address';
                            } else if (e.toString().contains('invalid-email')) {
                              message = 'Invalid email format';
                            } else if (e.toString().contains(
                              'too-many-requests',
                            )) {
                              message =
                                  'Too many reset attempts. Please try again later';
                            } else if (e.toString().contains(
                              'network-request-failed',
                            )) {
                              message =
                                  'Network error. Please check your connection';
                            }
                            setState(() => errorMessage = message);
                          } finally {
                            setState(() => isSending = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo[500],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text('Send Reset Link', style: GoogleFonts.poppins()),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: theme.scaffoldBackgroundColor,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: 24,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isMobile ? 500 : 600,
          minWidth: isMobile ? 400 : 500,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/logo.png',
                      width: isMobile ? 24 : 32,
                      height: isMobile ? 24 : 32,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Global Care',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListenableBuilder(
                    listenable: _tabController,
                    builder: (context, _) {
                      final index = _tabController.index;
                      return TabBar(
                        controller: _tabController,
                        labelColor: theme.colorScheme.onPrimary,
                        unselectedLabelColor: theme.colorScheme.primary,
                        indicator: BoxDecoration(
                          color: Colors.indigo[500],
                          borderRadius: index == 0
                              ? const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  bottomLeft: Radius.circular(12),
                                )
                              : const BorderRadius.only(
                                  topRight: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        tabs: [
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.login, size: isMobile ? 18 : 20),
                                const SizedBox(width: 4),
                                Text(
                                  'Login',
                                  style: GoogleFonts.poppins(
                                    fontSize: isMobile ? 14 : 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person_add,
                                  size: isMobile ? 18 : 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Sign Up',
                                  style: GoogleFonts.poppins(
                                    fontSize: isMobile ? 14 : 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: isMobile ? 600 : 520,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      Form(
                        key: _loginFormKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: 60,
                              child: TextFormField(
                                controller: _loginEmailController,
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: const Icon(Icons.email),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: theme.colorScheme.surfaceVariant
                                      .withOpacity(0.5),
                                  errorText: _loginEmailError,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email address';
                                  }
                                  if (!RegExp(
                                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                  ).hasMatch(value)) {
                                    return 'Please enter a valid email address';
                                  }
                                  return null;
                                },
                                onChanged: (value) =>
                                    setState(() => _loginEmailError = null),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 60,
                              child: TextFormField(
                                controller: _loginPasswordController,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock),
                                  suffixIcon: IconButton(
                                    key: const ValueKey(
                                      'login_password_toggle',
                                    ),
                                    icon: Icon(
                                      _showLoginPassword
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                    ),
                                    onPressed: () => setState(
                                      () => _showLoginPassword =
                                          !_showLoginPassword,
                                    ),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: theme.colorScheme.surfaceVariant
                                      .withOpacity(0.5),
                                  errorText: _loginPasswordError,
                                ),
                                obscureText: !_showLoginPassword,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  return null;
                                },
                                onChanged: (value) =>
                                    setState(() => _loginPasswordError = null),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _showForgotPasswordDialog,
                                style: theme.textButtonTheme.style,
                                child: Text(
                                  'Forgot Password?',
                                  style: GoogleFonts.poppins(
                                    fontSize: isMobile ? 12 : 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _submitLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo[500],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                                minimumSize: const Size(double.infinity, 50),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              child: Text(
                                'Login',
                                style: GoogleFonts.poppins(
                                  fontSize: isMobile ? 15 : 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Don't have an account?",
                                  style: GoogleFonts.poppins(
                                    fontSize: isMobile ? 12 : 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => _tabController.animateTo(1),
                                  style: theme.textButtonTheme.style,
                                  child: Text(
                                    'Sign Up',
                                    style: GoogleFonts.poppins(
                                      fontSize: isMobile ? 12 : 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Form(
                        key: _signupFormKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isMobile) ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 60,
                                      child: TextFormField(
                                        controller: _signupFirstNameController,
                                        decoration: InputDecoration(
                                          labelText: 'First Name',
                                          prefixIcon: const Icon(Icons.person),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          filled: true,
                                          fillColor: theme
                                              .colorScheme
                                              .surfaceVariant
                                              .withOpacity(0.5),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty)
                                            return 'Please enter your first name';
                                          if (value.trim().length < 1)
                                            return 'First name must be at least 1 character long';
                                          if (!RegExp(
                                            r'^[a-zA-Z\s-]+$',
                                          ).hasMatch(value))
                                            return 'First name can only contain letters, spaces, or hyphens';
                                          return null;
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: SizedBox(
                                      height: 60,
                                      child: TextFormField(
                                        controller: _signupLastNameController,
                                        decoration: InputDecoration(
                                          labelText: 'Last Name',
                                          prefixIcon: const Icon(Icons.person),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          filled: true,
                                          fillColor: theme
                                              .colorScheme
                                              .surfaceVariant
                                              .withOpacity(0.5),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty)
                                            return 'Please enter your last name';
                                          if (value.trim().length < 1)
                                            return 'Last name must be at least 1 character long';
                                          if (!RegExp(
                                            r'^[a-zA-Z\s-]+$',
                                          ).hasMatch(value))
                                            return 'Last name can only contain letters, spaces, or hyphens';
                                          return null;
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 60,
                                      child: TextFormField(
                                        controller: _signupAgeController,
                                        decoration: InputDecoration(
                                          labelText: 'Select Birthday for Age',
                                          prefixIcon: const Icon(Icons.cake),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          filled: true,
                                          fillColor: theme
                                              .colorScheme
                                              .surfaceVariant
                                              .withOpacity(0.5),
                                        ),
                                        readOnly: true,
                                        onTap: () async {
                                          final DateTime? picked =
                                              await showDatePicker(
                                                context: context,
                                                initialDate: DateTime.now(),
                                                firstDate: DateTime(1900),
                                                lastDate: DateTime.now(),
                                              );
                                          if (picked != null &&
                                              picked != _selectedBirthdate) {
                                            setState(() {
                                              _selectedBirthdate = picked;
                                              final age = _calculateAge(picked);
                                              _signupAgeController.text =
                                                  age != null
                                                  ? age.toString()
                                                  : '';
                                            });
                                          }
                                        },
                                        validator: (value) {
                                          if (value == null || value.isEmpty)
                                            return 'Please select your birthdate';
                                          final age = _calculateAge(
                                            _selectedBirthdate,
                                          );
                                          if (age == null ||
                                              age < 1 ||
                                              age > 150)
                                            return 'Please select a valid birthdate';
                                          if (age < 13)
                                            return 'You must be at least 13 years old to register';
                                          return null;
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: SizedBox(
                                      height: 60,
                                      child: DropdownButtonFormField<String>(
                                        value: null,
                                        decoration: InputDecoration(
                                          labelText: 'Sex',
                                          prefixIcon: const Icon(Icons.wc),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          filled: true,
                                          fillColor: theme
                                              .colorScheme
                                              .surfaceVariant
                                              .withOpacity(0.5),
                                        ),
                                        items: ['Male', 'Female', 'Other']
                                            .map(
                                              (sex) => DropdownMenuItem(
                                                value: sex,
                                                child: Text(sex),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (value) =>
                                            _signupSexController.text =
                                                value ?? '',
                                        validator: (value) =>
                                            value == null || value.isEmpty
                                            ? 'Please select your sex'
                                            : null,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 60,
                                child: TextFormField(
                                  controller: _signupEmailController,
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon: const Icon(Icons.email),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: theme.colorScheme.surfaceVariant
                                        .withOpacity(0.5),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty)
                                      return 'Please enter your email address';
                                    if (!RegExp(
                                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                    ).hasMatch(value))
                                      return 'Please enter a valid email address';
                                    return null;
                                  },
                                  onChanged: (value) => setState(
                                    () => _signupErrorMessage = null,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 60,
                                child: TextFormField(
                                  controller: _signupPhoneNumberController,
                                  decoration: InputDecoration(
                                    labelText: 'Phone Number',
                                    prefixIcon: const Icon(Icons.phone),
                                    prefixText: '+63 ',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: theme.colorScheme.surfaceVariant
                                        .withOpacity(0.5),
                                    helperText:
                                        'Enter 10-digit mobile number (e.g., 9393027628)',
                                  ),
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'[0-9]'),
                                    ),
                                    LengthLimitingTextInputFormatter(
                                      10,
                                    ), // 10 digits after +63
                                  ],
                                  validator: _validatePhilippinePhoneNumber,
                                  onChanged: (value) => setState(
                                    () => _signupErrorMessage = null,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 60,
                                child: TextFormField(
                                  controller: _signupPasswordController,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: const Icon(Icons.lock),
                                    suffixIcon: IconButton(
                                      key: const ValueKey(
                                        'signup_password_toggle',
                                      ),
                                      icon: Icon(
                                        _showSignupPassword
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                      ),
                                      onPressed: () => setState(
                                        () => _showSignupPassword =
                                            !_showSignupPassword,
                                      ),
                                    ),
                                    helperText:
                                        'At least 8 characters, including uppercase and number',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: theme.colorScheme.surfaceVariant
                                        .withOpacity(0.5),
                                  ),
                                  obscureText: !_showSignupPassword,
                                  validator: (value) =>
                                      value == null || value.isEmpty
                                      ? 'Please enter a password'
                                      : _validatePasswordStrength(value),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 60,
                                child: TextFormField(
                                  controller: _confirmPasswordController,
                                  decoration: InputDecoration(
                                    labelText: 'Confirm Password',
                                    prefixIcon: const Icon(Icons.lock),
                                    suffixIcon: IconButton(
                                      key: const ValueKey(
                                        'confirm_password_toggle',
                                      ),
                                      icon: Icon(
                                        _showConfirmPassword
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                      ),
                                      onPressed: () => setState(
                                        () => _showConfirmPassword =
                                            !_showConfirmPassword,
                                      ),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: theme.colorScheme.surfaceVariant
                                        .withOpacity(0.5),
                                  ),
                                  obscureText: !_showConfirmPassword,
                                  validator: (value) {
                                    if (value == null || value.isEmpty)
                                      return 'Please confirm your password';
                                    if (value != _signupPasswordController.text)
                                      return 'Passwords do not match';
                                    return null;
                                  },
                                ),
                              ),
                            ] else ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 60,
                                      child: TextFormField(
                                        controller: _signupFirstNameController,
                                        decoration: InputDecoration(
                                          labelText: 'First Name',
                                          prefixIcon: const Icon(Icons.person),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          filled: true,
                                          fillColor: theme
                                              .colorScheme
                                              .surfaceVariant
                                              .withOpacity(0.5),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty)
                                            return 'Please enter your first name';
                                          if (value.trim().length < 1)
                                            return 'First name must be at least 1 character long';
                                          if (!RegExp(
                                            r'^[a-zA-Z\s-]+$',
                                          ).hasMatch(value))
                                            return 'First name can only contain letters, spaces, or hyphens';
                                          return null;
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: SizedBox(
                                      height: 60,
                                      child: TextFormField(
                                        controller: _signupLastNameController,
                                        decoration: InputDecoration(
                                          labelText: 'Last Name',
                                          prefixIcon: const Icon(Icons.person),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          filled: true,
                                          fillColor: theme
                                              .colorScheme
                                              .surfaceVariant
                                              .withOpacity(0.5),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty)
                                            return 'Please enter your last name';
                                          if (value.trim().length < 1)
                                            return 'Last name must be at least 1 character long';
                                          if (!RegExp(
                                            r'^[a-zA-Z\s-]+$',
                                          ).hasMatch(value))
                                            return 'Last name can only contain letters, spaces, or hyphens';
                                          return null;
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 60,
                                      child: TextFormField(
                                        controller: _signupAgeController,
                                        decoration: InputDecoration(
                                          labelText: 'Select Birthday for Age',
                                          prefixIcon: const Icon(Icons.cake),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          filled: true,
                                          fillColor: theme
                                              .colorScheme
                                              .surfaceVariant
                                              .withOpacity(0.5),
                                        ),
                                        readOnly: true,
                                        onTap: () async {
                                          final DateTime? picked =
                                              await showDatePicker(
                                                context: context,
                                                initialDate: DateTime.now(),
                                                firstDate: DateTime(1900),
                                                lastDate: DateTime.now(),
                                              );
                                          if (picked != null &&
                                              picked != _selectedBirthdate) {
                                            setState(() {
                                              _selectedBirthdate = picked;
                                              final age = _calculateAge(picked);
                                              _signupAgeController.text =
                                                  age != null
                                                  ? age.toString()
                                                  : '';
                                            });
                                          }
                                        },
                                        validator: (value) {
                                          if (value == null || value.isEmpty)
                                            return 'Please select your birthdate';
                                          final age = _calculateAge(
                                            _selectedBirthdate,
                                          );
                                          if (age == null ||
                                              age < 1 ||
                                              age > 150)
                                            return 'Please select a valid birthdate';
                                          if (age < 13)
                                            return 'You must be at least 13 years old to register';
                                          return null;
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: SizedBox(
                                      height: 60,
                                      child: DropdownButtonFormField<String>(
                                        value: null,
                                        decoration: InputDecoration(
                                          labelText: 'Sex',
                                          prefixIcon: const Icon(Icons.wc),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          filled: true,
                                          fillColor: theme
                                              .colorScheme
                                              .surfaceVariant
                                              .withOpacity(0.5),
                                        ),
                                        items: ['Male', 'Female', 'Other']
                                            .map(
                                              (sex) => DropdownMenuItem(
                                                value: sex,
                                                child: Text(sex),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (value) =>
                                            _signupSexController.text =
                                                value ?? '',
                                        validator: (value) =>
                                            value == null || value.isEmpty
                                            ? 'Please select your sex'
                                            : null,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 60,
                                      child: TextFormField(
                                        controller: _signupEmailController,
                                        decoration: InputDecoration(
                                          labelText: 'Email',
                                          prefixIcon: const Icon(Icons.email),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          filled: true,
                                          fillColor: theme
                                              .colorScheme
                                              .surfaceVariant
                                              .withOpacity(0.5),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty)
                                            return 'Please enter your email address';
                                          if (!RegExp(
                                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                          ).hasMatch(value))
                                            return 'Please enter a valid email address';
                                          return null;
                                        },
                                        onChanged: (value) => setState(
                                          () => _signupErrorMessage = null,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: SizedBox(
                                      height: 60,
                                      child: TextFormField(
                                        controller:
                                            _signupPhoneNumberController,
                                        decoration: InputDecoration(
                                          labelText: 'Phone Number',
                                          prefixIcon: const Icon(Icons.phone),
                                          prefixText: '+63 ',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          filled: true,
                                          fillColor: theme
                                              .colorScheme
                                              .surfaceVariant
                                              .withOpacity(0.5),
                                          helperText:
                                              'Enter 10-digit mobile number (e.g., 9393027628)',
                                        ),
                                        keyboardType: TextInputType.phone,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(
                                            RegExp(r'[0-9]'),
                                          ),
                                          LengthLimitingTextInputFormatter(
                                            10,
                                          ), // 10 digits after +63
                                        ],
                                        validator:
                                            _validatePhilippinePhoneNumber,
                                        onChanged: (value) => setState(
                                          () => _signupErrorMessage = null,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 60,
                                      child: TextFormField(
                                        controller: _signupPasswordController,
                                        decoration: InputDecoration(
                                          labelText: 'Password',
                                          prefixIcon: const Icon(Icons.lock),
                                          suffixIcon: IconButton(
                                            key: const ValueKey(
                                              'signup_password_toggle',
                                            ),
                                            icon: Icon(
                                              _showSignupPassword
                                                  ? Icons.visibility
                                                  : Icons.visibility_off,
                                            ),
                                            onPressed: () => setState(
                                              () => _showSignupPassword =
                                                  !_showSignupPassword,
                                            ),
                                          ),
                                          helperText:
                                              'At least 8 characters, including uppercase and number',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          filled: true,
                                          fillColor: theme
                                              .colorScheme
                                              .surfaceVariant
                                              .withOpacity(0.5),
                                        ),
                                        obscureText: !_showSignupPassword,
                                        validator: (value) =>
                                            value == null || value.isEmpty
                                            ? 'Please enter a password'
                                            : _validatePasswordStrength(value),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: SizedBox(
                                      height: 60,
                                      child: TextFormField(
                                        controller: _confirmPasswordController,
                                        decoration: InputDecoration(
                                          labelText: 'Confirm Password',
                                          prefixIcon: const Icon(Icons.lock),
                                          suffixIcon: IconButton(
                                            key: const ValueKey(
                                              'confirm_password_toggle',
                                            ),
                                            icon: Icon(
                                              _showConfirmPassword
                                                  ? Icons.visibility
                                                  : Icons.visibility_off,
                                            ),
                                            onPressed: () => setState(
                                              () => _showConfirmPassword =
                                                  !_showConfirmPassword,
                                            ),
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          filled: true,
                                          fillColor: theme
                                              .colorScheme
                                              .surfaceVariant
                                              .withOpacity(0.5),
                                        ),
                                        obscureText: !_showConfirmPassword,
                                        validator: (value) {
                                          if (value == null || value.isEmpty)
                                            return 'Please confirm your password';
                                          if (value !=
                                              _signupPasswordController.text)
                                            return 'Passwords do not match';
                                          return null;
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (_signupErrorMessage != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                _signupErrorMessage!,
                                style: GoogleFonts.poppins(
                                  color: theme.colorScheme.error,
                                  fontSize: isMobile ? 12 : 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _submitSignup,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo[500],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                                minimumSize: const Size(double.infinity, 50),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              child: Text(
                                'Create Account',
                                style: GoogleFonts.poppins(
                                  fontSize: isMobile ? 15 : 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Already have an account?',
                                  style: GoogleFonts.poppins(
                                    fontSize: isMobile ? 12 : 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => _tabController.animateTo(0),
                                  style: theme.textButtonTheme.style,
                                  child: Text(
                                    'Login',
                                    style: GoogleFonts.poppins(
                                      fontSize: isMobile ? 12 : 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
