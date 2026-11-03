import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart'; // paket 2: intl
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart'; // paket 1

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID'); // aktifkan format tanggal Indonesia
  runApp(const CatatanHarianApp());
}

/* ===================== MODEL ===================== */

class Note {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;

  const Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        id: json['id'] as String,
        title: json['title'] as String,
        content: json['content'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

/* ===================== PENYIMPANAN ===================== */

class NoteStorage {
  static const _key = 'catatan_harian';

  static Future<List<Note>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => Note.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(List<Note> notes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(notes.map((n) => n.toJson()).toList()),
    );
  }
}

/* ===================== APLIKASI ===================== */

class CatatanHarianApp extends StatelessWidget {
  const CatatanHarianApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Catatan Harian',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

/* ===================== HALAMAN UTAMA ===================== */

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _dateFormat = DateFormat('EEEE, d MMMM yyyy', 'id_ID');
  final _timeFormat = DateFormat('HH:mm', 'id_ID');

  List<Note> _notes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final notes = await NoteStorage.load();
    notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (!mounted) return;
    setState(() {
      _notes = notes;
      _loading = false;
    });
  }

  Future<void> _persist() async {
    _notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    await NoteStorage.save(_notes);
  }

  Future<void> _openEditor({Note? note}) async {
    final result = await Navigator.push<Note>(
      context,
      MaterialPageRoute(builder: (_) => EditorPage(note: note)),
    );
    if (result == null) return;

    setState(() {
      final index = _notes.indexWhere((n) => n.id == result.id);
      if (index >= 0) {
        _notes[index] = result;
      } else {
        _notes.add(result);
      }
    });
    await _persist();
  }

  Future<bool> _confirmDelete(Note note) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus catatan?'),
        content: Text('"${note.title}" akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _deleteNote(Note note) async {
    final index = _notes.indexWhere((n) => n.id == note.id);
    setState(() => _notes.removeWhere((n) => n.id == note.id));
    await _persist();

    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Catatan dihapus'),
          action: SnackBarAction(
            label: 'URUNGKAN',
            onPressed: () async {
              setState(() => _notes.insert(index.clamp(0, _notes.length), note));
              await _persist();
            },
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan Harian'),
        backgroundColor: scheme.primaryContainer,
      ),
      body: Column(
        children: [
          // Banner tanggal hari ini
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            color: scheme.primaryContainer,
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  _dateFormat.format(DateTime.now()),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const Spacer(),
                Text('${_notes.length} catatan'),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('Catatan Baru'),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_notes.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Belum ada catatan.\nKetuk "Catatan Baru" untuk mulai menulis.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
      itemCount: _notes.length,
      itemBuilder: (context, i) {
        final note = _notes[i];
        return Dismissible(
          key: ValueKey(note.id),
          direction: DismissDirection.endToStart,
          confirmDismiss: (_) => _confirmDelete(note),
          onDismissed: (_) => _deleteNote(note),
          background: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.only(right: 20),
            alignment: Alignment.centerRight,
            decoration: BoxDecoration(
              color: Colors.red.shade400,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              onTap: () => _openEditor(note: note),
              title: Text(
                note.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  Text(
                    note.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_dateFormat.format(note.createdAt)} • '
                    '${_timeFormat.format(note.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ],
              ),
              trailing: IconButton(
                tooltip: 'Hapus catatan',
                onPressed: () async {
                  final shouldDelete = await _confirmDelete(note);
                  if (!shouldDelete) return;
                  await _deleteNote(note);
                },
                icon: const Icon(Icons.delete_outline),
                color: Colors.red,
              ),
            ),
          ),
        );
      },
    );
  }
}

/* ===================== HALAMAN TAMBAH / EDIT ===================== */

class EditorPage extends StatefulWidget {
  final Note? note;
  const EditorPage({super.key, this.note});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;
  late final DateTime _date;

  bool get _isEdit => widget.note != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.note?.title ?? '');
    _contentCtrl = TextEditingController(text: widget.note?.content ?? '');
    _date = widget.note?.createdAt ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      Note(
        id: widget.note?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        title: _titleCtrl.text.trim(),
        content: _contentCtrl.text.trim(),
        createdAt: _date,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat('EEEE, d MMMM yyyy • HH:mm', 'id_ID');

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Catatan' : 'Catatan Baru'),
        actions: [
          IconButton(
            tooltip: 'Simpan',
            onPressed: _save,
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.event, size: 18),
                  const SizedBox(width: 8),
                  Text(dateText.format(_date)),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Judul',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Judul wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TextFormField(
                  controller: _contentCtrl,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Isi catatan',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Isi catatan wajib diisi'
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: const Text('Simpan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
