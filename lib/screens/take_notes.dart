import 'package:flutter/material.dart';

class TakeNote extends StatefulWidget {
  const TakeNote({super.key});

  @override
  State<TakeNote> createState() => _TakeNoteState();
}

class _TakeNoteState extends State<TakeNote> {
  final note = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(width: 2, color: Colors.grey),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView(
        children: <Widget>[
          const ListTile(
            title: Text('Write your note here...'),
          ),
          TextField(
            controller: note,
            maxLength: null,
            maxLines: null,
            decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Write your note here...'),
          ),
          Container(
            alignment: Alignment.center,
            child: ElevatedButton(
              onPressed: () {},
              child: const Text('Save'),
            ),
          )
        ],
      ),
    );
  }
}
