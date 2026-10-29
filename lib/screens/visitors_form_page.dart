import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/visitor.dart';
import '../providers/visitor_provider.dart';
import '../utils/helpers.dart';
import 'visitor_detail_page.dart';

class VisitorFormPage extends StatefulWidget {
  final Visitor? visitor;
  const VisitorFormPage({super.key, this.visitor});

  @override
  State<VisitorFormPage> createState() => _VisitorFormPageState();
}

class _VisitorFormPageState extends State<VisitorFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _mobile;
  late final TextEditingController _purpose;
  String? _type;
  String? _project;
  bool _saving = false;

  static final RegExp _emailRegex =
      RegExp(r'^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$');

  bool get _editing => widget.visitor != null;

  @override
  void initState() {
    super.initState();
    final v = widget.visitor;
    _name = TextEditingController(text: v?.name ?? '');
    _email = TextEditingController(text: v?.email ?? '');
    _mobile = TextEditingController(text: v?.mobile ?? '');
    _purpose = TextEditingController(text: v?.purpose ?? '');
    _type = kVisitorTypes.contains(v?.type) ? v?.type : null;
    _project = kProjects.contains(v?.project) ? v?.project : null;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _mobile.dispose();
    _purpose.dispose();
    super.dispose();
  }

  // fill colour and borders come from AppTheme.inputDecorationTheme
  InputDecoration _dec(String label, IconData icon) =>
      InputDecoration(labelText: label, prefixIcon: Icon(icon));

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final provider = context.read<VisitorProvider>();
    setState(() => _saving = true);

    try {
      if (_editing) {
        final updated = widget.visitor!.copyWith(
          name: _name.text.trim(),
          email: _email.text.trim(),
          mobile: _mobile.text.trim(),
          type: _type,
          project: _project,
          purpose: _purpose.text.trim(),
        );
        await provider.update(updated); // PUT
        showMsgOn(messenger, 'Visitor updated on the server');
        nav.pop();
      } else {
        final draft = Visitor(
          id: '',
          name: _name.text.trim(),
          email: _email.text.trim(),
          mobile: _mobile.text.trim(),
          type: _type!,
          project: _project!,
          purpose: _purpose.text.trim(),
          registeredAt: DateTime.now(),
        );
        final created = await provider.register(draft); // POST + verify GET
        showMsgOn(messenger,
            'Visitor saved to server and confirmed (ID ${created.id})');
        nav.pushReplacement(
          MaterialPageRoute(
              builder: (_) => VisitorDetailPage(visitorId: created.id)),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _saving = false);
      showMsgOn(messenger, errText(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: Text(_editing ? 'Edit Visitor' : 'Register Visitor')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            // form is at most 450 wide, shrinks on small phones
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: _dec('Visitor name', Icons.person_outline),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Enter the visitor name'
                          : null,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration:
                          _dec('Email (optional)', Icons.email_outlined),
                      validator: (v) {
                        final t = v?.trim() ?? '';
                        if (t.isEmpty) return null;
                        return _emailRegex.hasMatch(t)
                            ? null
                            : 'Enter a valid email address';
                      },
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _mobile,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      decoration: _dec('Phone number', Icons.phone_outlined),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Enter the phone number';
                        }
                        if (v.length != 10) {
                          return 'Phone number must be exactly 10 digits';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    DropdownButtonFormField<String>(
                      initialValue: _type,
                      decoration: _dec('Visitor type', Icons.badge_outlined),
                      items: kVisitorTypes
                          .map((t) =>
                              DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (v) => setState(() => _type = v),
                      validator: (v) =>
                          v == null ? 'Select visitor type' : null,
                    ),
                    const SizedBox(height: 24),
                    DropdownButtonFormField<String>(
                      initialValue: _project,
                      decoration: _dec('Project', Icons.folder_outlined),
                      items: kProjects
                          .map((p) =>
                              DropdownMenuItem(value: p, child: Text(p)))
                          .toList(),
                      onChanged: (v) => setState(() => _project = v),
                      validator: (v) => v == null ? 'Select a project' : null,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _purpose,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 2,
                      decoration: _dec(
                          'Purpose of visit (optional)', Icons.notes_outlined),
                    ),
                    const SizedBox(height: 32),

                    // ---- Cancel / Register buttons ----
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed:
                                _saving ? null : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 24), // gap between buttons
                        Expanded(
                          child: FilledButton(
                            onPressed: _saving ? null : _save,
                            style: FilledButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _saving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(_editing ? 'Save' : 'Register'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}