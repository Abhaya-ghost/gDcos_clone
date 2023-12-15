import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_docs/colors.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:google_docs/common/loader.dart';
import 'package:google_docs/models/documentModel.dart';
import 'package:google_docs/models/errorModel.dart';
import 'package:google_docs/repository/auth_repository.dart';
import 'package:google_docs/repository/document_repository.dart';
import 'package:google_docs/repository/socket_repository.dart';
import 'package:routemaster/routemaster.dart';

class DocumentScreen extends ConsumerStatefulWidget {
  final String id;
  const DocumentScreen({super.key, required this.id});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _DocumentScreenState();
}

class _DocumentScreenState extends ConsumerState<DocumentScreen> {
  TextEditingController titleController =
      TextEditingController(text: 'Untitled Document');

  quill.QuillController? _controller;

  ErrorModel? errorModel;
  SocketRepo socketRepo = SocketRepo();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    socketRepo.joinRoom(widget.id);
    fetchDocumentData();

    socketRepo.changeListener((data) {
      _controller?.compose(
          quill.Delta.fromJson(data['delta']),
          _controller?.selection ?? const TextSelection.collapsed(offset: 0),
          quill.ChangeSource.REMOTE);
    });

    Timer.periodic(const Duration(seconds: 2), (timer) {
      socketRepo.autoSave(<String, dynamic>{
        'delta': _controller!.document.toDelta(),
        'room': widget.id,
      });
    });
  }

  void fetchDocumentData() async {
    errorModel = await ref
        .read(documentRepoProvider)
        .getDocumentById(ref.read(userProvider)!.token, widget.id);

    if (errorModel!.data != null) {
      titleController.text = (errorModel!.data as DocumentModel).title;
      _controller = quill.QuillController(
        document: errorModel!.data.content.isEmpty
            ? quill.Document()
            : quill.Document.fromDelta(
                quill.Delta.fromJson(errorModel!.data.content)),
        selection: const TextSelection.collapsed(offset: 0),
      );
      setState(() {});
    }

    _controller!.document.changes.listen((event) {
      // 1 -> entire content of document
      // 2-> changes that are made from the previous part
      // 3->local? —>we have typed remote?

      if (event.item3 == quill.ChangeSource.LOCAL) {
        Map<String, dynamic> map = {
          'delta': event.item2,
          'room': widget.id,
        };
        socketRepo.typing(map);
      }
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    titleController.dispose();
  }

  void updateTitle(WidgetRef ref, String title) {
    ref.read(documentRepoProvider).updateTitle(
        token: ref.read(userProvider)!.token, id: widget.id, title: title);
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const Scaffold(
        body: Loader(),
      );
    }
    return Scaffold(
        appBar: AppBar(
          backgroundColor: kwhiteColor,
          elevation: 0,
          actions: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(
                        text: 'http://localhost:3000/#/document/${widget.id}'),
                  ).then((value) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Link copied')));
                  });
                },
                icon: const Icon(
                  Icons.lock,
                  size: 16,
                  color: Colors.white,
                ),
                label: const Text(
                  'Share',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kblueColor,
                ),
              ),
            )
          ],
          title: Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Routemaster.of(context).replace('/');
                  },
                  child: Image.asset(
                    'assets/images/docs-logo.png',
                    height: 40,
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                SizedBox(
                  width: 170,
                  child: TextField(
                    onSubmitted: (value) => updateTitle(ref, value),
                    controller: titleController,
                    decoration: const InputDecoration(
                        border: InputBorder.none,
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: kblueColor)),
                        contentPadding: EdgeInsets.only(left: 10)),
                  ),
                )
              ],
            ),
          ),
          bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                decoration: BoxDecoration(
                    border: Border.all(color: kgreyColor, width: 0.1)),
              )),
        ),
        body: Center(
          child: Column(
            children: [
              const SizedBox(
                height: 10,
              ),
              quill.QuillToolbar.basic(controller: _controller!),
              const SizedBox(
                height: 10,
              ),
              Expanded(
                child: SizedBox(
                  width: 750,
                  child: Card(
                    color: kwhiteColor,
                    elevation: 5,
                    child: Padding(
                      padding: const EdgeInsets.all(30.0),
                      child: quill.QuillEditor.basic(
                        controller: _controller!,
                        readOnly: false,
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ));
  }
}
