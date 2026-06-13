import 'package:flutter/material.dart';

import '../../../core/session/session_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.sessionController,
  });

  final SessionController sessionController;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: 'demo.owner@credimerc.local');
    _passwordController = TextEditingController(text: 'Demo1234');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    await widget.sessionController.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    final message = widget.sessionController.errorMessage;
    if (message != null && message.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      widget.sessionController.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: AnimatedBuilder(
        animation: widget.sessionController,
        builder: (context, _) {
          final loading = widget.sessionController.isLoading;

          return Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colorScheme.primary.withOpacity(0.10),
                      Theme.of(context).scaffoldBackgroundColor,
                      colorScheme.secondary.withOpacity(0.08),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: -60,
                right: -40,
                child: _GlowBlob(color: colorScheme.secondary.withOpacity(0.20), size: 180),
              ),
              Positioned(
                bottom: -80,
                left: -60,
                child: _GlowBlob(color: colorScheme.primary.withOpacity(0.18), size: 220),
              ),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.82),
                              borderRadius: BorderRadius.circular(32),
                              border: Border.all(color: Colors.white.withOpacity(0.65)),
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.primary.withOpacity(0.10),
                                  blurRadius: 40,
                                  offset: const Offset(0, 22),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Image.asset(
                                  'lib/assets/credimerclogo.png',
                                  height: 150,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'CrediMerc',
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.8,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Controla clientes, préstamos y pagos con una experiencia clara y profesional.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                        height: 1.4,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.88),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(color: const Color(0xFFE3EEE9)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Iniciar sesion',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Accede a tu cartera y mantén el control operativo.',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                  const SizedBox(height: 18),
                                  TextFormField(
                                    controller: _emailController,
                                    decoration: const InputDecoration(
                                      labelText: 'Correo',
                                      prefixIcon: Icon(Icons.email_outlined),
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Ingresa tu correo.';
                                      }
                                      if (!value.contains('@')) {
                                        return 'Correo invalido.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _passwordController,
                                    decoration: const InputDecoration(
                                      labelText: 'Contrasena',
                                      prefixIcon: Icon(Icons.lock_outline),
                                    ),
                                    obscureText: true,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Ingresa tu contrasena.';
                                      }
                                      if (value.length < 8) {
                                        return 'La contrasena debe tener al menos 8 caracteres.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 18),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton(
                                      onPressed: loading ? null : _submit,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 2),
                                        child: Text(loading ? 'Ingresando...' : 'Ingresar'),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextButton(
                                          onPressed: loading
                                              ? null
                                              : () => showDialog<void>(
                                                    context: context,
                                                    builder: (_) => _ForgotPasswordDialog(
                                                      sessionController: widget.sessionController,
                                                    ),
                                                  ),
                                          child: const Text('Olvide mi contrasena'),
                                        ),
                                      ),
                                      Expanded(
                                        child: TextButton(
                                          onPressed: loading
                                              ? null
                                              : () => showDialog<void>(
                                                    context: context,
                                                    builder: (_) => _ResetPasswordDialog(
                                                      sessionController: widget.sessionController,
                                                    ),
                                                  ),
                                          child: const Text('Restablecer con token'),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      const Expanded(
                                        child: Divider(),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        child: Text(
                                          'o',
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                      ),
                                      const Expanded(
                                        child: Divider(),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  OutlinedButton.icon(
                                    onPressed: loading
                                        ? null
                                        : () async {
                                            final result = await showDialog<_RegisterResult>(
                                              context: context,
                                              builder: (_) => _RegisterDialog(
                                                sessionController: widget.sessionController,
                                              ),
                                            );

                                            if (result == null || !mounted) return;

                                            _emailController.text = result.email;
                                            _passwordController.text = result.password;

                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Cuenta creada. Ahora inicia sesion.'),
                                              ),
                                            );
                                          },
                                    icon: const Icon(Icons.person_add_alt_1),
                                    label: const Text('Crear cuenta'),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Cuidamos la trazabilidad de cada operacion.',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({
    required this.color,
    required this.size,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _ForgotPasswordDialog extends StatefulWidget {
  const _ForgotPasswordDialog({required this.sessionController});

  final SessionController sessionController;

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  final _emailController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un correo valido.')),
      );
      return;
    }

    setState(() => _submitting = true);
    final error = await widget.sessionController.requestPasswordReset(email);
    if (!mounted) return;

    setState(() => _submitting = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Solicitud enviada. Revisa tu canal de recuperacion.')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Recuperar contrasena'),
      content: TextField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(
          labelText: 'Correo',
          prefixIcon: Icon(Icons.email_outlined),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: Text(_submitting ? 'Enviando...' : 'Enviar'),
        ),
      ],
    );
  }
}

class _ResetPasswordDialog extends StatefulWidget {
  const _ResetPasswordDialog({required this.sessionController});

  final SessionController sessionController;

  @override
  State<_ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<_ResetPasswordDialog> {
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _tokenController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final token = _tokenController.text.trim();
    final password = _passwordController.text;

    if (token.length < 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un token valido.')),
      );
      return;
    }

    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La contrasena debe tener al menos 8 caracteres.')),
      );
      return;
    }

    setState(() => _submitting = true);
    final error = await widget.sessionController.resetPassword(
      token: token,
      newPassword: password,
    );

    if (!mounted) return;

    setState(() => _submitting = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contrasena restablecida. Ya puedes iniciar sesion.')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Restablecer contrasena'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _tokenController,
            decoration: const InputDecoration(
              labelText: 'Token de recuperacion',
              prefixIcon: Icon(Icons.vpn_key_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Nueva contrasena',
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: Text(_submitting ? 'Guardando...' : 'Guardar'),
        ),
      ],
    );
  }
}

class _RegisterResult {
  const _RegisterResult({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;
}

class _RegisterDialog extends StatefulWidget {
  const _RegisterDialog({required this.sessionController});

  final SessionController sessionController;

  @override
  State<_RegisterDialog> createState() => _RegisterDialogState();
}

class _RegisterDialogState extends State<_RegisterDialog> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (fullName.length < 2) {
      setState(() {
        _error = 'Ingresa tu nombre completo.';
      });
      return;
    }

    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _error = 'Ingresa un correo valido.';
      });
      return;
    }

    if (password.length < 8) {
      setState(() {
        _error = 'La contrasena debe tener al menos 8 caracteres.';
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _error = 'Las contrasenas no coinciden.';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    String? error;
    try {
      error = await widget.sessionController.register(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone.isEmpty ? null : phone,
      );
    } catch (exception) {
      error = 'Error inesperado al crear cuenta: $exception';
    }

    if (!mounted) return;

    setState(() {
      _submitting = false;
      _error = error;
    });

    if (error != null) {
      return;
    }

    Navigator.of(context).pop(_RegisterResult(email: email, password: password));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Crear cuenta'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                labelText: 'Nombre completo',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Telefono (opcional)',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Contrasena',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirmar contrasena',
                prefixIcon: Icon(Icons.lock_reset_outlined),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: Text(_submitting ? 'Creando...' : 'Crear cuenta'),
        ),
      ],
    );
  }
}
