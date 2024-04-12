import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: 'AIzaSyDMHTSiMSZK1PA2G9VNDTcMiNsCKyKX_4s',
      appId: '1:1062426757683:android:7b951db5f27b01f1bef146',
      messagingSenderId: '1062426757683',
      projectId: 'my-app-2b78c',
      storageBucket: 'my-app-2b78c.appspot.com',
    ),
  );
  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  late final DatabaseReference _database;
  late List<Event> _events = [];

  @override
  void initState() {
    super.initState();
    _database = FirebaseDatabase.instance.reference().child('events');
    _database.onChildAdded.listen((event) {
      setState(() {
        _events.add(Event.fromSnapshot(event.snapshot));
      });
    });
    _database.onChildRemoved.listen((event) {
      setState(() {
        _events.removeWhere((element) => element.key == event.snapshot.key);
      });
    });
  }

  void _addEventData() {
    String name = '';
    String date = '';
    String location = '';
    File? _image;

    Future<void> getImage() async {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController nameController = TextEditingController();
        TextEditingController locationController = TextEditingController();

        return AlertDialog(
          title: Text('Add Event Data'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  decoration: InputDecoration(labelText: 'Name'),
                  onChanged: (value) {
                    name = value;
                  },
                  controller: nameController,
                ),
                TextField(
                  decoration: InputDecoration(labelText: 'Location'),
                  onChanged: (value) {
                    location = value;
                  },
                  controller: locationController,
                ),
                SizedBox(height: 10),
                _image != null
                    ? Image.file(
                  _image!,
                  height: 150,
                  width: 150,
                )
                    : SizedBox(), // Display selected image
                TextButton(
                  onPressed: getImage,
                  child: Text('Pick Image'),
                ),
                SizedBox(height: 10),
                TextButton(
                  onPressed: () async {
                    final selectedDate = await _selectDate(context);
                    setState(() {
                      date = selectedDate;
                    });
                  },
                  child: Text('Select Date'),
                ),
                SizedBox(height: 10),
                Text(date), // Display selected date
              ],
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                _saveEventData(name, date, location, _image);
                Navigator.of(context).pop();
              },
              child: Text('Add'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<String> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      return DateFormat('dd/MM/yyyy').format(pickedDate);
    }
    return '';
  }

  void _saveEventData(String name, String date, String location, File? image) async {
    try {
      if (image != null) {
        String fileName = DateTime.now().millisecondsSinceEpoch.toString(); // Generate unique file name
        Reference ref = FirebaseStorage.instance.ref().child('images/$fileName.jpg');
        await ref.putFile(image);
        String imageUrl = await ref.getDownloadURL();
        _database.push().set({
          'name': name,
          'date': date,
          'location': location,
          'imageUrl': imageUrl,
        });
      } else {
        _database.push().set({
          'name': name,
          'date': date,
          'location': location,
        });
      }
      print('Data added successfully');
    } catch (error) {
      print('Failed to add data: $error');
    }
  }

  void _deleteEventData(String key) {
    try {
      _database.child(key).remove();
      print('Data deleted successfully');
    } catch (error) {
      print('Failed to delete data: $error');
    }
  }

  void _updateEventData(String key, String newName, String newDate, String newLocation) {
    try {
      _database.child(key).update({
        'name': newName,
        'date': newDate,
        'location': newLocation,
      });
      final index = _events.indexWhere((event) => event.key == key);
      if (index != -1) {
        setState(() {
          _events[index].name = newName;
          _events[index].date = newDate;
          _events[index].location = newLocation;
        });
      }
      print('Data updated successfully');
    } catch (error) {
      print('Failed to update data: $error');
    }
  }

  void _bookTicket(Event event) {
    // Implement booking ticket functionality here
    Fluttertoast.showToast(
      msg: 'Ticket booked ',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 2,
      backgroundColor: Colors.grey,
      textColor: Colors.white,
      fontSize: 16.0,
    );
    print('Ticket booked for ${event.name}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          _greetingMessage(),
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26, color: Colors.white),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Text(
              _currentDate(),
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        ],
      ),
      body: Container(
        color: Colors.blueGrey,
        child: ListView.builder(
          itemCount: _events.length,
          itemBuilder: (context, index) {
            final event = _events[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EventDetailsScreen(event: event, onBookTicket: _bookTicket),
                  ),
                );
              },
              child: EventCard(
                event: event,
                onDelete: () => _deleteEventData(event.key),
                onUpdate: (String newName, String newDate, String newLocation) =>
                    _updateEventData(event.key, newName, newDate, newLocation),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.redAccent,
        onPressed: _addEventData,
        child: Text(
          'Add Event',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  String _greetingMessage() {
    var hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  String _currentDate() {
    var now = DateTime.now();
    return DateFormat('MMMM d').format(now);
  }
}

class EventCard extends StatelessWidget {
  final Event event;
  final Function onDelete;
  final Function(String, String, String) onUpdate;

  EventCard({required this.event, required this.onDelete, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        color: Colors.grey,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
                image: DecorationImage(
                  fit: BoxFit.cover,
                  image: event.imageUrl != null
                      ? NetworkImage(event.imageUrl! as String)
                      : AssetImage('assets/event.jpg') as ImageProvider<Object>,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                event.name,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    event.date,
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  Text(
                    event.location,
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  color: Colors.white,
                  icon: Icon(Icons.edit),
                  onPressed: () => _editEventData(context),
                ),
                IconButton(
                  color: Colors.white,
                  icon: Icon(Icons.delete),
                  onPressed: () => onDelete(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _editEventData(BuildContext context) {
    String newName = event.name;
    String newDate = event.date;
    String newLocation = event.location;

    TextEditingController nameController = TextEditingController(text: event.name);
    TextEditingController locationController = TextEditingController(text: event.location);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Edit Event Data'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(
                      decoration: InputDecoration(labelText: 'Name'),
                      onChanged: (value) {
                        newName = value;
                      },
                      controller: nameController,
                    ),
                    TextField(
                      decoration: InputDecoration(labelText: 'Location'),
                      onChanged: (value) {
                        newLocation = value;
                      },
                      controller: locationController,
                    ),
                    SizedBox(height: 10),
                    TextButton(
                      onPressed: () async {
                        final selectedDate = await _selectDate(context, event.date);
                        setState(() {
                          newDate = selectedDate;
                        });
                      },
                      child: Text('Select Date'),
                    ),
                    SizedBox(height: 10),
                    Text(newDate), // Display selected date
                  ],
                ),
              ),
              actions: <Widget>[
                ElevatedButton(
                  onPressed: () {
                    onUpdate(newName, newDate, newLocation);
                    Navigator.of(context).pop();
                  },
                  child: Text('Update'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<String> _selectDate(BuildContext context, String initialDate) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateFormat('dd/MM/yyyy').parse(initialDate),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      return DateFormat('dd/MM/yyyy').format(pickedDate);
    }
    return initialDate;
  }
}

class Event {
  late final String key;
  late String name;
  late String date;
  late String location;
  String? imageUrl;

  Event(this.key, this.name, this.date, this.location, {this.imageUrl});

  Event.fromSnapshot(DataSnapshot snapshot) {
    key = snapshot.key ?? '';
    if (snapshot.value != null && snapshot.value is Map) {
      final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
      name = data['name'] ?? '';
      date = data['date'] ?? '';
      location = data['location'] ?? '';
      imageUrl = data['imageUrl'];
    } else {
      name = '';
      date = '';
      location = '';
    }
  }
}

class EventDetailsScreen extends StatelessWidget {
  final Event event;
  final Function(Event) onBookTicket;

  EventDetailsScreen({required this.event, required this.onBookTicket});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Event Details'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Name: ${event.name}',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              'Date: ${event.date}',
              style: TextStyle(fontSize: 20),
            ),
            Text(
              'Location: ${event.location}',
              style: TextStyle(fontSize: 20),
            ),
            ElevatedButton(
              onPressed: () {
                onBookTicket(event);
              },
              child: Text('Book Ticket'),
            ),
          ],
        ),
      ),
    );
  }
}