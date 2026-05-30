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
