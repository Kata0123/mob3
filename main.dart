import 'package:flutter/material.dart';

void main() => runApp(const NotesApp());

class NotesApp extends StatelessWidget {
  const NotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Заметки',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal),
      home: const NotesPage(),
    );
  }
}

class Note {
  Note(this.text);

  String text;
  bool important = false;
}

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final _input = TextEditingController();
  final _notes = <Note>[];

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _addNote() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    setState(() => _notes.insert(0, Note(text)));
    _input.clear();
    FocusScope.of(context).unfocus();
  }

  void _viewNote(Note note) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Заметка'),
        scrollable: true,
        content: SelectableText(note.text),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Закрыть')),
        ],
      ),
    );
  }

  Future<void> _editNote(Note note) async {
    final formKey = GlobalKey<FormState>();
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Редактировать заметку'),
        scrollable: true,
        content: Form(
          key: formKey,
          child: TextFormField(
            initialValue: note.text,
            autofocus: true,
            minLines: 3,
            maxLines: 8,
            decoration: const InputDecoration(labelText: 'Текст заметки'),
            validator: (value) => (value ?? '').trim().isEmpty ? 'Введите текст заметки' : null,
            onSaved: (value) => Navigator.pop(context, value!.trim()),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          FilledButton(
            onPressed: () {
              final form = formKey.currentState!;
              if (form.validate()) form.save();
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    if (!mounted || text == null) return;
    setState(() => note.text = text);
  }

  Widget _noteCard(Note note, ColorScheme colors) {
    return Dismissible(
      key: ObjectKey(note),
      direction: note.important ? DismissDirection.horizontal : DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: colors.secondaryContainer,
        child: Icon(Icons.star_outline, color: colors.onSecondaryContainer),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: colors.errorContainer,
        child: Icon(Icons.delete_outline, color: colors.onErrorContainer),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) return true;
        setState(() => note.important = false);
        return false;
      },
      onDismissed: (_) => setState(() => _notes.remove(note)),
      child: Card(
        margin: EdgeInsets.zero,
        color: note.important ? colors.tertiaryContainer : null,
        child: InkWell(
          onTap: () => _viewNote(note),
          onDoubleTap: () => setState(() => note.important = true),
          onLongPress: () => _editNote(note),
          child: ListTile(
            leading: Icon(
              note.important ? Icons.star : Icons.notes,
              semanticLabel: note.important ? 'Важная заметка' : null,
            ),
            title: Text(note.text, maxLines: 3, overflow: TextOverflow.ellipsis),
            trailing: IconButton(
              tooltip: 'Удалить заметку',
              onPressed: () => setState(() => _notes.remove(note)),
              icon: const Icon(Icons.delete_outline),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Заметки')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _input,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Новая заметка',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(onPressed: _addNote, child: const Text('Сохранить')),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _notes.isEmpty
                        ? const Center(child: Text('Заметок пока нет'))
                        : ListView.separated(
                            itemCount: _notes.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 8),
                            itemBuilder: (context, index) => _noteCard(_notes[index], colors),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
