/**
*Student Number: 218009030, 220049798, 220033640, 222057332, 221002961.
*Student Name: TA RASEGO, LONWABO SIFUMBA, BN NGALO, TC LAAT, TC RADEBE.
*Question: application_viewmodel.
*/

import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');

    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );

    runApp(const App());
  } catch (e) {
    print('Startup error: $e');
  }
