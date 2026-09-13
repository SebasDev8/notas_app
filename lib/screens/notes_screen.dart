import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  final TextEditingController _titleController =
      TextEditingController();

  final TextEditingController _contentController =
      TextEditingController();

  List<dynamic> _notes = [];

  bool _isLoading = true;
  bool _isOnline = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  //*el inicializador 

  Future<void> _initialize() async {
    _isOnline = await _apiService.isOnline();

    if (_isOnline) {
      await _syncPendingChanges();
      await _loadFromServer();
    } else {
      await _loadLocalNotes();
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  //*carga desde el servidor

  Future<void> _loadFromServer() async {
    try {
      final response = await _apiService.getNotes();

      _notes = response.data;

      await _storageService.saveNotes(_notes);
    } catch (e) {
      await _loadLocalNotes();
    }
  }

  //* carga las notas cuando no hay conexion

  Future<void> _loadLocalNotes() async {
    _notes = await _storageService.getLocalNotes();
  }

  //*crea la nota

  Future<void> _createNote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Completa el título y el contenido',
          ),
        ),
      );

      return;
    }

    if (_isOnline) {
      try {
        final response = await _apiService.createNote(
          title: title,
          content: content,
        );

        final note = response.data['nota'];

        _notes.insert(0, note);

        await _storageService.saveNotes(_notes);

        _closeDialog();

        setState(() {});

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Nota creada correctamente',
            ),
          ),
        );

        return;
      } catch (e) {
        _isOnline = false;
      }
    }

    //*guarda cuando no hay conexion

    final localId = DateTime.now().millisecondsSinceEpoch;

    final localNote = {
      'id': localId,
      'title': title,
      'content': content,
      'localOnly': true,
    };

    _notes.insert(0, localNote);

    await _storageService.saveNotes(_notes);

    final pendingChanges =
        await _storageService.getPendingChanges();

    pendingChanges.add({
      'action': 'create',
      'title': title,
      'content': content,
      'localId': localId,
    });

    await _storageService.savePendingChanges(
      pendingChanges,
    );

    _closeDialog();

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Sin conexión. Nota guardada localmente.',
        ),
      ),
    );
  }

  //*edita 

  Future<void> _editNote(dynamic note) async {
    _titleController.text = note['title'];
    _contentController.text = note['content'];

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar nota'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título',
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _contentController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Contenido',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final title =
                    _titleController.text.trim();

                final content =
                    _contentController.text.trim();

                if (title.isEmpty || content.isEmpty) {
                  return;
                }

                if (_isOnline &&
                    note['localOnly'] != true) {
                  try {
                    await _apiService.updateNote(
                      id: note['id'],
                      title: title,
                      content: content,
                    );

                    note['title'] = title;
                    note['content'] = content;

                    await _storageService.saveNotes(
                      _notes,
                    );

                    if (!mounted) return;

                    Navigator.pop(context);

                    setState(() {});

                    return;
                  } catch (e) {
                    _isOnline = false;
                  }
                }

                //*edita cuando no hay conexion

                note['title'] = title;
                note['content'] = content;

                await _storageService.saveNotes(
                  _notes,
                );

                final pendingChanges =
                    await _storageService
                        .getPendingChanges();

                // Si la nota fue creada offline,
                // modificamos la creación pendiente.
                if (note['localOnly'] == true) {
                  final localId = note['id'];

                  final createIndex =
                      pendingChanges.indexWhere(
                    (change) =>
                        change['action'] == 'create' &&
                        change['localId'] == localId,
                  );

                  if (createIndex != -1) {
                    pendingChanges[createIndex]['title'] =
                        title;

                    pendingChanges[createIndex]['content'] =
                        content;
                  }
                } else {
                  // Nota que ya existía en el servidor.
                  pendingChanges.add({
                    'action': 'update',
                    'id': note['id'],
                    'title': title,
                    'content': content,
                  });
                }

                await _storageService
                    .savePendingChanges(
                  pendingChanges,
                );

                if (!mounted) return;

                Navigator.pop(context);

                setState(() {});

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Sin conexión. Cambio guardado localmente.',
                    ),
                  ),
                );
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  //*elimina

  Future<void> _deleteNote(int index) async {
    final note = _notes[index];

    if (_isOnline && note['localOnly'] != true) {
      try {
        await _apiService.deleteNote(
          note['id'],
        );

        _notes.removeAt(index);

        await _storageService.saveNotes(_notes);

        setState(() {});

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Nota eliminada correctamente.',
            ),
          ),
        );

        return;
      } catch (e) {
        _isOnline = false;
      }
    }

    //*elimina cuando no hay conexion

    final pendingChanges =
        await _storageService.getPendingChanges();

    // Si la nota fue creada offline y todavía
    // no existe en el servidor, simplemente
    // cancelamos su creación pendiente.
    if (note['localOnly'] == true) {
      final localId = note['id'];

      pendingChanges.removeWhere(
        (change) =>
            change['action'] == 'create' &&
            change['localId'] == localId,
      );
    } else {
      // Si la nota ya existía en el servidor,
      // guardamos la eliminación para sincronizarla.
      pendingChanges.add({
        'action': 'delete',
        'id': note['id'],
      });
    }

    _notes.removeAt(index);

    await _storageService.saveNotes(_notes);

    await _storageService.savePendingChanges(
      pendingChanges,
    );

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Sin conexión. Eliminación guardada localmente.',
        ),
      ),
    );
  }

  //*sincronizar

  Future<void> _syncPendingChanges() async {
    final pendingChanges =
        await _storageService.getPendingChanges();

    if (pendingChanges.isEmpty) {
      return;
    }

    final remainingChanges = <dynamic>[];

    for (final change in pendingChanges) {
      try {
        //*crea

        if (change['action'] == 'create') {
          final response =
              await _apiService.createNote(
            title: change['title'],
            content: change['content'],
          );

          final serverNote = response.data['nota'];

          final localId = change['localId'];

          final localIndex = _notes.indexWhere(
            (note) =>
                note['localOnly'] == true &&
                note['id'] == localId,
          );

          if (localIndex != -1) {
            _notes[localIndex] = serverNote;
          }
        }

        //*actualiza

        if (change['action'] == 'update') {
          await _apiService.updateNote(
            id: change['id'],
            title: change['title'],
            content: change['content'],
          );
        }

        //*elimina

        if (change['action'] == 'delete') {
          await _apiService.deleteNote(
            change['id'],
          );
        }
      } catch (e) {
        remainingChanges.add(change);
      }
    }

    await _storageService.savePendingChanges(
      remainingChanges,
    );

    await _storageService.saveNotes(_notes);
  }

  //*actualiza

  Future<void> _refresh() async {
    setState(() {
      _isLoading = true;
    });

    _isOnline = await _apiService.isOnline();

    if (_isOnline) {
      await _syncPendingChanges();
      await _loadFromServer();
    } else {
      await _loadLocalNotes();
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _closeDialog() {
    _titleController.clear();
    _contentController.clear();

    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _showCreateNoteDialog() {
    _titleController.clear();
    _contentController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nueva nota'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título',
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _contentController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Contenido',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: _createNote,
              child: const Text('Crear'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isOnline
              ? 'Mis notas'
              : 'Mis notas (sin conexión)',
        ),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.sync),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _notes.isEmpty
              ? const Center(
                  child: Text(
                    'No tienes notas todavía',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _notes.length,
                  itemBuilder: (context, index) {
                    final note = _notes[index];

                    return Card(
                      child: ListTile(
                        title: Text(
                          note['title'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(
                            top: 8,
                          ),
                          child: Text(
                            note['content'],
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                              ),
                              onPressed: () {
                                _editNote(note);
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                              ),
                              onPressed: () {
                                _deleteNote(index);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateNoteDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}