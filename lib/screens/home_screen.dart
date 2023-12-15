import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_docs/colors.dart';
import 'package:google_docs/common/loader.dart';
import 'package:google_docs/models/documentModel.dart';
import 'package:google_docs/repository/auth_repository.dart';
import 'package:google_docs/repository/document_repository.dart';
import 'package:routemaster/routemaster.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void signOut(WidgetRef ref) {
    ref.read(authRepositoryProvider).signOut();
    ref.read(userProvider.notifier).update((state) => null);
  }

  void createDocument(BuildContext context, WidgetRef ref) async {
    String token = ref.read(userProvider)!.token;
    final navigator = Routemaster.of(context);
    final snackbar = ScaffoldMessenger.of(context);

    final errorModel =
        await ref.read(documentRepoProvider).createDocument(token);

    if (errorModel.data != null) {
      navigator.push('/document/${errorModel.data.id}');
    } else {
      snackbar.showSnackBar(SnackBar(content: Text(errorModel.error!)));
    }
  }

  void navigateToDocument(BuildContext context, String docId) {
    Routemaster.of(context).push('/document/$docId');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kwhiteColor,
        actions: [
          IconButton(
              onPressed: () => createDocument(context, ref),
              icon: const Icon(
                Icons.add,
                color: kblackCOlor,
              )),
          IconButton(
              onPressed: () {
                signOut(ref);
              },
              icon: const Icon(
                Icons.logout,
                color: kredColor,
              )),
        ],
      ),
      body: FutureBuilder(
          future: ref
              .watch(documentRepoProvider)
              .getDocument(ref.watch(userProvider)!.token),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Loader();
            }

            return Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10),
                width: 600,
                child: ListView.builder(
                  itemCount: snapshot.data!.data.length,
                  itemBuilder: (context, index) {
                    DocumentModel document = snapshot.data!.data[index];

                    return InkWell(
                      onTap: () => navigateToDocument(context, document.id),
                      child: SizedBox(
                        height: 50,
                        child: Card(
                          child: Center(
                              child: Text(
                            document.title,
                            style: const TextStyle(fontSize: 17),
                          )),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          }),
    );
  }
}
