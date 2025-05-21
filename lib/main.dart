import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(MyApp(appState: MyAppState(prefs)));
}

class MyApp extends StatelessWidget {
  final MyAppState appState;

  const MyApp({super.key, required this.appState});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: appState,
      child: MaterialApp(
        title: 'Notes',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        home: const MyHomePage(title: 'Notes'),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var selectedIndex = 0;
  var notes = <String>[];
  final SharedPreferences _prefs;

  MyAppState(this._prefs) {
    _loadNotes();
  }

  void _saveNotes() {
    _prefs.setStringList('notes', notes);
  }

  void _loadNotes() {
    final savedNotes = _prefs.getStringList('notes');
    if (savedNotes != null) {
      notes = savedNotes;
    } else {
      notes = <String>[];
    }
  }

  bool isTask(String note) {
    if (note.length >= 4 && note.startsWith('Task')) {
      return true;
    } else {
      return false;
    }
  }

  bool isTaskDone(String note) {
    if (isTask(note) && note.startsWith('!')) {
      return true;
    } else {
      return false;
    }
  }

  void updateTaskState(int index) {
    if (isTask(notes[index])) {
      if (isTaskDone(notes[index])) {
        notes[index] = notes[index].substring(1);
        _saveNotes();
        notifyListeners();
      } else {
        notes[index] = '!${notes[index]}';
      }
      _saveNotes();
      notifyListeners();
    } else {
      print('Not a task!');
    }
  }

  String getNote(int index) {
    return notes[index];
  }


  void returnHome() {
    selectedIndex = 0;
    notifyListeners();
  }

  int getNoteCount() {
    var noteCount = notes.length;
    print('There are ${noteCount} notes.');
    return noteCount;
  }

  void updateNote(int index, String note) {
    notes[index] = note;
    _saveNotes();
    notifyListeners();
  }

  void addNote(String note, [bool isTask = false, String title = '']) {
    if (!isTask) {
      notes.add('Note #${notes.length + 1}: ${note.toString()}');
      _saveNotes();
    } else if (isTask) {
      notes.add('Task #${notes.length + 1}: ${note.toString()}');
      _saveNotes();
    }
    notifyListeners();
  }

  void remNote(int noteLoc) {
    notes.removeAt(noteLoc);
    _saveNotes();
    notifyListeners();
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var noteIndex = 0;
  var _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    MyAppState appState = context.watch<MyAppState>();
    Widget page;
    switch (appState.selectedIndex) {
      case 0:
        page = MyHomePage(title: 'Notes App');
        break;
      case 1:
        page = NoteEdit(index: noteIndex);
        break;
      default:
        throw UnimplementedError('no widget for $appState.selectedIndex');
    }

    if (appState.selectedIndex != 0) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme
              .of(context)
              .colorScheme
              .inversePrimary,
          title: Text(widget.title),
        ),
        body: Container(child: page),
      );
    } else if (appState.getNoteCount() != 0) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme
              .of(context)
              .colorScheme
              .inversePrimary,
          title: Text(widget.title),
        ),
        body: Center(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: appState.getNoteCount(),
            itemBuilder: (BuildContext context, int index) {
              if (appState.isTask(appState.getNote(index))) {
                return ListTile(
                  leading: IconButton( //TODO: Add checkbox to be able to mark as complete
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      setState(() {
                        noteIndex = index;
                        appState.selectedIndex = 1;
                      });
                    },
                  ),
                  title: Text(appState.getNote(index)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        appState.remNote(index);
                      });
                    },
                  ),
                );
              } else {
                return ListTile(
                  leading: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      setState(() {
                        noteIndex = index;
                        appState.selectedIndex = 1;
                      });
                    },
                  ),
                  title: Text(appState.getNote(index)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        appState.remNote(index);
                      });
                    },
                  ),
                );
              }
            },
            shrinkWrap: false,
            scrollDirection: Axis.vertical,
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {
              noteCreatePopup(context);
            });
          },
          tooltip: 'Create New',
          child: const Icon(Icons.add),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme
              .of(context)
              .colorScheme
              .inversePrimary,
          title: Text(widget.title),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: Text(
                'No notes yet :(',
                style: Theme
                    .of(context)
                    .textTheme
                    .headlineMedium,
              ),
            ),
            Image.asset(
                'images/sadblueemoji.png'
            )
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {
              noteCreatePopup(context);
            });
          },
          tooltip: 'Create New',
          child: const Icon(Icons.add),
        ),
      );
    }
  }

//TODO: Clean up the textbox
  void noteCreatePopup(BuildContext context) {
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    final screenHeight = MediaQuery
        .of(context)
        .size
        .height;
    MyAppState appState = Provider.of<MyAppState>(context, listen: false);
    bool isTask = false;
    var noteTitle = '';
    var noteBody = '';
    TextEditingController _textController = TextEditingController();
    ScrollController _scrollController = ScrollController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('New Note/Task'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter dialogSetState) {
              // dialogSetState is specific to this StatefulBuilder's content
              return SizedBox(
                width: screenWidth * 0.7,
                height: screenHeight * 0.4,
                child: Column(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        decoration: InputDecoration(
                            hintText: "What's on your mind?"),
                        scrollController: _scrollController,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        expands: true,
                      ),
                    ),
                    Row(
                      children: [
                        Checkbox(
                          value: isTask,
                          onChanged: (bool? value) {
                            dialogSetState(() {
                              isTask = value!;
                            });
                          },
                        ),
                        Text('Is this a task?'),
                      ],
                    ),
                  ],
                ),
              );
            },
          ), actions: <Widget>[
          TextButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('OK'),
            onPressed: () {
              setState(() {
                noteBody = _textController.text;
              });
              Navigator.of(context).pop(noteBody);
            },
          ),
        ],
        );
      },
    ).then((value) {
      if (value != null) {
        appState.addNote(value, isTask, noteTitle);
      }
    });
  }
}

class NoteEdit extends StatefulWidget {
  NoteEdit({super.key, required this.index});

  final int index;

  @override
  State<NoteEdit> createState() => _NoteEditState();
}

class _NoteEditState extends State<NoteEdit> {
  ScrollController _scrollController = ScrollController();
  TextEditingController _textController = TextEditingController();

  void prepNote(String note) {
    _textController.text = note;
  }

  void saveNote(String note, String newNoteContent, int index) {
    MyAppState appState = context.read<MyAppState>();
    if (newNoteContent != note) {
      appState.updateNote(index, newNoteContent);
      setState(() {
        appState.returnHome();
      });
    } else if (newNoteContent == note) {
      setState(() {
        appState.returnHome();
      });
    }
  }

//TODO: Clean up UI
  @override
  Widget build(BuildContext context) {
    MyAppState appState = context.watch<MyAppState>();
    var note = appState.getNote(widget.index);
    prepNote(note);
    return Scaffold(
      appBar: AppBar(title: Text('Edit Note')),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(),
                scrollController: _scrollController,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                expands: true,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          saveNote(note, _textController.text, widget.index);
        },
        tooltip: 'Save Note',
        child: const Icon(Icons.save),
      ),
    );
  }
}